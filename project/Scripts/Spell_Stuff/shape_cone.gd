extends Area3D

var parent_spell: SpellBase
const CONE_HALF_ANGLE_COS := 0.65  # approx 49° half-angle

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	body_entered.connect(_on_body_entered)
	_apply_element_color()

func _apply_element_color() -> void:
	if not SpellGlobals.ELEMENT_COLORS.has(parent_spell.element):
		return
	var mesh_instance := $MeshInstance3D as MeshInstance3D
	var mat = mesh_instance.get_active_material(0)
	if not mat:
		return
	var material := mat.duplicate() as StandardMaterial3D
	material.albedo_color = SpellGlobals.ELEMENT_COLORS[parent_spell.element]
	mesh_instance.material_override = material

func _on_body_entered(body: Node3D) -> void:
	# Filter out bodies not within the cone angle
	var to_body := (body.global_position - global_position).normalized()
	var forward := -global_transform.basis.z
	if to_body.dot(forward) < CONE_HALF_ANGLE_COS:
		return

	if body is StaticBody3D:
		if parent_spell.is_environment_piercing:
			return
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
		parent_spell.queue_free()
		return
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	if not parent_spell.is_piercing:
		parent_spell.queue_free()
