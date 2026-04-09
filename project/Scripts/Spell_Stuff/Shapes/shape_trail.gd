extends ShapeBase

const TRAIL_INTERVAL: float = 0.15
const TRAIL_LIFETIME: float = 1.2
const TRAIL_RADIUS: float = 0.5

func _ready() -> void:
	super()
	_start_trail()

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
		var killed := false
		if body.has_method("take_damage"):
			killed = body.take_damage(captured_spell.damage)
		captured_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, zone.global_transform)
		if killed:
			captured_spell.fire_trigger(SpellGlobals.SpellTrigger.OnKill, zone.global_transform)
	)
	get_tree().current_scene.add_child(zone)
	zone.global_position = pos
	get_tree().create_timer(TRAIL_LIFETIME).timeout.connect(func():
		if is_instance_valid(zone):
			zone.queue_free()
	)
