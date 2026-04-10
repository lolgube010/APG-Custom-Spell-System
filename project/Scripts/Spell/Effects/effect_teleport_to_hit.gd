extends EffectBase

## Always teleports the caster, not the hit body.
var target_self: bool = true

## Set by SpellFactory from the OnHit spawn transform before add_child.
var hit_position: Vector3

func _ready() -> void:
	is_one_shot = true
	super()
	target.global_position = hit_position
	queue_free()
