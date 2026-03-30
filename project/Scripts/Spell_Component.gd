# spell_component.gd
class_name SpellComponent extends Resource

@export var test1 = 1
@export var components: Array[SpellComponent]

# Virtual function that derived components will override
func execute(context: SpellContext) -> void:
	push_warning("execute() not implemented in base SpellComponent!")
