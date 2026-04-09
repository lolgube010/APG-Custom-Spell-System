extends EffectBase

var amount: float = 500.0  # gravity weight, set from spell graph

var _original_weight: float

func _ready() -> void:
	_original_weight = player_root.Gravity.Weight
	player_root.Gravity.Weight = amount
	super()

func remove_effect() -> void:
	player_root.Gravity.Weight = _original_weight
