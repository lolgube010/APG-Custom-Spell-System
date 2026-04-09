extends Node

const TRAIL_INTERVAL: float = 0.08   # seconds between trail orbs
const TRAIL_LIFETIME: float = 0.7    # how long each orb lasts
const TRAIL_RADIUS:   float = 0.22   # visual + collision radius

var parent_spell: SpellBase
var _element_color: Color = Color(1.0, 1.0, 1.0)

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	if SpellGlobals.ELEMENT_COLORS.has(parent_spell.element):
		_element_color = SpellGlobals.ELEMENT_COLORS[parent_spell.element]
	_run_trail()

func _run_trail() -> void:
	while is_instance_valid(self):
		await get_tree().create_timer(TRAIL_INTERVAL).timeout
		if not is_instance_valid(self) or not is_instance_valid(parent_spell):
			break
		_spawn_trail_orb(parent_spell.global_position)

func _spawn_trail_orb(pos: Vector3) -> void:
	# --- Visual: glowing sphere that fades out and shrinks ---
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = TRAIL_RADIUS
	mesh.height  = TRAIL_RADIUS * 2.0
	mi.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color              = Color(_element_color.r, _element_color.g, _element_color.b, 0.75)
	mat.emission_enabled          = true
	mat.emission                  = _element_color
	mat.emission_energy_multiplier = 1.5
	mi.material_override = mat

	get_tree().current_scene.add_child(mi)
	mi.global_position = pos

	var tween := mi.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mat, "albedo_color:a", 0.0,               TRAIL_LIFETIME)
	tween.tween_property(mi,  "scale",          Vector3.ONE * 0.05, TRAIL_LIFETIME)
	tween.set_parallel(false)
	tween.tween_callback(mi.queue_free)

	# --- Collision zone so trail positions can trigger OnHit ---
	var zone := Area3D.new()
	var col  := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = TRAIL_RADIUS
	col.shape = shape
	zone.add_child(col)
	var captured_spell := parent_spell
	zone.body_entered.connect(func(body: Node3D):
		if body is StaticBody3D or not is_instance_valid(captured_spell):
			return
		captured_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, zone.global_transform)
	)
	get_tree().current_scene.add_child(zone)
	zone.global_position = pos
	get_tree().create_timer(TRAIL_LIFETIME).timeout.connect(func():
		if is_instance_valid(zone):
			zone.queue_free()
	)
