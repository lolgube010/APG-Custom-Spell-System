extends EffectBase

var amount: float = 3.0  # lift speed m/s, set from spell graph

func _ready() -> void:
	super()

func _physics_process(_delta: float) -> void:
	if not target: return
	target.velocity = Vector3(target.velocity.x, amount, target.velocity.z)
