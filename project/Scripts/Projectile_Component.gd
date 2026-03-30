# projectile_component.gd
class_name ProjectileComponent extends SpellComponent

@export var speed: float = 20.0
@export var projectile_scene: PackedScene # The visual/collision Node to spawn

func execute(context: SpellContext) -> void:
	# 1. Spawn the physical projectile node
	var proj_instance = projectile_scene.instantiate()
	proj_instance.global_position = context.caster.global_position
	
	# 2. Give the projectile its movement data AND the remaining spell context
	proj_instance.setup(context.current_direction, speed, context)
	
	# 3. Add to the active scene tree
	context.caster.get_tree().root.add_child(proj_instance)
