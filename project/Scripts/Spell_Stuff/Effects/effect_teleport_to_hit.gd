extends EffectBase

## Set automatically by _apply_child_spell_effects from the OnHit spawn transform.
## Use this effect inside an OnHit trigger chain: Orb → OnHit → SelfInstant → TeleportToHit
var hit_position: Vector3

func _ready() -> void:
	player_root.global_position = hit_position
	queue_free()
