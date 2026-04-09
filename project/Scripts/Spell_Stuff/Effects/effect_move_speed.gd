extends EffectBase

var amount: float = 2.0  # speed multiplier, set from spell graph

# Static stack so multiple simultaneous MoveSpeed effects recalculate from
# the true base rather than each restoring a stale snapshot.
static var _stack: Array[float] = []
static var _walk_base: float = 0.0
static var _sprint_base: float = 0.0

func _ready() -> void:
	if _stack.is_empty():
		_walk_base = player_root.WalkSpeed
		_sprint_base = player_root.SprintSpeed
	_stack.append(amount)
	_apply_stack()
	super()

func remove_effect() -> void:
	_stack.erase(amount)
	_apply_stack()

func _apply_stack() -> void:
	if _stack.is_empty():
		player_root.WalkSpeed = _walk_base
		player_root.SprintSpeed = _sprint_base
		return
	var total: float = 1.0
	for m in _stack:
		total *= m
	player_root.WalkSpeed = _walk_base * total
	player_root.SprintSpeed = _sprint_base * total
