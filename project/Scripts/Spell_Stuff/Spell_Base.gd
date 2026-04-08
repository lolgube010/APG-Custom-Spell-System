extends Node3D
class_name SpellBase

# We store basic stats here so modifiers (like Speed * 2) can easily find and change them
var speed: float = 1.
var damage: float = 1.

# We'll use this later to store the rest of the array if we hit a Trigger!
var remaining_instructions: Array = []

func _process(delta: float) -> void:
	# The base script doesn't move itself. 
	# It waits for its child components (like the Orb) to move it!
	pass
