extends Node

# Steers toward the nearest node in the "enemies" group.
# Tag your enemy nodes with the "enemies" group in the Godot editor.

var parent_spell: SpellBase
var target: Node3D = null
const TURN_SPEED: float = 3.0

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	_find_nearest_target()

func _find_nearest_target() -> void:
	var closest_dist = INF
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node3D:
			var d = parent_spell.global_position.distance_to(node.global_position)
			if d < closest_dist:
				closest_dist = d
				target = node

func _physics_process(delta: float) -> void:
	if not parent_spell: return
	var forward = -parent_spell.global_transform.basis.z
	if is_instance_valid(target):
		var to_target = (target.global_position - parent_spell.global_position).normalized()
		forward = forward.lerp(to_target, TURN_SPEED * delta).normalized()
	parent_spell.global_position += forward * parent_spell.speed * delta
