extends EffectBase

var amount: float = 10.0  # max radius in metres

func _ready() -> void:
	is_one_shot = true
	super()
	var angle := randf() * TAU
	var dist := sqrt(randf()) * amount  # sqrt for uniform distribution inside circle
	player_root.global_position += Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	queue_free()
