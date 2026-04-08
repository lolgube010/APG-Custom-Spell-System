extends PathBase

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	var forward_direction = -parent_spell.global_transform.basis.z
	parent_spell.global_position += forward_direction * parent_spell.speed * delta
