extends EffectBase

var amount: float = 5.0  # damage per tick, set from spell graph

const TICK_INTERVAL: float = 1.0

func _ready() -> void:
	super()
	_start_poison()

func _start_poison() -> void:
	while is_instance_valid(self):
		await get_tree().create_timer(TICK_INTERVAL).timeout
		if not is_instance_valid(self):
			break
		if target.has_method("take_damage"):
			target.take_damage(amount)
		elif target.get("HealthSystem") != null:
			target.HealthSystem.TakeDamage(amount)
