extends Area3D

var parent_spell: SpellBase
var _bounce_cooldown: bool = false

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	body_entered.connect(_on_body_entered)
	_apply_element_color()

func _apply_element_color() -> void:
	if not SpellGlobals.ELEMENT_COLORS.has(parent_spell.element):
		return
	var mesh_instance := $MeshInstance3D as MeshInstance3D
	var material := mesh_instance.get_active_material(0).duplicate() as StandardMaterial3D
	material.albedo_color = SpellGlobals.ELEMENT_COLORS[parent_spell.element]
	mesh_instance.material_override = material

func _on_body_entered(body: Node3D) -> void:
	if _bounce_cooldown:
		return

	var is_environment := body is StaticBody3D

	if is_environment and parent_spell.does_ricochet:
		_do_ricochet()
		return

	if is_environment and parent_spell.is_environment_piercing:
		return  # pass through walls

	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	parent_spell.queue_free()

func _do_ricochet() -> void:
	_bounce_cooldown = true
	get_tree().create_timer(0.1).timeout.connect(func(): _bounce_cooldown = false)

	var forward := -parent_spell.global_transform.basis.z
	var space := get_world_3d().direct_space_state

	# Cast from slightly behind to slightly ahead to find the surface normal
	var query := PhysicsRayQueryParameters3D.create(
		parent_spell.global_position - forward * 0.3,
		parent_spell.global_position + forward * 0.3
	)
	var result := space.intersect_ray(query)

	if result:
		var normal: Vector3 = result.normal
		var reflected := forward.reflect(normal).normalized()
		# Push spell out of the surface so it doesn't re-enter next frame
		parent_spell.global_position = result.position + normal * 0.15
		# Rotate the spell container so all path scripts follow the new direction
		var up := Vector3.UP if abs(reflected.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
		parent_spell.look_at(parent_spell.global_position + reflected, up)
	else:
		# Couldn't find surface (e.g. hit a corner exactly); just reverse
		parent_spell.rotate_y(PI)
