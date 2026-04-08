extends GraphNode

@onready var titlebar:HBoxContainer = get_titlebar_hbox()
signal setting_changed

func _ready() -> void:
	# --- Set up the Close Button ---
	var close_btn:Button = Button.new()
	close_btn.pressed.connect(_on_close_button_pressed)
	close_btn.custom_minimum_size = Vector2(32, 0)
	close_btn.text = "X"
	close_btn.theme = theme
	titlebar.add_child(close_btn)

	# --- Dynamically Build Rows, Dropdowns, and Slots ---
	for i in range(SpellGlobals.attribute_configs.size()):
		var config = SpellGlobals.attribute_configs[i]
		var input_type: String = config.get("input_type", "none")

		# Wrap each row in a PanelContainer so we can colour its background
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

		var row: HBoxContainer = HBoxContainer.new()

		# 1. Label
		var label: Label = Label.new()
		label.text = config["name"]
		label.custom_minimum_size = Vector2(90, 0)
		row.add_child(label)

		# 2. Dropdown
		var dropdown: OptionButton = OptionButton.new()
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for element_name in config["enum"].keys():
			dropdown.add_item(element_name.capitalize())
		dropdown.item_selected.connect(func(_i): setting_changed.emit())
		row.add_child(dropdown)

		# 3. Input widget(s) based on input_type
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
			"vec":
				for _axis in 3:
					var spin := SpinBox.new()
					spin.min_value = -100.0
					spin.max_value = 100.0
					spin.step = 0.1
					spin.value = 1.0
					spin.custom_minimum_size = Vector2(60, 0)
					spin.value_changed.connect(func(_v): setting_changed.emit())
					row.add_child(spin)

		panel.add_child(row)
		add_child(panel)
		set_slot(i, true, 0, config["color"], true, 0, config["color"])

func _on_close_button_pressed() -> void:
	delete_request.emit()

# Highlight or clear the background of a specific port row
func highlight_port(port_index: int, on: bool) -> void:
	var panel := get_child(port_index) as PanelContainer
	if not panel:
		return
	if on:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.28, 0.22, 0.0, 0.85)
		style.set_corner_radius_all(3)
		panel.add_theme_stylebox_override("panel", style)
	else:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func clear_highlights() -> void:
	for child in get_children():
		if child is PanelContainer:
			child.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func get_data_for_port(port_index: int) -> Dictionary:
	var config = SpellGlobals.attribute_configs[port_index]
	var row := get_child(port_index).get_child(0) as HBoxContainer
	var dropdown: OptionButton = row.get_child(1)

	var data = {
		"type": config["id"],
		"value": dropdown.get_selected_id()
	}

	match config.get("input_type", "none"):
		"float":
			data["amount"] = row.get_child(2).value
		"int":
			data["amount"] = int(row.get_child(2).value)
		"bool":
			data["amount"] = row.get_child(2).button_pressed
		"vec":
			data["amount"] = {
				"x": row.get_child(2).value,
				"y": row.get_child(3).value,
				"z": row.get_child(4).value,
			}

	return data

func get_dropdown_states() -> Array:
	var states = []
	var config_index = 0
	for child in get_children():
		if not child is PanelContainer:
			continue
		var row := child.get_child(0) as HBoxContainer
		if not row:
			continue
		var config = SpellGlobals.attribute_configs[config_index]
		var dropdown = row.get_child(1) as OptionButton
		var state = {"dropdown": dropdown.selected}

		match config.get("input_type", "none"):
			"float":
				state["amount"] = row.get_child(2).value
			"int":
				state["amount"] = int(row.get_child(2).value)
			"bool":
				state["amount"] = row.get_child(2).button_pressed
			"vec":
				state["amount"] = {
					"x": row.get_child(2).value,
					"y": row.get_child(3).value,
					"z": row.get_child(4).value,
				}

		states.append(state)
		config_index += 1
	return states

func set_dropdown_states(states: Array) -> void:
	var state_index = 0
	var config_index = 0
	for child in get_children():
		if not child is PanelContainer:
			continue
		if state_index >= states.size():
			break
		var row := child.get_child(0) as HBoxContainer
		if not row:
			continue
		var config = SpellGlobals.attribute_configs[config_index]
		var state = states[state_index]
		var dropdown = row.get_child(1) as OptionButton

		# Support old format (plain int) and new format (dict)
		if state is int:
			dropdown.select(state)
		elif state is Dictionary:
			dropdown.select(state.get("dropdown", 0))
			match config.get("input_type", "none"):
				"float":
					if state.has("amount"):
						row.get_child(2).value = state["amount"]
				"int":
					if state.has("amount"):
						row.get_child(2).value = state["amount"]
				"bool":
					if state.has("amount"):
						row.get_child(2).button_pressed = state["amount"]
				"vec":
					if state.has("amount"):
						row.get_child(2).value = state["amount"].get("x", 1.0)
						row.get_child(3).value = state["amount"].get("y", 1.0)
						row.get_child(4).value = state["amount"].get("z", 1.0)

		state_index += 1
		config_index += 1
	setting_changed.emit()
