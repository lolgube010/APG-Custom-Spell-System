extends GraphNode

@onready var titlebar:HBoxContainer = get_titlebar_hbox()
signal setting_changed

# Per-row references built during _ready(). Eliminates all child-index-based access.
# Each entry: { "dropdown": OptionButton, "widget": Node|null, "input_type": String,
#               "value_input_types": Dictionary }
# widget is: SpinBox (float/int), CheckBox (bool),
#            HBoxContainer with 3 SpinBoxes (vec),
#            HBoxContainer rebuilt on change (dynamic/modifier),
#            null (none)
var _rows: Array = []

# One PanelContainer per row — for highlight_port / clear_highlights.
var _panels: Array = []

func _ready() -> void:
	# --- Close Button ---
	var close_btn := Button.new()
	close_btn.pressed.connect(_on_close_button_pressed)
	close_btn.custom_minimum_size = Vector2(32, 0)
	close_btn.text = "X"
	close_btn.theme = theme
	titlebar.add_child(close_btn)

	# --- Build one row per attribute_config entry ---
	for i in range(SpellGlobals.attribute_configs.size()):
		var config = SpellGlobals.attribute_configs[i]
		var input_type: String = config.get("input_type", "none")

		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

		var row := HBoxContainer.new()

		# Label
		var label := Label.new()
		label.text = config["name"]
		label.custom_minimum_size = Vector2(90, 0)
		row.add_child(label)

		# Dropdown — populate from enum or from MODIFIER_ITEMS
		var dropdown := OptionButton.new()
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if input_type == "modifier":
			for item in SpellGlobals.MODIFIER_ITEMS:
				dropdown.add_item(item["label"])
		else:
			for element_name in config["enum"].keys():
				dropdown.add_item(element_name.capitalize())

		# Generic signal only for plain rows; dynamic/modifier connect their own below
		if input_type != "dynamic" and input_type != "modifier":
			dropdown.item_selected.connect(func(_i): setting_changed.emit())
		row.add_child(dropdown)

		# Value widget — stored by reference, never accessed by child index outside _ready
		var widget = null
		match input_type:
			"float":
				var spin := SpinBox.new()
				spin.min_value = -1000.0
				spin.max_value = 1000.0
				spin.step = 0.1
				spin.value = 1.0
				spin.custom_minimum_size = Vector2(80, 0)
				spin.value_changed.connect(func(_v): setting_changed.emit())
				row.add_child(spin)
				widget = spin
			"int":
				var spin := SpinBox.new()
				spin.min_value = -100
				spin.max_value = 100
				spin.step = 1
				spin.rounded = true
				spin.value = 1
				spin.custom_minimum_size = Vector2(70, 0)
				spin.value_changed.connect(func(_v): setting_changed.emit())
				row.add_child(spin)
				widget = spin
			"bool":
				var check := CheckBox.new()
				var state_label := Label.new()
				state_label.text = "OFF"
				state_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				check.toggled.connect(func(pressed: bool):
					if pressed:
						state_label.text = "ON"
						state_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
					else:
						state_label.text = "OFF"
						state_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
					setting_changed.emit()
				)
				row.add_child(check)
				row.add_child(state_label)
				widget = check
			"vec":
				var vec_container := HBoxContainer.new()
				for _axis in 3:
					var spin := SpinBox.new()
					spin.min_value = -100.0
					spin.max_value = 100.0
					spin.step = 0.1
					spin.value = 1.0
					spin.custom_minimum_size = Vector2(60, 0)
					spin.value_changed.connect(func(_v): setting_changed.emit())
					vec_container.add_child(spin)
				row.add_child(vec_container)
				widget = vec_container
			"dynamic":
				var value_input_types: Dictionary = config.get("value_input_types", {})
				var dyn := HBoxContainer.new()
				var first_info = value_input_types.get(0, {"type": "none", "default": 1.0})
				_update_dynamic_widget(dyn, first_info.get("type", "none"), first_info.get("default", 1.0))
				dropdown.item_selected.connect(func(idx: int):
					var info = value_input_types.get(idx, {"type": "none", "default": 1.0})
					_update_dynamic_widget(dyn, info.get("type", "none"), info.get("default", 1.0))
					setting_changed.emit()
				)
				row.add_child(dyn)
				widget = dyn
			"modifier":
				var dyn := HBoxContainer.new()
				var first_item = SpellGlobals.MODIFIER_ITEMS[0]
				_update_dynamic_widget(dyn, first_item["widget_type"], first_item.get("default", 1.0))
				dropdown.item_selected.connect(func(idx: int):
					var item = SpellGlobals.MODIFIER_ITEMS[idx]
					_update_dynamic_widget(dyn, item["widget_type"], item.get("default", 1.0))
					setting_changed.emit()
				)
				row.add_child(dyn)
				widget = dyn

		_rows.append({
			"dropdown": dropdown,
			"widget": widget,
			"input_type": input_type,
			"value_input_types": config.get("value_input_types", {})
		})

		panel.add_child(row)
		add_child(panel)
		_panels.append(panel)
		set_slot(i, true, 0, config["color"], true, 0, config["color"])

# ---------------------------------------------------------------------------
# Dynamic widget helpers
# ---------------------------------------------------------------------------

func _update_dynamic_widget(container: HBoxContainer, widget_type: String, default_val) -> void:
	for child in container.get_children():
		child.free()
	match widget_type:
		"float":
			var spin := SpinBox.new()
			spin.min_value = 0.0
			spin.max_value = 10000.0
			spin.step = 0.01
			spin.value = float(default_val)
			spin.custom_minimum_size = Vector2(90, 0)
			spin.value_changed.connect(func(_v): setting_changed.emit())
			container.add_child(spin)
		"int":
			var spin := SpinBox.new()
			spin.min_value = 1
			spin.max_value = 100
			spin.step = 1
			spin.rounded = true
			spin.value = int(default_val)
			spin.custom_minimum_size = Vector2(70, 0)
			spin.value_changed.connect(func(_v): setting_changed.emit())
			container.add_child(spin)
		"bool":
			var check := CheckBox.new()
			var state_label := Label.new()
			state_label.text = "OFF"
			state_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			check.toggled.connect(func(pressed: bool):
				if pressed:
					state_label.text = "ON"
					state_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
				else:
					state_label.text = "OFF"
					state_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				setting_changed.emit()
			)
			container.add_child(check)
			container.add_child(state_label)
		"vec":
			for _axis in 3:
				var spin := SpinBox.new()
				spin.min_value = -100.0
				spin.max_value = 100.0
				spin.step = 0.01
				spin.value = float(default_val)
				spin.custom_minimum_size = Vector2(65, 0)
				spin.value_changed.connect(func(_v): setting_changed.emit())
				container.add_child(spin)
		# "none": leave container empty

func _read_container_amount(container: HBoxContainer, widget_type: String):
	match widget_type:
		"float":
			if container.get_child_count() >= 1:
				return (container.get_child(0) as SpinBox).value
		"int":
			if container.get_child_count() >= 1:
				return int((container.get_child(0) as SpinBox).value)
		"bool":
			if container.get_child_count() >= 1:
				return (container.get_child(0) as CheckBox).button_pressed
		"vec":
			if container.get_child_count() >= 3:
				return {
					"x": (container.get_child(0) as SpinBox).value,
					"y": (container.get_child(1) as SpinBox).value,
					"z": (container.get_child(2) as SpinBox).value,
				}
	return null

func _write_container_amount(container: HBoxContainer, widget_type: String, amount) -> void:
	if amount == null:
		return
	match widget_type:
		"float", "int":
			if container.get_child_count() >= 1:
				(container.get_child(0) as SpinBox).value = float(amount)
		"bool":
			if container.get_child_count() >= 1:
				(container.get_child(0) as CheckBox).button_pressed = bool(amount)
		"vec":
			if container.get_child_count() >= 3 and amount is Dictionary:
				(container.get_child(0) as SpinBox).value = amount.get("x", 1.0)
				(container.get_child(1) as SpinBox).value = amount.get("y", 1.0)
				(container.get_child(2) as SpinBox).value = amount.get("z", 1.0)

# ---------------------------------------------------------------------------
# Slot highlights
# ---------------------------------------------------------------------------

func highlight_port(port_index: int, on: bool) -> void:
	if port_index >= _panels.size():
		return
	var panel: PanelContainer = _panels[port_index]
	if on:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.28, 0.22, 0.0, 0.85)
		style.set_corner_radius_all(3)
		panel.add_theme_stylebox_override("panel", style)
	else:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func clear_highlights() -> void:
	for panel in _panels:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func _on_close_button_pressed() -> void:
	delete_request.emit()

# ---------------------------------------------------------------------------
# Data API
# ---------------------------------------------------------------------------

func get_data_for_port(port_index: int) -> Dictionary:
	var config = SpellGlobals.attribute_configs[port_index]
	var row_data = _rows[port_index]
	var dropdown: OptionButton = row_data["dropdown"]
	var widget = row_data["widget"]
	var input_type: String = row_data["input_type"]

	# Modifier row: type/value come from the selected MODIFIER_ITEMS entry
	if input_type == "modifier":
		var item = SpellGlobals.MODIFIER_ITEMS[dropdown.selected]
		var mod_data = {"type": item["spell_type"], "value": item["spell_value"]}
		var amount = _read_container_amount(widget, item["widget_type"])
		if amount != null:
			mod_data["amount"] = amount
		return mod_data

	var data = {"type": config["id"], "value": dropdown.get_selected_id()}
	match input_type:
		"float":
			data["amount"] = (widget as SpinBox).value
		"int":
			data["amount"] = int((widget as SpinBox).value)
		"bool":
			data["amount"] = (widget as CheckBox).button_pressed
		"vec":
			var c := widget as HBoxContainer
			data["amount"] = {
				"x": (c.get_child(0) as SpinBox).value,
				"y": (c.get_child(1) as SpinBox).value,
				"z": (c.get_child(2) as SpinBox).value,
			}
		"dynamic":
			var info = row_data["value_input_types"].get(dropdown.selected, {"type": "none", "default": 1.0})
			var amount = _read_container_amount(widget, info.get("type", "none"))
			if amount != null:
				data["amount"] = amount
	return data

func get_dropdown_states() -> Array:
	var states = []
	for row_data in _rows:
		var dropdown: OptionButton = row_data["dropdown"]
		var widget = row_data["widget"]
		var input_type: String = row_data["input_type"]
		var state = {"dropdown": dropdown.selected}

		match input_type:
			"float":
				state["amount"] = (widget as SpinBox).value
			"int":
				state["amount"] = int((widget as SpinBox).value)
			"bool":
				state["amount"] = (widget as CheckBox).button_pressed
			"vec":
				var c := widget as HBoxContainer
				state["amount"] = {
					"x": (c.get_child(0) as SpinBox).value,
					"y": (c.get_child(1) as SpinBox).value,
					"z": (c.get_child(2) as SpinBox).value,
				}
			"dynamic":
				var info = row_data["value_input_types"].get(dropdown.selected, {"type": "none", "default": 1.0})
				var amount = _read_container_amount(widget, info.get("type", "none"))
				if amount != null:
					state["amount"] = amount
			"modifier":
				var item = SpellGlobals.MODIFIER_ITEMS[dropdown.selected]
				var amount = _read_container_amount(widget, item["widget_type"])
				if amount != null:
					state["amount"] = amount

		states.append(state)
	return states

func set_dropdown_states(states: Array) -> void:
	for i in mini(states.size(), _rows.size()):
		var row_data = _rows[i]
		var state = states[i]
		var dropdown: OptionButton = row_data["dropdown"]
		var widget = row_data["widget"]
		var input_type: String = row_data["input_type"]

		var selected_idx: int = state if state is int else state.get("dropdown", 0)
		dropdown.select(selected_idx)

		if state is Dictionary:
			match input_type:
				"float", "int":
					if state.has("amount"):
						(widget as SpinBox).value = float(state["amount"])
				"bool":
					if state.has("amount"):
						(widget as CheckBox).button_pressed = bool(state["amount"])
				"vec":
					if state.has("amount"):
						var c := widget as HBoxContainer
						var amt = state["amount"]
						(c.get_child(0) as SpinBox).value = amt.get("x", 1.0)
						(c.get_child(1) as SpinBox).value = amt.get("y", 1.0)
						(c.get_child(2) as SpinBox).value = amt.get("z", 1.0)
				"dynamic":
					var info = row_data["value_input_types"].get(selected_idx, {"type": "none", "default": 1.0})
					_update_dynamic_widget(widget, info.get("type", "none"), info.get("default", 1.0))
					if state.has("amount"):
						_write_container_amount(widget, info.get("type", "none"), state["amount"])
				"modifier":
					var item = SpellGlobals.MODIFIER_ITEMS[selected_idx]
					_update_dynamic_widget(widget, item["widget_type"], item.get("default", 1.0))
					if state.has("amount"):
						_write_container_amount(widget, item["widget_type"], state["amount"])

	setting_changed.emit()
