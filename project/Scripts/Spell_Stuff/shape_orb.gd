extends Area3D

var parent_spell: SpellBase

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
	print("Fireball collided with: ", body.name)

	# Here is where we'd eventually check for Triggers like OnHit!
	# For now, just destroy the projectile container.
	#parent_spell.queue_free()
