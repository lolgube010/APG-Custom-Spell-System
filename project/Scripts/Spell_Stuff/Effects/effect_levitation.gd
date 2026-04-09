extends EffectBase

var amount: float = 3.0  # lift speed m/s, set from spell graph

func _physics_process(_delta: float) -> void:
	if not player_root: return
	player_root.velocity = Vector3(player_root.velocity.x, amount, player_root.velocity.z)
