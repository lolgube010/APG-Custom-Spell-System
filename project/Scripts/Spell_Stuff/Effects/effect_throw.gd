extends Node

# One-shot upward launch. Duration is unused — effect is instant and irreversible.
var player_root
var duration: float = 5.0
const THROW_FORCE: float = 20.0

func _ready() -> void:
	player_root.Velocity = Vector3(player_root.Velocity.X, THROW_FORCE, player_root.Velocity.Z)
	queue_free()

func remove_effect() -> void:
	pass
