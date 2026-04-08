extends Node

# Moves forward (like LineOfSight) but snaps side-to-side in a sharp triangular wave.

var parent_spell: SpellBase
var forward: Vector3
var right: Vector3
var elapsed: float = 0.0
var initialized: bool = false
const FREQUENCY: float = 2.5  # zig-zags per second
const AMPLITUDE: float = 5.0  # lateral speed at peak (m/s)

func _ready() -> void:
	parent_spell = get_parent() as SpellBase

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	if not initialized:
		forward = -parent_spell.global_transform.basis.z
		right = parent_spell.global_transform.basis.x
		initialized = true
	elapsed += delta
	var t = fmod(elapsed * FREQUENCY, 1.0)
	var lateral = (2.0 * abs(2.0 * t - 1.0) - 1.0) * AMPLITUDE  # triangular wave [-1, 1]
	parent_spell.global_position += (forward * parent_spell.speed + right * lateral) * delta
