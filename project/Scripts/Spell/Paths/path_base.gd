class_name PathBase
extends Node

var parent_spell: SpellBase
var _initialized: bool = false

func _ready() -> void:
	parent_spell = get_parent() as SpellBase

## Called by PathBase on the first physics frame where parent_spell is valid.
## Override to capture initial direction/position from the spell's transform.
## Subclasses must call super(delta) at the top of _physics_process to trigger this.
func _init_direction() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if _initialized or not is_instance_valid(parent_spell):
		return
	_init_direction()
	_initialized = true
