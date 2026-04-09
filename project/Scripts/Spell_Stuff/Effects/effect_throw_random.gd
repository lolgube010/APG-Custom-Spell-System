extends EffectBase

# One-shot launch in a random horizontal direction with an upward component.
var amount: float = 20.0  # launch force, set from spell graph

func _ready() -> void:
	var direction := Vector3(
		randf_range(-1.0, 1.0),
		0.5,
		randf_range(-1.0, 1.0)
	).normalized()
	player_root.velocity = direction * amount
	queue_free()
