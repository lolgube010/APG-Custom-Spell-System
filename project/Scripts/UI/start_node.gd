extends GraphNode
# Giving it a class_name makes it easy to identify later!
class_name SpellStartNode

func _ready() -> void:
	# 1. Basic Setup
	title = "Start Spell"
	
	# We intentionally DO NOT add the custom "X" close button here.
	
	# 2. Create the row
	var label: Label = Label.new()
	label.text = "Sequence Out ->"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(label)
	
	# 3. Configure the slot
	# set_slot(index, enable_left, type_left, color_left, enable_right, type_right, color_right)
	# Left (Input) is FALSE. Right (Output) is TRUE.
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)
