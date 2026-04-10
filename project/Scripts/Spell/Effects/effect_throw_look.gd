extends EffectBase

var amount: float = 20.0  # launch force

func _ready() -> void:
	is_one_shot = true
	super()
	var camera: Camera3D = caster.get_node_or_null("Head/CameraSmooth/Camera3D") if is_instance_valid(caster) else null
	var direction := -camera.global_transform.basis.z if camera else -target.global_transform.basis.z
	target.velocity = direction * amount
	queue_free()
