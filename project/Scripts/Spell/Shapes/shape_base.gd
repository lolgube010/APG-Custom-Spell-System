class_name ShapeBase
extends Area3D

## Shared base for all spell shapes. Handles element colouring, the standard
## hit/destroy/ricochet/piercing flow, and the bounce cooldown.

var parent_spell: SpellBase
var _bounce_cooldown: bool = false
var _hit_bodies: Array = []

## Call in _ready() for shapes that persist and re-hit bodies on re-entry (AOE, Wall).
func _init_persistent_zone() -> void:
	body_exited.connect(func(body): _hit_bodies.erase(body))

## Snap the parent spell to the ground and flatten its rotation. Safe to call
## from _ready() (via await) or _physics_process.
func _snap_to_ground() -> void:
	var space := get_world_3d().direct_space_state
	var from := parent_spell.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 100.0)
	query.collision_mask = 1
	var result := space.intersect_ray(query)
	if result:
		parent_spell.global_position.y = result.position.y
	var fwd := -parent_spell.global_transform.basis.z
	var flat := Vector3(fwd.x, 0.0, fwd.z)
	if flat.length_squared() > 0.001:
		parent_spell.look_at(parent_spell.global_position + flat.normalized(), Vector3.UP)

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	body_entered.connect(_on_body_entered)
	_apply_element_color()

func _apply_element_color() -> void:
	if not SpellGlobals.ELEMENT_COLORS.has(parent_spell.element):
		return
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if not mesh:
		return
	var mat = mesh.get_active_material(0)
	if not mat:
		return
	var dup := mat.duplicate() as StandardMaterial3D
	_configure_material(dup, SpellGlobals.ELEMENT_COLORS[parent_spell.element])
	mesh.material_override = dup

## Override to customise material properties beyond albedo (e.g. add emission for beams).
func _configure_material(mat: StandardMaterial3D, color: Color) -> void:
	mat.albedo_color = color

## Override to return a different hit point (e.g. beam projects onto its axis).
func _get_hit_transform(_body: Node3D) -> Transform3D:
	return global_transform

## Default: hits destroy the spell; StaticBody3D triggers ricochet or wall-pierce logic.
## Override in subclasses for different behaviour (persistent zones, etc.).
func _on_body_entered(body: Node3D) -> void:
	if _bounce_cooldown:
		return
	var hit_xform := _get_hit_transform(body)
	if body is StaticBody3D:
		if parent_spell.does_ricochet:
			_do_ricochet()
			return
		if parent_spell.is_environment_piercing:
			return
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, hit_xform)
		parent_spell.end_spell(hit_xform)
		return
	_damage_body(body, hit_xform)
	if not parent_spell.is_piercing:
		parent_spell.end_spell(hit_xform)

## Deal damage to a non-static body and fire OnHit + OnKill triggers as appropriate.
## All shapes should call this instead of take_damage + fire_trigger directly.
func _damage_body(body: Node3D, hit_xform: Transform3D) -> void:
	var killed := false
	if body.has_method("take_damage"):
		killed = body.take_damage(parent_spell.damage)
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, hit_xform, body)
	if killed:
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnKill, hit_xform, body)

## Reflect the spell off a surface using the parent spell's facing direction.
## Override in shapes that track their own velocity vector (e.g. Projectile).
func _do_ricochet() -> void:
	var result := _cast_ricochet_ray(-parent_spell.global_transform.basis.z)
	if result:
		var reflected := (-parent_spell.global_transform.basis.z).reflect(result.normal).normalized()
		parent_spell.global_position = result.position + result.normal * 0.6
		var up := Vector3.UP if abs(reflected.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
		parent_spell.look_at(parent_spell.global_position + reflected, up)
	else:
		parent_spell.rotate_y(PI)

## Cast a short ray along `direction` through the spell's current position.
## Handles the cooldown flag. Returns the intersect_ray result dict, or empty if
## on cooldown or no hit. Subclasses call this instead of repeating the scaffolding.
func _cast_ricochet_ray(direction: Vector3) -> Dictionary:
	if _bounce_cooldown:
		return {}
	_bounce_cooldown = true
	get_tree().create_timer(0.1).timeout.connect(func(): _bounce_cooldown = false)
	var space := get_world_3d().direct_space_state
	# Cast from 3 units behind to 0.3 units ahead so the ray crosses the wall
	# surface without overshooting through thin geometry.
	var query := PhysicsRayQueryParameters3D.create(
		parent_spell.global_position - direction * 3.0,
		parent_spell.global_position + direction * 0.3
	)
	query.collision_mask = 1  # static world geometry only
	return space.intersect_ray(query)
