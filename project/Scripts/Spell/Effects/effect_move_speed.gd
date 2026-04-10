extends EffectBase

var amount: float = 2.0  # speed multiplier, set from spell graph

# Static stack so multiple simultaneous MoveSpeed effects recalculate from
# the true base rather than each restoring a stale snapshot.
static var _stack: Array[float] = []
static var _walk_base: float = 0.0
static var _sprint_base: float = 0.0

func _ready() -> void:
	if not "WalkSpeed" in target:
		queue_free()
		return
	if _stack.is_empty():
		_walk_base = target.WalkSpeed
		_sprint_base = target.SprintSpeed
	_stack.append(amount)
	_apply_stack()
	super()

func remove_effect() -> void:
	_stack.erase(amount)
	_apply_stack()

func _apply_stack() -> void:
	if not is_instance_valid(target) or not "WalkSpeed" in target:
		return
	var total: float = _stack.reduce(func(a, b): return a * b, 1.0)
	target.WalkSpeed = _walk_base * total
	target.SprintSpeed = _sprint_base * total
