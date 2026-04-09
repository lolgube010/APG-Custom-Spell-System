extends Area3D

var parent_spell: SpellBase
var _hit_bodies: Array = []

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
	if body is StaticBody3D or _hit_bodies.has(body):
		return
	_hit_bodies.append(body)
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	# Wall persists — does not destroy itself on hit
