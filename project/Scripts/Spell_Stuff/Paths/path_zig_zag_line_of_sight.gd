extends PathBase

# Moves forward (like LineOfSight) but snaps side-to-side in a sharp triangular wave.

var _forward: Vector3
var _right: Vector3
var _elapsed: float = 0.0
var _initialized: bool = false
const FREQUENCY: float = 2.5  # zig-zags per second
const AMPLITUDE: float = 5.0  # lateral speed at peak (m/s)

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	if not _initialized:
		_forward = -parent_spell.global_transform.basis.z
		_right = parent_spell.global_transform.basis.x
		_initialized = true
	_elapsed += delta
	var t := fmod(_elapsed * FREQUENCY, 1.0)
	var lateral : float = (2.0 * abs(2.0 * t - 1.0) - 1.0) * AMPLITUDE
	parent_spell.global_position += (_forward * parent_spell.speed + _right * lateral) * delta
