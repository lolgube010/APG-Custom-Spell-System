extends EffectBase

const GRAVITY_WEIGHT: float = 500.0

var _original_weight: float

func _ready() -> void:
	_original_weight = player_root.Gravity.Weight
	player_root.Gravity.Weight = GRAVITY_WEIGHT
	super()

func remove_effect() -> void:
	player_root.Gravity.Weight = _original_weight
