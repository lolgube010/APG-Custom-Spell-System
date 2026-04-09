extends Node3D
class_name SpellBase

# We store basic stats here so modifiers (like Speed * 2) can easily find and change them
var element: int = -1 # -1 means none
var current_path: int = -1
var damage: float = 10.0
var speed: float = 10.0
var scale_mult: Vector3 = Vector3.ONE
var split_count: int = 0
var is_piercing: bool = false
var does_ricochet: bool = false
var is_environment_piercing: bool = false
var has_trail: bool = false

var lifetime: float = 5.0
var _ended: bool = false

# Trigger / child spell
var trigger_type: int = -1          # SpellTrigger enum value, -1 = no trigger
var timer_trigger_interval: float = 0.0  # used when trigger_type == OnTimer
var child_spell_array: Array = []   # compiled sub-array to spawn when trigger fires
var spawn_child: Callable           # set by Spell_Casting: call(child_array, transform)

# Arrays to hold effects that haven't been applied to a shape yet
var pending_effects: Array[int] = []

func _ready() -> void:
	if trigger_type == SpellGlobals.SpellTrigger.OnTimer and timer_trigger_interval > 0.0:
		_run_timer_trigger()
	await get_tree().create_timer(lifetime).timeout
	end_spell(global_transform)

## Call this instead of queue_free() everywhere — fires OnEnd then destroys the spell.
## The _ended guard ensures it can only run once even if called from multiple paths.
func end_spell(xform: Transform3D) -> void:
	if _ended:
		return
	_ended = true
	fire_trigger(SpellGlobals.SpellTrigger.OnEnd, xform)
	queue_free()

func _run_timer_trigger() -> void:
	while is_instance_valid(self):
		await get_tree().create_timer(timer_trigger_interval).timeout
		if not is_instance_valid(self):
			return
		fire_trigger(SpellGlobals.SpellTrigger.OnTimer, global_transform)

func fire_trigger(type: int, xform: Transform3D) -> void:
	if type != trigger_type or child_spell_array.is_empty() or not spawn_child.is_valid():
		return
	spawn_child.call(child_spell_array, xform)
