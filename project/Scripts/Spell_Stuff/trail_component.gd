extends Node

const TRAIL_INTERVAL: float = 0.08   # seconds between trail orbs
const TRAIL_LIFETIME: float = 0.7    # how long each orb lasts
const TRAIL_RADIUS:   float = 0.22   # visual + collision radius

# Pool size must cover the full lifetime window so the oldest slot is always
# expired by the time it gets reused: ceil(TRAIL_LIFETIME / TRAIL_INTERVAL) + 1
const POOL_SIZE: int = 10

var parent_spell: SpellBase
var _element_color: Color = Color(1.0, 1.0, 1.0)

# Shared resources — created once, referenced by every pool slot.
var _shared_mesh: SphereMesh
var _shared_col_shape: SphereShape3D

# Circular pool — pre-allocated in _ready(), reused every TRAIL_INTERVAL.
# All nodes are top_level children so they stay in world-space when the spell moves.
var _pool_mis:   Array = []   # MeshInstance3D per slot
var _pool_mats:  Array = []   # StandardMaterial3D per slot (needs per-slot alpha tween)
var _pool_zones: Array = []   # Area3D per slot
var _pool_idx:   int   = 0

var _spawn_timer: float = 0.0

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	if SpellGlobals.ELEMENT_COLORS.has(parent_spell.element):
		_element_color = SpellGlobals.ELEMENT_COLORS[parent_spell.element]

	_shared_mesh = SphereMesh.new()
	_shared_mesh.radius = TRAIL_RADIUS
	_shared_mesh.height = TRAIL_RADIUS * 2.0

	_shared_col_shape = SphereShape3D.new()
	_shared_col_shape.radius = TRAIL_RADIUS

	var captured_spell := parent_spell
	for i in POOL_SIZE:
		# Visual orb
		var mat := StandardMaterial3D.new()
		mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color               = Color(_element_color.r, _element_color.g, _element_color.b, 0.0)
		mat.emission_enabled           = true
		mat.emission                   = _element_color
		mat.emission_energy_multiplier = 1.5

		var mi := MeshInstance3D.new()
		mi.mesh              = _shared_mesh
		mi.material_override = mat
		mi.visible           = false
		mi.top_level         = true
		add_child(mi)

		# Collision zone
		var zone := Area3D.new()
		var col  := CollisionShape3D.new()
		col.shape = _shared_col_shape
		zone.add_child(col)
		zone.monitoring = false
		zone.top_level  = true
		add_child(zone)

		zone.body_entered.connect(func(body: Node3D):
			if body is StaticBody3D or not is_instance_valid(captured_spell):
				return
			captured_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, zone.global_transform)
		)

		_pool_mis.append(mi)
		_pool_mats.append(mat)
		_pool_zones.append(zone)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	_spawn_timer += delta
	if _spawn_timer >= TRAIL_INTERVAL:
		_spawn_timer -= TRAIL_INTERVAL
		_spawn_trail_orb(parent_spell.global_position)

func _spawn_trail_orb(pos: Vector3) -> void:
	var mi:   MeshInstance3D    = _pool_mis[_pool_idx]
	var mat:  StandardMaterial3D = _pool_mats[_pool_idx]
	var zone: Area3D             = _pool_zones[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE

	# Reposition and reset
	mi.global_position  = pos
	mi.scale            = Vector3.ONE
	mi.visible          = true
	mat.albedo_color.a  = 0.75

	zone.global_position = pos
	zone.monitoring      = true

	# Fade out + shrink, then return slot to idle state
	var tween := mi.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mat, "albedo_color:a", 0.0,                TRAIL_LIFETIME)
	tween.tween_property(mi,  "scale",          Vector3.ONE * 0.05, TRAIL_LIFETIME)
	tween.set_parallel(false)
	tween.tween_callback(func():
		mi.visible      = false
		zone.monitoring = false
	)
