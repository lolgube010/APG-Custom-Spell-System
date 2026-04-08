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
		
		# Create a horizontal box so the Label and Dropdown sit nicely side-by-side
		var row: HBoxContainer = HBoxContainer.new()
		
		# 1. Add the Label (e.g., "Shape")
		var label: Label = Label.new()
		label.text = config["name"]
		label.custom_minimum_size = Vector2(100, 0) # Keeps dropdowns aligned
		row.add_child(label)
		
		# 2. Add the Dropdown (OptionButton)
		var dropdown: OptionButton = OptionButton.new()
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Stretch to fill space
		
		# Populate the dropdown from the enum keys
		for element_name in config["enum"].keys():
			dropdown.add_item(element_name.capitalize())
		
		dropdown.item_selected.connect(_on_dropdown_item_selected)
		
		row.add_child(dropdown)
		
		# 3. Add the entire row to the GraphNode
		add_child(row)
		
		# 4. Enable the slots for this specific row index
		# We use type '0' for everything so you can connect a Shape to a Trigger as requested
		set_slot(i, true, 0, config["color"], true, 0, config["color"])

#func _on_element_selected(index: int) -> void:
	## 'index' matches both the dropdown list position AND the enum integer value!
	#var chosen_element: SpellGlobals.SpellElement = index as SpellGlobals.SpellElement
	#
	#match chosen_element:
		#SpellGlobals.SpellElement.FIRE:
			#print("Player chose Fire!")
			## Maybe change the node's color here?
		#SpellGlobals.SpellElement.ICE:
			#print("Player chose Ice!")
		#SpellGlobals.SpellElement.LIGHTNING:
			#print("Player chose Lightning!")
		#SpellGlobals.SpellElement.ARCANE:
			#print("Player chose Arcane!")

func _on_close_button_pressed() -> void:
	delete_request.emit()

func get_data_for_port(port_index: int) -> Dictionary:
	var data = {}
	
	# Get the specific config dictionary for this row
	var config = SpellGlobals.attribute_configs[port_index]
	
	# The row is a child of the GraphNode. 
	# Children order: 0 is Titlebar (usually hidden from get_child index), 
	# but since we added our custom HBoxContainers manually, they align with the port_index!
	# (Note: +1 is because we added the custom Close Button directly to the titlebar earlier, 
	# but the rows are added directly to the node body. You may need to tweak this index 
	# slightly if Godot counts an internal node first).
	
	var row = get_child(port_index) 
	
	# Inside our row, child 0 is the Label, child 1 is the OptionButton
	var dropdown: OptionButton = row.get_child(1)
	
	data["type"] = config["id"]
	data["value"] = dropdown.get_selected_id()
	
	return data

func get_dropdown_states() -> Array:
	var states = []
	# Iterate safely through children to find the HBoxContainers we built
	for child in get_children():
		if child is HBoxContainer:
			var dropdown = child.get_child(1) as OptionButton
			if dropdown:
				states.append(dropdown.selected)
	return states

func set_dropdown_states(states: Array) -> void:
	var state_index = 0
	for child in get_children():
		if child is HBoxContainer:
			if state_index < states.size():
				var dropdown = child.get_child(1) as OptionButton
				if dropdown:
					# Apply the saved integer back to the dropdown
					dropdown.select(states[state_index])
				state_index += 1
	setting_changed.emit()

func _on_dropdown_item_selected(_index: int) -> void:
	# We don't actually need to know *which* index was selected here.
	# We just need to shout "Hey, something changed!" so the main script 
	# knows to re-run the compile_spell() loop.
	print("node settings changed in graph_node.gd!")
	setting_changed.emit()
