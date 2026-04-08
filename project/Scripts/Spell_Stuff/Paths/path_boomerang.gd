extends PathBase

# Flies outward then returns to the spawn point and destroys itself.
# During the outward phase the transform is read live each frame so that
# the Ricochet modifier (which rotates the spell via look_at) is respected.

var spawn_position: Vector3
var elapsed: float = 0.0
var returning: bool = false
var initialized: bool = false
var outward_time: float = 0.8
const OUTWARD_FRACTION: float = 0.16

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	if not initialized:
		spawn_position = parent_spell.global_position
		outward_time = parent_spell.lifetime * OUTWARD_FRACTION
		initialized = true
	elapsed += delta
	if not returning:
		# Read the transform live so any mid-flight ricochet is respected.
		var forward := -parent_spell.global_transform.basis.z
		parent_spell.global_position += forward * parent_spell.speed * delta
		if elapsed >= outward_time:
			returning = true
	else:
		var to_origin := spawn_position - parent_spell.global_position
		if to_origin.length() < 0.5:
			parent_spell.queue_free()
			return
		parent_spell.global_position += to_origin.normalized() * parent_spell.speed * delta
