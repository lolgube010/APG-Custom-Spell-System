extends EffectBase

var amount: float = 500.0  # gravity weight, set from spell graph

# Static stack; the heaviest active weight wins. Base is restored when all
# gravity effects expire, regardless of removal order.
static var _stack: Array[float] = []
static var _base_weight: float = 0.0

func _ready() -> void:
	if _stack.is_empty():
		_base_weight = player_root.Gravity.Weight
	_stack.append(amount)
	player_root.Gravity.Weight = _stack.max()
	super()

func remove_effect() -> void:
	_stack.erase(amount)
	player_root.Gravity.Weight = _stack.max() if not _stack.is_empty() else _base_weight
