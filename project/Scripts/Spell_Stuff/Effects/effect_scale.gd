extends Node

# TODO: Scaling a CharacterBody3D breaks collision. Implement by scaling the visual
# mesh child separately once the player scene structure is finalised.
var player_root
var duration: float = 5.0

func _ready() -> void:
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		remove_effect()
		queue_free()

func remove_effect() -> void:
	pass
