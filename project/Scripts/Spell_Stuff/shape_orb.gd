extends Area3D

var parent_spell: SpellBase

func _ready() -> void:
	# Find our parent container
	parent_spell = get_parent() as SpellBase
	
	# Connect the collision signal so we know when we hit a wall or enemy
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	print("Fireball collided with: ", body.name)
	
	# Here is where we'd eventually check for Triggers like OnHit!
	# For now, just destroy the projectile container.
	#parent_spell.queue_free()
