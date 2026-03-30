class_name SpellContext extends RefCounted

var caster: Node3D
var target_position: Vector3
var current_direction: Vector3
var base_damage: float
var remaining_components: Array[SpellComponent] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
