extends Node

@export var player_root: Node3D
var wand: Node

var our_spell_array: Array   # raw compiled array (may contain spell_ref entries)
var _flat_spell_array: Array # pre-flattened; always kept in sync
var current_casting_type: int = -1
var current_cast_speed: float = 1.0

const BASE_FIRE_RATE: float = 0.2
const DEFAULT_CHARGE_DURATION: float = 1.5
const DEFAULT_EFFECT_DURATION: float = 5.0
const DEFAULT_CAST_DELAY: float = 2.0
const SPLIT_ANGLE_STEP_DEG: float = 20.0
const SPLIT_POS_OFFSET: float = 0.8
const HOLD_REPEAT_INTERVAL: float = 0.5

var _factory: SpellFactory

var fire_rate_timer: Timer
var _hold_repeat_timer: Timer
var _toggle_repeat_timer: Timer

var _is_charging: bool = false
var _charge_cancelled: bool = false

var active_toggle_effects: Dictionary = {}  # { SpellEffect value → Node }
var _active_hold_effects: Dictionary = {}   # { SpellEffect value → Node }

func _ready() -> void:
	wand = player_root.get_node("Head/CameraSmooth/Camera3D/WandMesh")

	_factory = SpellFactory.new()
	_factory.player_root = player_root
	add_child(_factory)

	fire_rate_timer = Timer.new()
	fire_rate_timer.wait_time = BASE_FIRE_RATE
	fire_rate_timer.timeout.connect(_on_fire_rate_timeout)
	add_child(fire_rate_timer)

	_hold_repeat_timer = Timer.new()
	_hold_repeat_timer.wait_time = HOLD_REPEAT_INTERVAL
	_hold_repeat_timer.timeout.connect(_on_hold_repeat_timeout)
	add_child(_hold_repeat_timer)

	_toggle_repeat_timer = Timer.new()
	_toggle_repeat_timer.wait_time = HOLD_REPEAT_INTERVAL
	_toggle_repeat_timer.timeout.connect(_on_toggle_repeat_timeout)
	add_child(_toggle_repeat_timer)

	wand.spell_cast.connect(_on_spell_cast)
	wand.spell_stop.connect(_on_spell_stop)

func _on_spell_creation_spell_data_created(spell_array: Array) -> void:
	our_spell_array = spell_array
	_flat_spell_array = SpellFactory.flatten_spell_refs(spell_array)
	current_casting_type = -1
	current_cast_speed = 1.0
	for component in _flat_spell_array:
		if component["type"] == "casting" and current_casting_type == -1:
			current_casting_type = int(component["value"])
	var cs := _find_mod("mod_float", SpellGlobals.SpellModifierFloat.CastSpeed)
	if not cs.is_empty():
		current_cast_speed = maxf(0.1, cs.get("amount", 1.0))
	wand.cast_speed = current_cast_speed
	fire_rate_timer.wait_time = BASE_FIRE_RATE / current_cast_speed

func _on_spell_cast() -> void:
	if our_spell_array.is_empty():
		return
	match current_casting_type:
		SpellGlobals.SpellCasting.Burst:
			_schedule_spell(wand.get_spell_spawn_transform())
		SpellGlobals.SpellCasting.Continous:
			if not fire_rate_timer.is_stopped():
				return
			_schedule_spell(wand.get_spell_spawn_transform())
			fire_rate_timer.start()
		SpellGlobals.SpellCasting.ChargeUp:
			if not _is_charging:
				_begin_charge()
		SpellGlobals.SpellCasting.SelfInstant:
			_apply_self_effects(false)
			_fire_shape_for_self_cast()
		SpellGlobals.SpellCasting.SelfToggle:
			_apply_self_effects(true)
			_fire_shape_for_self_cast()
		SpellGlobals.SpellCasting.SelfHold:
			var first_hold := _active_hold_effects.is_empty()
			_apply_hold_effects()
			if first_hold:
				_fire_shape_for_self_cast()

func _begin_charge() -> void:
	_is_charging = true
	_charge_cancelled = false
	await get_tree().create_timer(DEFAULT_CHARGE_DURATION).timeout
	_is_charging = false
	if not _charge_cancelled:
		_factory.spawn(our_spell_array, wand.get_spell_spawn_transform())

func _schedule_spell(spawn_transform: Transform3D, charge_multiplier: float = 0.0) -> void:
	var delay := _get_cast_delay()
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	var split_count := _get_split_count()
	var right := spawn_transform.basis.x
	for i in range(split_count):
		var t := i - (split_count - 1) / 2.0
		var rotated := Transform3D(
			Basis(Vector3.UP, deg_to_rad(SPLIT_ANGLE_STEP_DEG * t)) * spawn_transform.basis,
			spawn_transform.origin + right * SPLIT_POS_OFFSET * t
		)
		_factory.spawn(our_spell_array, rotated, charge_multiplier)

func _on_fire_rate_timeout() -> void:
	if wand:
		_schedule_spell(wand.get_spell_spawn_transform())

func _on_spell_stop() -> void:
	_charge_cancelled = true
	_is_charging = false
	fire_rate_timer.stop()
	_hold_repeat_timer.stop()
	for node in _active_hold_effects.values():
		if is_instance_valid(node):
			node.remove_effect()
			node.queue_free()
	_active_hold_effects.clear()

func is_hold_casting() -> bool:
	return not _active_hold_effects.is_empty()

# ── Self-cast effects ─────────────────────────────────────────────────────────

func _apply_self_effects(is_toggle: bool) -> void:
	for component in _flat_spell_array:
		if component["type"] != "effect":
			continue
		var ev: int = component["value"]
		if not SpellGlobals.EFFECT_SCRIPTS.has(ev):
			continue
		if is_toggle:
			if active_toggle_effects.has(ev):
				var existing = active_toggle_effects[ev]
				active_toggle_effects.erase(ev)
				if is_instance_valid(existing):
					existing.remove_effect()
					existing.queue_free()
				if active_toggle_effects.is_empty():
					_toggle_repeat_timer.stop()
				continue
			var node := _factory.make_effect_node(ev, component, -1.0)
			player_root.add_child(node)
			active_toggle_effects[ev] = node
			if _toggle_repeat_timer.is_stopped():
				_toggle_repeat_timer.start()
		else:
			player_root.add_child(_factory.make_effect_node(ev, component, DEFAULT_EFFECT_DURATION * _get_duration_mult()))

func _apply_hold_effects() -> void:
	if not _active_hold_effects.is_empty():
		return
	for component in _flat_spell_array:
		if component["type"] != "effect":
			continue
		var ev: int = component["value"]
		if not SpellGlobals.EFFECT_SCRIPTS.has(ev):
			continue
		var node := _factory.make_effect_node(ev, component, -1.0)
		player_root.add_child(node)
		_active_hold_effects[ev] = node
	if not _active_hold_effects.is_empty():
		_hold_repeat_timer.start()

## Re-fire any one-shot effects (e.g. ThrowLook) that freed themselves while still active.
func _respawn_dead_effects(effects: Dictionary) -> void:
	for ev in effects.keys():
		if is_instance_valid(effects[ev]):
			continue
		var comp := _find_effect_component(ev)
		if comp.is_empty():
			continue
		var node := _factory.make_effect_node(ev, comp, -1.0)
		player_root.add_child(node)
		effects[ev] = node

func _on_hold_repeat_timeout() -> void:
	_respawn_dead_effects(_active_hold_effects)

func _on_toggle_repeat_timeout() -> void:
	_respawn_dead_effects(active_toggle_effects)

# ── Shape firing for Self cast types ─────────────────────────────────────────

func _get_shape_firing_type() -> int:
	var skipped_first := false
	for c in _flat_spell_array:
		if c["type"] != "casting":
			continue
		if not skipped_first:
			skipped_first = true
			continue
		return int(c["value"])
	return SpellGlobals.SpellCasting.Burst

func _fire_shape_for_self_cast() -> void:
	if not SpellFactory.array_has_shape(_flat_spell_array):
		return
	match _get_shape_firing_type():
		SpellGlobals.SpellCasting.Continous:
			if fire_rate_timer.is_stopped():
				_schedule_spell(wand.get_spell_spawn_transform())
				fire_rate_timer.start()
		SpellGlobals.SpellCasting.ChargeUp:
			if not _is_charging:
				_begin_charge()
		_:
			_schedule_spell(wand.get_spell_spawn_transform())

# ── Lookup helpers ────────────────────────────────────────────────────────────

func _find_mod(type_str: String, value: int) -> Dictionary:
	for c in _flat_spell_array:
		if c["type"] == type_str and int(c["value"]) == value:
			return c
	return {}

func _find_effect_component(effect_value: int) -> Dictionary:
	for c in _flat_spell_array:
		if c["type"] == "effect" and int(c["value"]) == effect_value:
			return c
	return {}

func _get_duration_mult() -> float:
	var c := _find_mod("mod_float", SpellGlobals.SpellModifierFloat.Duration)
	return maxf(0.1, c.get("amount", 1.0)) if not c.is_empty() else 1.0

func _get_cast_delay() -> float:
	var c := _find_mod("mod_float", SpellGlobals.SpellModifierFloat.Delay)
	return c.get("amount", DEFAULT_CAST_DELAY) if not c.is_empty() else 0.0

func _get_split_count() -> int:
	var c := _find_mod("mod_int", SpellGlobals.SpellModifierInt.Split)
	return maxi(1, c.get("amount", 1)) if not c.is_empty() else 1
