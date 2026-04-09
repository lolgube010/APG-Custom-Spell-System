extends EffectBase

var amount_vec: Vector3 = Vector3(2.0, 2.0, 2.0)

var _mesh: MeshInstance3D
var _original_scale: Vector3

func _ready() -> void:
	_mesh = player_root.get_node("MeshInstance3D")
	_original_scale = _mesh.scale
	_mesh.scale = amount_vec
	super()

func remove_effect() -> void:
	if is_instance_valid(_mesh):
		_mesh.scale = _original_scale
