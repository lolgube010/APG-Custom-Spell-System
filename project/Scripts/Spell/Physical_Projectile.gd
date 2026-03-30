# physical_projectile.gd (Attached to the spawned Node)
extends Area3D

var context_payload: SpellContext

func setup(dir: Vector3, spd: float, ctx: SpellContext):
	# Setup movement logic here...
	context_payload = ctx
	# Important: Remove the projectile from the chain so it doesn't loop forever!
	context_payload.remaining_components.pop_front() 

# Connected to the Area3D's 'body_entered' signal
func _on_body_entered(body: Node):
	# 1. Update the context with the hit location
	context_payload.target_position = global_position
	
	# 2. Trigger the next step in the chain!
	if not context_payload.remaining_components.is_empty():
		var next_component = context_payload.remaining_components[0]
		next_component.execute(context_payload)
		
	# 3. Destroy this projectile
	queue_free()
