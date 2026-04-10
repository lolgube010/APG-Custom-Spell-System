extends PathBase

var _forward: Vector3
var _right: Vector3
var _elapsed: float = 0.0
const FREQUENCY: float = 2.5  # zig-zags per second
const AMPLITUDE: float = 5.0  # lateral speed at peak (m/s)

func _init_direction() -> void:
	_forward = -parent_spell.global_transform.basis.z
	_right = parent_spell.global_transform.basis.x

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	super(delta)
	_elapsed += delta
	var t := fmod(_elapsed * FREQUENCY, 1.0)
	var lateral : float = (2.0 * abs(2.0 * t - 1.0) - 1.0) * AMPLITUDE
	parent_spell.global_position += (_forward * parent_spell.speed + _right * lateral) * delta
