extends ShapeBase

const BEAM_LENGTH: float = 12.0

## Override: also apply emission so the beam glows with the element colour.
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
	var color: Color = SpellGlobals.ELEMENT_COLORS[parent_spell.element]
	dup.albedo_color = color
	dup.emission = color
	mesh.material_override = dup

## Override: fire triggers at the point on the beam axis nearest to the hit body,
## not at the beam's own origin (which is the cast point at the wand).
func _on_body_entered(body: Node3D) -> void:
	if _bounce_cooldown:
		return
	var hit_xform := _hit_transform(body)
	if body is StaticBody3D:
		if parent_spell.does_ricochet:
			_do_ricochet()
			return
		if parent_spell.is_environment_piercing:
			return
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, hit_xform)
		parent_spell.end_spell(hit_xform)
		return
	if body.has_method("take_damage"):
		body.take_damage(parent_spell.damage)
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, hit_xform)
	if not parent_spell.is_piercing:
		parent_spell.end_spell(hit_xform)

## Project the body's world position onto the beam axis (clamped to beam length)
## and return a Transform3D at that point with the beam's orientation.
func _hit_transform(body: Node3D) -> Transform3D:
	var origin := parent_spell.global_position
	var forward := -parent_spell.global_transform.basis.z
	var t := clampf((body.global_position - origin).dot(forward), 0.0, BEAM_LENGTH)
	return Transform3D(parent_spell.global_transform.basis, origin + forward * t)
