extends Area3D

var parent_spell: SpellBase
const PULSE_INTERVAL: float = 1.0

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	_apply_element_color()
	_start_pulse()

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

func _start_pulse() -> void:
	while is_instance_valid(self):
		await get_tree().create_timer(PULSE_INTERVAL).timeout
		if not is_instance_valid(self) or not is_instance_valid(parent_spell):
			break
		for body in get_overlapping_bodies():
			if body is StaticBody3D:
				continue
			parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
