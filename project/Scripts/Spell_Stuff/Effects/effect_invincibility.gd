extends Node

# TODO: PlayerController.HealthSystem needs an invincibility flag exposed.
# Wire up once the health system API is confirmed.
var player_root
var duration: float = 5.0

func _ready() -> void:
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		remove_effect()
		queue_free()

func remove_effect() -> void:
	pass
