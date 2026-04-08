extends Node

var player_root
var duration: float = 5.0
const SPEED_MULTIPLIER: float = 2.0

var _original_walk: float
var _original_sprint: float

func _ready() -> void:
	_original_walk = player_root.WalkSpeed
	_original_sprint = player_root.SprintSpeed
	player_root.WalkSpeed = _original_walk * SPEED_MULTIPLIER
	player_root.SprintSpeed = _original_sprint * SPEED_MULTIPLIER
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		remove_effect()
		queue_free()

func remove_effect() -> void:
	player_root.WalkSpeed = _original_walk
	player_root.SprintSpeed = _original_sprint
