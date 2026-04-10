extends ShapeBase

## Ground-hugging AOE zone. Snaps to the ground on spawn and continuously
## re-snaps every physics frame, so it glides forward along the ground when
## combined with a path (e.g. LineOfSight). Never rises into the air.

func _ready() -> void:
	super()
	_init_persistent_zone()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	_snap_to_ground()

func _on_body_entered(body: Node3D) -> void:
	if _hit_bodies.has(body) or body is StaticBody3D:
		return
	_hit_bodies.append(body)
	_damage_body(body, global_transform)
	# AOE persists for the spell's lifetime — does not destroy on hit
