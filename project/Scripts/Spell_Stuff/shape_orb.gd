extends Area3D

var parent_spell: SpellBase

func _ready() -> void:
	# Find our parent container
	parent_spell = get_parent() as SpellBase
	
	# Connect the collision signal so we know when we hit a wall or enemy
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	
	# The parent container's local Z axis was perfectly aimed by the player's camera.
	# We just push the parent forward along that axis!
	var forward_direction = -parent_spell.global_transform.basis.z
	parent_spell.global_position += forward_direction * parent_spell.speed_mult * delta

func _on_body_entered(body: Node3D) -> void:
	print("Fireball collided with: ", body.name)
	
	# Here is where we'd eventually check for Triggers like OnHit!
	# For now, just destroy the projectile container.
	#parent_spell.queue_free()
