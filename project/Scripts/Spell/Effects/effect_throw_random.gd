extends EffectBase

var amount: float = 20.0  # launch force

func _ready() -> void:
	is_one_shot = true
	super()
	var direction := Vector3(randf_range(-1.0, 1.0), 0.5, randf_range(-1.0, 1.0)).normalized()
	target.velocity = direction * amount
	queue_free()
