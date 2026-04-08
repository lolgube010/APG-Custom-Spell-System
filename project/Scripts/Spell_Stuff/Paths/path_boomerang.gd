extends Node

# Flies outward then returns to the spawn point and destroys itself.

var parent_spell: SpellBase
var forward: Vector3
var spawn_position: Vector3
var elapsed: float = 0.0
var returning: bool = false
const OUTWARD_TIME: float = 0.8

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	forward = -parent_spell.global_transform.basis.z
	spawn_position = parent_spell.global_position

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	elapsed += delta
	if not returning:
		parent_spell.global_position += forward * parent_spell.speed * delta
		if elapsed >= OUTWARD_TIME:
			returning = true
	else:
		var to_origin = spawn_position - parent_spell.global_position
		if to_origin.length() < 0.5:
			parent_spell.queue_free()
			return
		parent_spell.global_position += to_origin.normalized() * parent_spell.speed * delta
