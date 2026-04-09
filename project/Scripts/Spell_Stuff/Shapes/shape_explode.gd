extends ShapeBase

## Explosion that visibly grows from zero to full size, then detonates —
## dealing damage to everything inside at the moment it reaches full size.

const GROW_DURATION: float = 0.6

var _elapsed: float = 0.0
var _detonated: bool = false

func _ready() -> void:
	super()
	# Disconnect the inherited body_entered — we poll via get_overlapping_bodies on detonate
	body_entered.disconnect(_on_body_entered)
	scale = Vector3.ONE * 0.001  # Vector3.ZERO → det==0 which crashes Basis invert

func _physics_process(delta: float) -> void:
	if _detonated:
		return
	_elapsed += delta
	var t := minf(_elapsed / GROW_DURATION, 1.0)
	scale = Vector3.ONE * t
	if t >= 1.0:
		_detonated = true
		_detonate()

func _detonate() -> void:
	if not is_instance_valid(parent_spell):
		return
	for body in get_overlapping_bodies():
		if body is StaticBody3D:
			continue
		if body.has_method("take_damage"):
			body.take_damage(parent_spell.damage)
		parent_spell.fire_trigger(SpellGlobals.SpellTrigger.OnHit, global_transform)
	parent_spell.end_spell(global_transform)
