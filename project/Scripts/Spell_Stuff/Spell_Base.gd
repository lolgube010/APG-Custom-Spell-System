extends Node3D
class_name SpellBase

# We store basic stats here so modifiers (like Speed * 2) can easily find and change them
var element: int = -1 # -1 means none
var current_path: int = -1
var damage: float = 10.0
var speed: float = 10.0
var scale_mult: Vector3 = Vector3.ONE
var duration_mult: float = 1.0
var split_count: int = 0
var is_piercing: bool = false
var does_ricochet: bool = false
var is_time_bomb: bool = false

# Arrays to hold effects that haven't been applied to a shape yet
var pending_effects: Array[int] = []
