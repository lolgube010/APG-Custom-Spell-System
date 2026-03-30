# modifier_amplify.gd
class_name ModifierAmplify extends Resource

@export var multiplier: float = 2.0

func apply_modifier(context: SpellContext) -> void:
	context.magnitude *= multiplier
