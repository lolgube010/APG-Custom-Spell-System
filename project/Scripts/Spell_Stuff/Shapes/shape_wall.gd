extends ShapeBase

## Valorant-style wall: a tall barrier that extends forward from the cast point,
## standing vertically on the ground. Stationary regardless of path.
## Damages anything that walks through it (once per body).

var _hit_bodies: Array = []

func _ready() -> void:
	super()
	_place_on_ground()

func _place_on_ground() -> void:
	await get_tree().process_frame
	# Snap to ground
	var space := get_world_3d().direct_space_state
	var from := parent_spell.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 100.0)
	query.collision_mask = 1
	var result := space.intersect_ray(query)
	if result:
		parent_spell.global_position.y = result.position.y
	# Flatten rotation so the wall stands upright
	var fwd := -parent_spell.global_transform.basis.z
	var flat := Vector3(fwd.x, 0.0, fwd.z)
	if flat.length_squared() > 0.001:
		parent_spell.look_at(parent_spell.global_position + flat.normalized(), Vector3.UP)
	# Pin in place
	top_level = true

func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D or _hit_bodies.has(body):
		return
	_hit_bodies.append(body)
	if body.has_method("take_damage"):
		body.take_damage(parent_spell.damage)
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	# Wall persists — does not destroy on hit
