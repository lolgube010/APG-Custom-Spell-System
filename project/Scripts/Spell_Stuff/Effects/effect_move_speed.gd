extends EffectBase

var amount: float = 2.0  # speed multiplier, set from spell graph

var _original_walk: float
var _original_sprint: float

func _ready() -> void:
	_original_walk = player_root.WalkSpeed
	_original_sprint = player_root.SprintSpeed
	player_root.WalkSpeed = _original_walk * amount
	player_root.SprintSpeed = _original_sprint * amount
	super()

func remove_effect() -> void:
	player_root.WalkSpeed = _original_walk
	player_root.SprintSpeed = _original_sprint
