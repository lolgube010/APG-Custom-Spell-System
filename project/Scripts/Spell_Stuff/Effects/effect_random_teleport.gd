extends EffectBase

var amount: float = 10.0  # max teleport radius in metres

func _ready() -> void:
	var angle := randf() * TAU
	# sqrt for uniform distribution — without it, most teleports cluster near origin
	var dist := sqrt(randf()) * amount
	player_root.global_position += Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	queue_free()
