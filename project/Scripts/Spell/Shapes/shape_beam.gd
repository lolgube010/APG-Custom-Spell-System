extends ShapeBase

const BEAM_LENGTH: float = 12.0

## Override: beam also glows with element colour.
func _configure_material(mat: StandardMaterial3D, color: Color) -> void:
	mat.albedo_color = color
	mat.emission = color

## Override: fire triggers at the point on the beam axis nearest to the hit body.
func _get_hit_transform(body: Node3D) -> Transform3D:
	var origin := parent_spell.global_position
	var forward := -parent_spell.global_transform.basis.z
	var t := clampf((body.global_position - origin).dot(forward), 0.0, BEAM_LENGTH)
	return Transform3D(parent_spell.global_transform.basis, origin + forward * t)
