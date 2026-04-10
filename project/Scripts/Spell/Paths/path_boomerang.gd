extends PathBase

# Flies outward then returns to the spawn point and destroys itself.

var _spawn_position: Vector3
var _elapsed: float = 0.0
var _returning: bool = false
var _outward_time: float = 0.0
const OUTWARD_FRACTION: float = 0.16

func _init_direction() -> void:
	_spawn_position = parent_spell.global_position
	_outward_time = parent_spell.lifetime * OUTWARD_FRACTION

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	super(delta)
	_elapsed += delta
	if not _returning:
		var forward := -parent_spell.global_transform.basis.z
		parent_spell.global_position += forward * parent_spell.speed * delta
		if _elapsed >= _outward_time:
			_returning = true
	else:
		var to_origin := _spawn_position - parent_spell.global_position
		if to_origin.length() < 0.5:
			parent_spell.end_spell(parent_spell.global_transform)
			return
		parent_spell.global_position += to_origin.normalized() * parent_spell.speed * delta
