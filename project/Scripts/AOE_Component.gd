# aoe_component.gd
class_name AoeComponent extends SpellComponent

@export var radius: float = 5.0
@export var damage_multiplier: float = 1.0

func execute(context: SpellContext) -> void:
	# Spawn an Area3D (or 2D) at the context's target_position
	# Apply damage to everything in radius
	print("BOOM! AOE at ", context.target_position, " for ", context.base_damage * damage_multiplier, " damage!")
	
	# If there are more components (e.g., AOE spawns smaller projectiles), execute them!
	if not context.remaining_components.is_empty():
		var next_comp = context.remaining_components.pop_front()
		next_comp.execute(context)
