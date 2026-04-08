extends EffectBase

# One-shot upward launch. Duration is unused — effect is instant and irreversible.
const THROW_FORCE: float = 20.0

func _ready() -> void:
	player_root.velocity = Vector3(player_root.velocity.x, THROW_FORCE, player_root.velocity.z)
	queue_free()

func remove_effect() -> void:
	pass
