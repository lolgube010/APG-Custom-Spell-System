extends PathBase

var _direction: Vector3
var _turn_rate: float
var _initialized: bool = false
const BASE_TURN_RATE: float = 1.2  # radians per second

func _ready() -> void:
	super()
	_turn_rate = BASE_TURN_RATE * (1.0 if randf() > 0.5 else -1.0)

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	if not _initialized:
		_direction = -parent_spell.global_transform.basis.z
		_initialized = true
	_direction = _direction.rotated(Vector3.UP, _turn_rate * delta).normalized()
	parent_spell.global_position += _direction * parent_spell.speed * delta
