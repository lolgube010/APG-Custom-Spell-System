# spell_trigger.gd (Abstract Base)
class_name SpellTrigger extends Resource

# By exporting an array of other triggers/deliveries/effects, 
# you create your nested tree structure!
# todo, make inherit from a common spell class so we don't get too many options
@export var next_actions: Array[Resource] = [] 

# Virtual function
func setup_trigger(context: SpellContext, attached_node: Node) -> void:
	pass
