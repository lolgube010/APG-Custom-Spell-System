extends ShapeBase

## Self-propelled projectile with gravity — like a thrown rock.
## Moves forward and accelerates downward each frame.
## Uses a sweep ray (CCD) each frame so fast-moving projectiles
## don't skip through thin geometry.

const GRAVITY: float = 12.0

var _velocity: Vector3 = Vector3.ZERO
var _initialized: bool = false

func _ready() -> void:
	super()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	if not _initialized:
		# Lazy init: global_transform is guaranteed set by the first physics tick
		_velocity = -parent_spell.global_transform.basis.z * parent_spell.speed * parent_spell.cast_force
		_initialized = true

	_velocity.y -= GRAVITY * delta
	var move := _velocity * delta

	# Sweep-ray CCD: catch collisions the Area3D might skip at high speed
	if move.length_squared() > 0.0001:
		var space := get_world_3d().direct_space_state
		var dir := move.normalized()
		var query := PhysicsRayQueryParameters3D.create(
			parent_spell.global_position,
			parent_spell.global_position + dir * (move.length() + 0.3)
		)
		var result := space.intersect_ray(query)
		if result:
			var collider := result.collider as Node3D
			if collider:
				_on_body_entered(collider)
				return

	parent_spell.global_position += move

## Override: reflect the tracked velocity vector rather than the spell's facing.
func _do_ricochet() -> void:
	if _bounce_cooldown:
		return
	_bounce_cooldown = true
	get_tree().create_timer(0.1).timeout.connect(func(): _bounce_cooldown = false)
	var dir := _velocity.normalized()
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		parent_spell.global_position - dir * 0.3,
		parent_spell.global_position + dir * 0.3
	)
	var result := space.intersect_ray(query)
	if result:
		_velocity = _velocity.reflect(result.normal)
		parent_spell.global_position = result.position + result.normal * 0.15
	else:
		_velocity.y = abs(_velocity.y)
