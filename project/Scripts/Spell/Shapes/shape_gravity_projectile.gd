extends ShapeBase

## Gravity well: pulls nearby bodies toward it every physics frame.
## Has a short spawn grace period to avoid immediately self-destructing
## against the player's own collision shape.

const PULL_FORCE: float = 20.0
const SPAWN_GRACE: float = 0.2  # seconds before body_entered is live

var _spawn_ready: bool = false

func _ready() -> void:
	super()
	body_exited.connect(_on_gravity_body_exited)
	get_tree().create_timer(SPAWN_GRACE).timeout.connect(func(): _spawn_ready = true)

func _on_gravity_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.velocity = Vector3(0.0, body.velocity.y, 0.0)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	for body in get_overlapping_bodies():
		var dir := (global_position - body.global_position).normalized()
		if body is RigidBody3D:
			body.apply_central_force(dir * PULL_FORCE)
		elif body is CharacterBody3D:
			body.velocity += dir * PULL_FORCE * delta

func _on_body_entered(body: Node3D) -> void:
	if not _spawn_ready:
		return
	super(body)
