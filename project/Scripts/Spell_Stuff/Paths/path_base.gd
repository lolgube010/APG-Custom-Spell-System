class_name PathBase
extends Node

var parent_spell: SpellBase

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
