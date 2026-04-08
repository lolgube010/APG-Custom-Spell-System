extends Node3D
class_name SpellBase

# We store basic stats here so modifiers (like Speed * 2) can easily find and change them
var element: int = -1 # -1 means none
var current_path: int = -1 
var scale_mult: Vector3 = Vector3.ONE
var speed_mult: float = 1.0
var duration_mult: float = 1.0
var split_count: int = 0
var is_piercing: bool = false
var does_ricochet: bool = false

# Arrays to hold effects that haven't been applied to a shape yet
var pending_effects: Array[int] = []

func _process(delta: float) -> void:
	# The base script doesn't move itself. 
	# It waits for its child components (like the Orb) to move it!
	pass
