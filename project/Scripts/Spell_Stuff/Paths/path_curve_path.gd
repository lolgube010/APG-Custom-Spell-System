extends Node

var parent_spell: SpellBase
var direction: Vector3
var turn_rate: float
var initialized: bool = false
const BASE_TURN_RATE: float = 1.2  # radians per second

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	turn_rate = BASE_TURN_RATE * (1.0 if randf() > 0.5 else -1.0)

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	if not initialized:
		direction = -parent_spell.global_transform.basis.z
		initialized = true
	direction = direction.rotated(Vector3.UP, turn_rate * delta).normalized()
	parent_spell.global_position += direction * parent_spell.speed * delta
