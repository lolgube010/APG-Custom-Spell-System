extends Area3D

var parent_spell: SpellBase
var _hit_bodies: Array = []  # one trigger fire per body per AOE instance

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	body_entered.connect(_on_body_entered)
	_apply_element_color()
	# global_transform is set by Spell_Casting after add_child; wait one frame
	_snap_to_ground()

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

func _snap_to_ground() -> void:
	await get_tree().process_frame
	var space := get_world_3d().direct_space_state
	var from := parent_spell.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 100.0)
	query.collision_mask = 1  # environment layer only
	var result := space.intersect_ray(query)
	if result:
		parent_spell.global_position = result.position

func _on_body_entered(body: Node3D) -> void:
	if _hit_bodies.has(body) or body is StaticBody3D:
		return
	_hit_bodies.append(body)
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	# AOE persists for the spell's lifetime — does not destroy itself on hit
