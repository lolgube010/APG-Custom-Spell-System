extends ShapeBase

## Valorant-style wall: a tall barrier that extends forward from the cast point,
## standing vertically on the ground. Stationary regardless of path.
## Damages anything that walks through it (once per pass — re-entering deals damage again).

func _ready() -> void:
	super()
	_init_persistent_zone()
	_place_on_ground()

func _place_on_ground() -> void:
	await get_tree().process_frame
	_snap_to_ground()
	top_level = true

func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D or _hit_bodies.has(body):
		return
	_hit_bodies.append(body)
	_damage_body(body, global_transform)
	# Wall persists — does not destroy on hit
