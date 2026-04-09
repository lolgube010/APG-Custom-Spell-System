extends Area3D

var parent_spell: SpellBase
const TRAIL_INTERVAL: float = 0.15
const TRAIL_LIFETIME: float = 1.2
const TRAIL_RADIUS: float = 0.5

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	body_entered.connect(_on_body_entered)
	_apply_element_color()
	_start_trail()

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

func _start_trail() -> void:
	while is_instance_valid(self):
		await get_tree().create_timer(TRAIL_INTERVAL).timeout
		if not is_instance_valid(self):
			break
		_spawn_trail_zone(global_position)

func _spawn_trail_zone(pos: Vector3) -> void:
	var zone := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = TRAIL_RADIUS
	col.shape = shape
	zone.add_child(col)
	var captured_spell := parent_spell
	zone.body_entered.connect(func(body: Node3D):
		if body is StaticBody3D or not is_instance_valid(captured_spell):
			return
		captured_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, zone.global_transform)
	)
	get_tree().current_scene.add_child(zone)
	zone.global_position = pos
	get_tree().create_timer(TRAIL_LIFETIME).timeout.connect(func():
		if is_instance_valid(zone):
			zone.queue_free()
	)

func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D:
		if parent_spell.is_environment_piercing:
			return
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
		parent_spell.end_spell(global_transform)
		return
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	if not parent_spell.is_piercing:
		parent_spell.end_spell(global_transform)
