extends EffectBase

var amount: float = 500.0  # gravity weight, set from spell graph

# Static stack; the heaviest active weight wins. Base is restored when all
# gravity effects expire, regardless of removal order.
static var _stack: Array[float] = []
static var _base_weight: float = 0.0

func _ready() -> void:
	if not "Gravity" in target:
		queue_free()
		return
	if _stack.is_empty():
		_base_weight = target.Gravity.Weight
	_stack.append(amount)
	target.Gravity.Weight = _stack.max()
	super()

func remove_effect() -> void:
	_stack.erase(amount)
	if not is_instance_valid(target) or not "Gravity" in target:
		return
	target.Gravity.Weight = _stack.max() if not _stack.is_empty() else _base_weight
