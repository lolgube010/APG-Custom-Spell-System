extends Node

var parent_spell: SpellBase

func _ready() -> void:
	parent_spell = get_parent() as SpellBase

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	parent_spell.global_position += Vector3.UP * parent_spell.speed * delta
