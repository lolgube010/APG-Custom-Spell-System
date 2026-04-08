extends PathBase

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	parent_spell.global_position += Vector3.UP * parent_spell.speed * delta
