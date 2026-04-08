extends EffectBase

const TIME_SCALE: float = 0.3

func _ready() -> void:
	Engine.time_scale = TIME_SCALE
	if duration > 0:
		# ignore_time_scale = true so the timer runs in real seconds, not slowed game time
		await get_tree().create_timer(duration, true, false, true).timeout
		remove_effect()
		queue_free()

func remove_effect() -> void:
	Engine.time_scale = 1.0
