extends ShapeBase

## Ground-hugging AOE zone. Snaps to the ground on spawn and continuously
## re-snaps every physics frame, so it glides forward along the ground when
## combined with a path (e.g. LineOfSight). Never rises into the air.

var _hit_bodies: Array = []

func _ready() -> void:
	super()
	# body_entered fires, but AOE doesn't destroy itself — override below

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	_snap_to_ground()

func _snap_to_ground() -> void:
	var space := get_world_3d().direct_space_state
	# Cast from slightly above so we don't start inside the ground
	var from := parent_spell.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 100.0)
	query.collision_mask = 1
	var result := space.intersect_ray(query)
	if result:
		parent_spell.global_position.y = result.position.y
	# Keep the disc flat regardless of aim pitch
	var fwd := -parent_spell.global_transform.basis.z
	var flat := Vector3(fwd.x, 0.0, fwd.z)
	if flat.length_squared() > 0.001:
		parent_spell.look_at(parent_spell.global_position + flat.normalized(), Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	if _hit_bodies.has(body) or body is StaticBody3D:
		return
	_hit_bodies.append(body)
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	# AOE persists for the spell's lifetime — does not destroy on hit
