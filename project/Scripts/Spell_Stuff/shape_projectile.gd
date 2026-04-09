extends Area3D

# Self-contained projectile: moves forward and falls under gravity.
# Does not require a Path node — movement is handled internally.
var parent_spell: SpellBase
var _velocity: Vector3 = Vector3.ZERO
var _initialized: bool = false
const GRAVITY: float = 12.0

func _ready() -> void:
	parent_spell = get_parent() as SpellBase
	body_entered.connect(_on_body_entered)
	_apply_element_color()

func _apply_element_color() -> void:
	if not SpellGlobals.ELEMENT_COLORS.has(parent_spell.element):
		return
	var mesh_instance := $MeshInstance3D as MeshInstance3D
	var mat = mesh_instance.get_active_material(0)
	if not mat:
		return
	var material := mat.duplicate() as StandardMaterial3D
	material.albedo_color = SpellGlobals.ELEMENT_COLORS[parent_spell.element]
	mesh_instance.material_override = material

func _physics_process(delta: float) -> void:
	if not is_instance_valid(parent_spell):
		return
	# Lazy init so we read global_transform after Spell_Casting has set it
	if not _initialized:
		_velocity = -parent_spell.global_transform.basis.z * parent_spell.speed
		_initialized = true
	_velocity.y -= GRAVITY * delta
	parent_spell.global_position += _velocity * delta

func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D:
		if parent_spell.does_ricochet:
			_do_ricochet()
			return
		if parent_spell.is_environment_piercing:
			return
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
		parent_spell.queue_free()
		return
	parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	if not parent_spell.is_piercing:
		parent_spell.queue_free()

var _bounce_cooldown: bool = false
func _do_ricochet() -> void:
	if _bounce_cooldown:
		return
	_bounce_cooldown = true
	get_tree().create_timer(0.1).timeout.connect(func(): _bounce_cooldown = false)
	var space := get_world_3d().direct_space_state
	var forward := _velocity.normalized()
	var query := PhysicsRayQueryParameters3D.create(
		parent_spell.global_position - forward * 0.3,
		parent_spell.global_position + forward * 0.3
	)
	var result := space.intersect_ray(query)
	if result:
		_velocity = _velocity.reflect(result.normal)
		parent_spell.global_position = result.position + result.normal * 0.15
	else:
		_velocity.y = abs(_velocity.y)  # bounce upward if no normal found
