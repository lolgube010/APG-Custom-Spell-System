extends EffectBase

const LIFT_SPEED: float = 3.0  # m/s upward

func _ready() -> void:
	super()

func _physics_process(_delta: float) -> void:
	if not player_root: return
	player_root.velocity = Vector3(player_root.velocity.x, LIFT_SPEED, player_root.velocity.z)

func remove_effect() -> void:
	pass
