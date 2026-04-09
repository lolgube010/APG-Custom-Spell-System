extends ShapeBase

## Cone whose origin is pinned at the cast point.
## A CylinderMesh (top_radius=grow, bottom_radius=0) is generated in code so the
## tip stays at origin and the wide end sweeps outward each frame.
## Dot-product filter limits hits to the forward arc.

const CONE_HALF_ANGLE_COS := 0.65  # collision arc ~49°
const CONE_VISUAL_TAN     := 0.36  # visual half-angle ~20° (tan 20°)
const CONE_LIFETIME       := 1.2   # seconds before the cone disappears
const GROW_SPEED_MULT     := 3.0   # grow faster than spell speed by default

var _forward:    Vector3
var _elapsed:    float = 0.0
var _col_shape:  SphereShape3D
var _cone_mesh:  CylinderMesh
var _cone_mi:    MeshInstance3D
var _cone_mat:   StandardMaterial3D
var _element_color: Color = Color(1.0, 0.9, 0.1)

# Override so base _apply_element_color doesn't crash looking for MeshInstance3D
func _apply_element_color() -> void:
	if SpellGlobals.ELEMENT_COLORS.has(parent_spell.element):
		_element_color = SpellGlobals.ELEMENT_COLORS[parent_spell.element]

func _ready() -> void:
	super()  # sets parent_spell, connects body_entered, calls overridden _apply_element_color

	# Remove the placeholder MeshInstance3D from the tscn (if any)
	var old_mi := get_node_or_null("MeshInstance3D")
	if old_mi:
		old_mi.queue_free()

	_col_shape = $CollisionShape3D.shape as SphereShape3D

	# Build the programmatic cone mesh
	_cone_mat = StandardMaterial3D.new()
	_cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cone_mat.albedo_color = Color(_element_color.r, _element_color.g, _element_color.b, 0.45)
	_cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # visible from both sides

	_cone_mesh = CylinderMesh.new()
	_cone_mesh.top_radius    = 0.01   # wide end (forward) — grows each frame
	_cone_mesh.bottom_radius = 0.0    # tip (at origin) — stays zero
	_cone_mesh.height        = 0.01

	_cone_mi = MeshInstance3D.new()
	_cone_mi.mesh = _cone_mesh
	_cone_mi.material_override = _cone_mat
	add_child(_cone_mi)

	_init_top_level()

func _init_top_level() -> void:
	await get_tree().process_frame
	# Capture flat forward from the spell's orientation, then pin in place
	var fwd := -parent_spell.global_transform.basis.z
	_forward = Vector3(fwd.x, 0.0, fwd.z).normalized()
	if _forward.length_squared() < 0.01:
		_forward = Vector3.FORWARD
	top_level = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	_elapsed += delta
	if _elapsed >= CONE_LIFETIME:
		parent_spell.end_spell(global_transform)
		return
	var h := maxf(0.05, parent_spell.speed * GROW_SPEED_MULT * _elapsed)

	# Grow the collision sphere
	_col_shape.radius = h

	# Update cone mesh:
	#   bottom_radius = 0  → tip, maps to +Z (backward → origin) after -90° X rotation
	#   top_radius    = R  → wide end, maps to -Z (forward) after -90° X rotation
	#   position (0, 0, -h/2) slides the tip to the origin
	_cone_mesh.height     = h
	_cone_mesh.top_radius = h * CONE_VISUAL_TAN

	var rot := Basis(Vector3.RIGHT, -PI / 2.0)  # -90° around X: local Y → world -Z
	_cone_mi.transform = Transform3D(rot, Vector3(0.0, 0.0, -h * 0.5))

func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D:
		return  # cone ignores environment
	var to_body := (body.global_position - global_position).normalized()
	if to_body.dot(_forward) < CONE_HALF_ANGLE_COS:
		return
	if body.has_method("take_damage"):
		body.take_damage(parent_spell.damage)
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	if not parent_spell.is_piercing:
		parent_spell.end_spell(global_transform)
