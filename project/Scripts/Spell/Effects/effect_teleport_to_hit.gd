extends EffectBase

## Set by Spell_Casting from the OnHit spawn transform before add_child.
var hit_position: Vector3

func _ready() -> void:
	is_one_shot = true
	super()
	player_root.global_position = hit_position
	queue_free()
