extends Area3D

var parent_spell: SpellBase

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	_apply_element_color()
	# Wait one physics frame so Area3D has processed its overlaps
	await get_tree().create_timer(0.05).timeout
	_detonate()

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

func _detonate() -> void:
	if not is_instance_valid(parent_spell):
		return
	for body in get_overlapping_bodies():
		if body is StaticBody3D:
			continue
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	parent_spell.queue_free()
