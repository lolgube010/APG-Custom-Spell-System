class_name ShapeBase
extends Area3D

## Shared base for all spell shapes. Handles element colouring, the standard
## hit/destroy/ricochet/piercing flow, and the bounce cooldown.

var parent_spell: SpellBase
var _bounce_cooldown: bool = false

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
	dup.albedo_color = SpellGlobals.ELEMENT_COLORS[parent_spell.element]
	mesh.material_override = dup

## Default: hits destroy the spell; StaticBody3D triggers ricochet or wall-pierce logic.
## Override in subclasses for different behaviour (persistent zones, etc.).
func _on_body_entered(body: Node3D) -> void:
	if _bounce_cooldown:
		return
	if body is StaticBody3D:
		if parent_spell.does_ricochet:
			_do_ricochet()
			return
		if parent_spell.is_environment_piercing:
			return
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
		parent_spell.end_spell(global_transform)
		return
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	if not parent_spell.is_piercing:
		parent_spell.end_spell(global_transform)

## Reflect the spell off a surface using the parent spell's facing direction.
## Override in shapes that track their own velocity vector (e.g. Projectile).
func _do_ricochet() -> void:
	if _bounce_cooldown:
		return
	_bounce_cooldown = true
	get_tree().create_timer(0.1).timeout.connect(func(): _bounce_cooldown = false)
	var forward := -parent_spell.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		parent_spell.global_position - forward * 0.3,
		parent_spell.global_position + forward * 0.3
	)
	var result := space.intersect_ray(query)
	if result:
		var reflected := forward.reflect(result.normal).normalized()
		parent_spell.global_position = result.position + result.normal * 0.15
		var up := Vector3.UP if abs(reflected.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
		parent_spell.look_at(parent_spell.global_position + reflected, up)
	else:
		parent_spell.rotate_y(PI)
