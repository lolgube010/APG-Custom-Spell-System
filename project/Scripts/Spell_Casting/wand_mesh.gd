extends Node
@onready var animation_player: AnimationPlayer = $"../../../../AnimationPlayer"
@export var camera: Camera3D
@export var wand_point: Marker3D
signal spell_cast(spawn_transform: Transform3D)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				animation_player.play("cast_hold")
			if !event.pressed:
				animation_player.play("cast_release")

func animation_callback_point():
	spell_cast.emit(get_spell_spawn_transform())

func get_spell_spawn_transform() -> Transform3D:
	# 1. Start with a blank transform
	var spawn_transform = Transform3D()
	
	# 2. Set the starting position to the tip of the wand
	spawn_transform.origin = wand_point.global_position
	
	# 3. Find out what the player's crosshair is pointing at
	# We project a point 100 meters straight forward from the exact center of the camera
	var aim_target = camera.global_position - camera.global_transform.basis.z * 100.0
	
	# 4. Rotate our spawn transform so the wand points directly at the camera's target
	spawn_transform = spawn_transform.looking_at(aim_target, Vector3.UP)
	
	return spawn_transform
