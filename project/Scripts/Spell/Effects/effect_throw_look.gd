extends EffectBase

var amount: float = 20.0  # launch force

func _ready() -> void:
	is_one_shot = true
	super()
	var camera: Camera3D = player_root.get_node("Head/CameraSmooth/Camera3D")
	player_root.velocity = -camera.global_transform.basis.z * amount
	queue_free()
