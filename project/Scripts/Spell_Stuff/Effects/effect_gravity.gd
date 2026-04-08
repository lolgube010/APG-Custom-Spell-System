extends Node

var player_root
var duration: float = 5.0
const GRAVITY_WEIGHT: float = 500.0

var _original_weight: float

func _ready() -> void:
	_original_weight = player_root.Gravity.Weight
	player_root.Gravity.Weight = GRAVITY_WEIGHT
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		remove_effect()
		queue_free()

func remove_effect() -> void:
	player_root.Gravity.Weight = _original_weight
