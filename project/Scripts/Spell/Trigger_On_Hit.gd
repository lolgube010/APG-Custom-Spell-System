# trigger_on_hit.gd
class_name TriggerOnHit extends SpellTrigger

func setup_trigger(context: SpellContext, attached_node: Node) -> void:
	# Assuming attached_node is something like a Projectile Area3D
	if attached_node.has_signal("body_entered"):
		# Connect the physical collision signal to our custom logic
		attached_node.body_entered.connect(_on_impact.bind(context))

func _on_impact(body: Node, context: SpellContext) -> void:
	# Pass the hit target into the context payload!
	context.current_target = body
	
	# Execute the nested components! (This is your nesting in action)
	for action in next_actions:
		if action is SpellEffect:
			action.apply_effect(context)
		elif action is SpellDelivery:
			action.execute_delivery(context)
