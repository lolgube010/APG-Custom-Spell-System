extends Node

var parent_spell: SpellBase

func _ready() -> void:
	parent_spell = get_parent() as SpellBase

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	var forward_direction = -parent_spell.global_transform.basis.z
	parent_spell.global_position += forward_direction * parent_spell.speed * delta
