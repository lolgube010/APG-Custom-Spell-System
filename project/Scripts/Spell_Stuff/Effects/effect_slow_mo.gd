extends EffectBase

var amount: float = 0.3  # time scale (0–1), set from spell graph

func _ready() -> void:
	Engine.time_scale = amount
	real_time_duration = true
	super()

func remove_effect() -> void:
	Engine.time_scale = 1.0
