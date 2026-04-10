extends EffectBase

var amount_vec: Vector3 = Vector3(2.0, 2.0, 2.0)

var _original_scale: Vector3

func _ready() -> void:
	_original_scale = target.scale
	target.scale = amount_vec
	super()

func remove_effect() -> void:
	if is_instance_valid(target):
		target.scale = _original_scale
