extends EffectBase

# One-shot launch in the direction the camera is facing.
var amount: float = 20.0  # launch force, set from spell graph

func _ready() -> void:
	var camera: Camera3D = player_root.get_node("Head/CameraSmooth/Camera3D")
	var direction := -camera.global_transform.basis.z
	player_root.velocity = direction * amount
	queue_free()
