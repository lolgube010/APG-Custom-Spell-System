class_name EffectBase
extends Node

var target: Node3D
var caster: Node3D  # always the player; used by effects that need player context (e.g. ThrowLook)
var duration: float = 5.0       # set by Spell_Casting before add_child; -1 = permanent
var real_time_duration: bool = false
var is_one_shot: bool = false   # set true before super() to skip the duration timer entirely

func _ready() -> void:
	if is_one_shot:
		return
	if duration >= 0.0:
		get_tree().create_timer(duration, true, false, real_time_duration).timeout.connect(_on_duration_expired)

func _on_duration_expired() -> void:
	remove_effect()
	queue_free()

## Override to undo persistent changes (speed boosts, gravity changes, etc.).
## Caller is responsible for queue_free() after calling this.
func remove_effect() -> void:
	pass
