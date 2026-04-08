extends Node

var player_root
var duration: float = 5.0
const LIFT_SPEED: float = 3.0  # m/s upward

func _ready() -> void:
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		remove_effect()
		queue_free()

func _physics_process(_delta: float) -> void:
	if not player_root: return
	player_root.velocity = Vector3(player_root.velocity.x, LIFT_SPEED, player_root.velocity.z)

func remove_effect() -> void:
	pass
