extends EffectBase

var amount: float = 0.3  # time scale (0–1), set from spell graph

# Static stack; the lowest (most slowed) active value wins. Normal time is
# restored when all slow-mo effects expire, regardless of removal order.
static var _stack: Array[float] = []
static var _base_scale: float = 1.0

func _ready() -> void:
	if _stack.is_empty():
		_base_scale = Engine.time_scale
	_stack.append(amount)
	Engine.time_scale = _stack.min()
	real_time_duration = true
	super()

func remove_effect() -> void:
	_stack.erase(amount)
	Engine.time_scale = _stack.min() if not _stack.is_empty() else _base_scale
