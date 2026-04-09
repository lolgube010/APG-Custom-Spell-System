extends CharacterBody3D

const MAX_HP: float = 100.0

var hp: float = MAX_HP
var _mesh_mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemies")
	# Grab a duplicate of the mesh material so we can flash it on hit
	var mi := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mi and mi.get_active_material(0):
		_mesh_mat = mi.get_active_material(0).duplicate()
		mi.material_override = _mesh_mat

func take_damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)
	_spawn_damage_label(amount)
	_flash_hit()
	if hp <= 0.0:
		_on_death()

func _on_death() -> void:
	hp = MAX_HP
	if is_instance_valid(_mesh_mat):
		# Flash white on death reset
		_mesh_mat.albedo_color = Color.WHITE
		await get_tree().create_timer(0.15).timeout
		_mesh_mat.albedo_color = Color(0.78, 0.44, 0.18)

func _flash_hit() -> void:
	if not is_instance_valid(_mesh_mat):
		return
	_mesh_mat.albedo_color = Color(1.0, 0.6, 0.2)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_mesh_mat):
		_mesh_mat.albedo_color = Color(0.78, 0.44, 0.18)

func _spawn_damage_label(amount: float) -> void:
	var label := Label3D.new()
	label.text = str(int(amount)) if amount == int(amount) else ("%.1f" % amount)
	label.font_size = 72
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 1
	label.outline_size = 10
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	label.modulate = Color(1.0, 0.25, 0.1) if amount >= 20.0 else Color(1.0, 0.88, 0.1)

	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector3(
		randf_range(-0.35, 0.35), 2.1, randf_range(-0.35, 0.35))

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y",
		label.global_position.y + 1.6, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.45)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
