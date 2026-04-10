extends PathBase

# Steers toward the nearest node in the "enemies" group.

const TURN_SPEED: float = 5.0          # higher = sharper turns
const REACQUIRE_INTERVAL: float = 0.5  # re-scan for closer targets every N seconds

var _target: Node3D = null
var _reacquire_timer: float = 0.0      # starts at 0 so first physics frame triggers a scan
var _direction: Vector3                # accumulated movement direction; lazy-inited first frame

func _init_direction() -> void:
	_direction = -parent_spell.global_transform.basis.z

func _physics_process(delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	super(delta)

	_reacquire_timer -= delta
	if _reacquire_timer <= 0.0 or not is_instance_valid(_target):
		_reacquire_timer = REACQUIRE_INTERVAL
		_acquire_target()

	if is_instance_valid(_target):
		var to_target := (_target.global_position - parent_spell.global_position).normalized()
		_direction = _direction.lerp(to_target, TURN_SPEED * delta).normalized()

	parent_spell.global_position += _direction * parent_spell.speed * delta

func _acquire_target() -> void:
	var best: Node3D = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var d := parent_spell.global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	_target = best
