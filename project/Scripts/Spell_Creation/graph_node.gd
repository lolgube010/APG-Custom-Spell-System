extends GraphNode

@onready var titlebar:HBoxContainer = get_titlebar_hbox()

#mainly responsible for the visual layout of the node
enum SpellElement { FIRE, ICE, LIGHTNING, ARCANE }
enum SpellModifierVec { Size }
enum SpellModifierFloat { CastSpeed, MoveSpeed, Duration, CastForce }
enum SpellPath { LineOfSight, CurvePath, SigZagLineOfSight, Upwards, OnPlayer, }
enum SpellShape { Orb, AOE, Beam, Explode }
enum SpellCasting { Burst, Continous, Self}
enum SpellEffect { Scale, MoveSpeed, SlowMo, Levitation, Throw, Poison }
enum SpellAmplification { Half, Double, Quad, Ten }
enum SpellTrigger { OnHit, OnEnd, OnTimer, OnCast, OnKill }

var attribute_configs = [
	{"name": "Element", "enum": SpellElement, "color": Color.RED, "id": "element"},
	{"name": "Modif (Vec)", "enum": SpellModifierVec, "color": Color.CYAN, "id": "mod_vec"},
	{"name": "Modif (Float)", "enum": SpellModifierFloat, "color": Color.AZURE, "id": "mod_float"},
	{"name": "Path", "enum": SpellPath, "color": Color.YELLOW, "id": "path"},
	{"name": "Shape", "enum": SpellShape, "color": Color.ORANGE, "id": "shape"},
	{"name": "Casting", "enum": SpellCasting, "color": Color.GREEN, "id": "casting"},
	{"name": "Effect", "enum": SpellEffect, "color": Color.PURPLE, "id": "effect"},
	{"name": "Amplification", "enum": SpellAmplification, "color": Color.PINK, "id": "amplification"},
	{"name": "Trigger", "enum": SpellTrigger, "color": Color.WHITE, "id": "trigger"}
]

func _ready() -> void:
	# --- Set up the Close Button ---
	var close_btn:Button = Button.new()
	close_btn.pressed.connect(_on_close_button_pressed)
	close_btn.custom_minimum_size = Vector2(32, 0)
	close_btn.text = "X"
	close_btn.theme = theme
	titlebar.add_child(close_btn)
	
	# --- Dynamically Build Rows, Dropdowns, and Slots ---
	for i in range(attribute_configs.size()):
		var config = attribute_configs[i]
		
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
			
		row.add_child(dropdown)
		
		# 3. Add the entire row to the GraphNode
		add_child(row)
		
		# 4. Enable the slots for this specific row index
		# We use type '0' for everything so you can connect a Shape to a Trigger as requested
		set_slot(i, true, 0, config["color"], true, 0, config["color"])
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 2. Handle the selection
func _on_element_selected(index: int) -> void:
	# 'index' matches both the dropdown list position AND the enum integer value!
	var chosen_element: SpellElement = index as SpellElement
	
	match chosen_element:
		SpellElement.FIRE:
			print("Player chose Fire!")
			# Maybe change the node's color here?
		SpellElement.ICE:
			print("Player chose Ice!")
		SpellElement.LIGHTNING:
			print("Player chose Lightning!")
		SpellElement.ARCANE:
			print("Player chose Arcane!")

func _on_close_button_pressed() -> void:
	delete_request.emit()


	
func get_data_for_port(port_index: int) -> Dictionary:
	var data = {}
	
	# Get the specific config dictionary for this row
	var config = attribute_configs[port_index]
	
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
