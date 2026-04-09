class_name EffectBase
extends Node

var player_root
var duration: float = 5.0
# Set to true when the effect needs its timer to run in real time (e.g. SlowMo).
var real_time_duration: bool = false

func _ready() -> void:
	if duration > 0:
		await get_tree().create_timer(duration, true, false, real_time_duration).timeout
		remove_effect()
		queue_free()

func remove_effect() -> void:
	pass
