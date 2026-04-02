extends GraphNode

@onready var titlebar:HBoxContainer = get_titlebar_hbox()

#mainly responsible for the visual layout of the node
enum SpellElement { FIRE, ICE, LIGHTNING, ARCANE }
enum SpellModifierVec { Size }
enum SpellModifierFloat { CastSpeed, MoveSpeed, Duration, CastForce }
enum SpellPath { LOS, CurvePath, SigZagLOS, Upwards, OnPlayer, }
enum SpellShape { Orb, AOE, Beam }
enum SpellCasting { Burst, Continous, Self}
enum SpellEffect { Scale, MoveSpeed, SlowMo, Levitation, Throw, Poison }
enum SpellAmplification { Half, Double, Quad, Ten }
enum SpellTrigger { OnHit, OnEnd, OnTimer, OnCast, OnKill }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var close_btn:Button = Button.new()
	close_btn.pressed.connect(_on_close_button_pressed)
	close_btn.custom_minimum_size = Vector2(32, 0)
	close_btn.text = "X"
	close_btn.theme = theme
	titlebar.add_child(close_btn)
# --- Adding the Enum Dropdown ---
	
	var dropdown: OptionButton = OptionButton.new()
	
	# Loop through the string names of our enum (FIRE, ICE, etc.)
	for element_name in SpellElement.keys():
		# Capitalize() makes "FIRE" look nicely formatted as "Fire" in the UI
		dropdown.add_item(element_name.capitalize())
		
	# Connect the signal so we know when the player changes the dropdown
	dropdown.item_selected.connect(_on_element_selected)
	
	# Add it to the GraphNode
	add_child(dropdown)
	
	set_slot(0, true, 0, Color.GREEN, true, 0, Color.RED)


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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
