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

		add_child(row)
		set_slot(i, true, 0, config["color"], true, 0, config["color"])

func _on_close_button_pressed() -> void:
	delete_request.emit()

func get_data_for_port(port_index: int) -> Dictionary:
	var config = SpellGlobals.attribute_configs[port_index]
	var row = get_child(port_index)
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
		if not child is HBoxContainer:
			continue
		var config = SpellGlobals.attribute_configs[config_index]
		var dropdown = child.get_child(1) as OptionButton
		var state = {"dropdown": dropdown.selected}

		match config.get("input_type", "none"):
			"float":
				state["amount"] = child.get_child(2).value
			"int":
				state["amount"] = int(child.get_child(2).value)
			"bool":
				state["amount"] = child.get_child(2).button_pressed
			"vec":
				state["amount"] = {
					"x": child.get_child(2).value,
					"y": child.get_child(3).value,
					"z": child.get_child(4).value,
				}

		states.append(state)
		config_index += 1
	return states

func set_dropdown_states(states: Array) -> void:
	var state_index = 0
	var config_index = 0
	for child in get_children():
		if not child is HBoxContainer:
			continue
		if state_index >= states.size():
			break
		var config = SpellGlobals.attribute_configs[config_index]
		var state = states[state_index]
		var dropdown = child.get_child(1) as OptionButton

		# Support old format (plain int) and new format (dict)
		if state is int:
			dropdown.select(state)
		elif state is Dictionary:
			dropdown.select(state.get("dropdown", 0))
			match config.get("input_type", "none"):
				"float":
					if state.has("amount"):
						child.get_child(2).value = state["amount"]
				"int":
					if state.has("amount"):
						child.get_child(2).value = state["amount"]
				"bool":
					if state.has("amount"):
						child.get_child(2).button_pressed = state["amount"]
				"vec":
					if state.has("amount"):
						child.get_child(2).value = state["amount"].get("x", 1.0)
						child.get_child(3).value = state["amount"].get("y", 1.0)
						child.get_child(4).value = state["amount"].get("z", 1.0)

		state_index += 1
		config_index += 1
	setting_changed.emit()
