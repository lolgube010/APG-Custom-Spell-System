extends ShapeBase

const TRAIL_INTERVAL: float = 0.15
const TRAIL_LIFETIME: float = 1.2
const TRAIL_RADIUS: float = 0.5

var _timer: float = 0.0

func _ready() -> void:
	super()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	_timer += delta
	if _timer >= TRAIL_INTERVAL:
		_timer -= TRAIL_INTERVAL
		_spawn_trail_zone(global_position)

func _spawn_trail_zone(pos: Vector3) -> void:
	var zone := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = TRAIL_RADIUS
	col.shape = shape
	zone.add_child(col)
	var captured_spell := parent_spell
	var captured_shape := self
	zone.body_entered.connect(func(body: Node3D):
		if body is StaticBody3D or not is_instance_valid(captured_spell):
			return
		captured_shape._damage_body(body, zone.global_transform)
	)
	get_tree().current_scene.add_child(zone)
	zone.global_position = pos
	get_tree().create_timer(TRAIL_LIFETIME).timeout.connect(func():
		if is_instance_valid(zone):
			zone.queue_free()
	)
