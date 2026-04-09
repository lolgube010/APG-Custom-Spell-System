extends Node

const TRAIL_SCRIPT = preload("res://Scripts/Spell_Stuff/trail_component.gd")

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

var fire_rate_timer: Timer
var _hold_repeat_timer: Timer
var _toggle_repeat_timer: Timer

var _is_charging: bool = false
var _charge_cancelled: bool = false

var active_toggle_effects: Dictionary = {}  # { SpellEffect value → Node }
var _active_hold_effects: Dictionary = {}   # { SpellEffect value → Node }

func _ready() -> void:
	wand = player_root.get_node("Head/CameraSmooth/Camera3D/WandMesh")

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
	_flat_spell_array = _flatten_spell_refs(spell_array)
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
		_spawn_spell_object(wand.get_spell_spawn_transform())

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
		_spawn_spell_object(rotated, charge_multiplier)

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
			var node := _make_effect_node(ev, component, -1.0)
			player_root.add_child(node)
			active_toggle_effects[ev] = node
			if _toggle_repeat_timer.is_stopped():
				_toggle_repeat_timer.start()
		else:
			player_root.add_child(_make_effect_node(ev, component, DEFAULT_EFFECT_DURATION * _get_duration_mult()))

func _apply_hold_effects() -> void:
	if not _active_hold_effects.is_empty():
		return
	for component in _flat_spell_array:
		if component["type"] != "effect":
			continue
		var ev: int = component["value"]
		if not SpellGlobals.EFFECT_SCRIPTS.has(ev):
			continue
		var node := _make_effect_node(ev, component, -1.0)
		player_root.add_child(node)
		_active_hold_effects[ev] = node
	if not _active_hold_effects.is_empty():
		_hold_repeat_timer.start()

func _apply_child_spell_effects(arr: Array, hit_transform: Transform3D = Transform3D.IDENTITY) -> void:
	for component in arr:
		if component["type"] != "effect":
			continue
		var ev := int(component["value"])
		if not SpellGlobals.EFFECT_SCRIPTS.has(ev):
			continue
		var node := _make_effect_node(ev, component, DEFAULT_EFFECT_DURATION)
		node.set("hit_position", hit_transform.origin)
		player_root.add_child(node)

## Re-fire any one-shot effects (e.g. ThrowLook) that freed themselves while still active.
func _respawn_dead_effects(effects: Dictionary) -> void:
	for ev in effects.keys():
		if is_instance_valid(effects[ev]):
			continue
		var comp := _find_effect_component(ev)
		if comp.is_empty():
			continue
		var node := _make_effect_node(ev, comp, -1.0)
		player_root.add_child(node)
		effects[ev] = node

func _on_hold_repeat_timeout() -> void:
	_respawn_dead_effects(_active_hold_effects)

func _on_toggle_repeat_timeout() -> void:
	_respawn_dead_effects(active_toggle_effects)

# ── Shape firing for Self cast types ─────────────────────────────────────────

## Returns the second casting entry's value — the shape's firing mode when a Self
## type is combined with a spell ref containing its own casting entry.
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
	if not _array_has_shape(_flat_spell_array):
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

# ── Spell object spawning ─────────────────────────────────────────────────────

func _spawn_spell_object(spawn_transform: Transform3D, charge_multiplier: float = 0.0, spell_array: Array = []) -> Node3D:
	var is_child_spell := not spell_array.is_empty()
	if spell_array.is_empty():
		spell_array = our_spell_array
	spell_array = _flatten_spell_refs(spell_array)

	var spell := SpellBase.new()
	spell.name = "ActiveSpell"

	if charge_multiplier > 0.0:
		spell.damage *= (1.0 + charge_multiplier)
		spell.speed  *= (1.0 + charge_multiplier * 0.5)

	_apply_modifiers(spell_array, spell)
	var has_shape := _attach_components(spell_array, spell)

	if not has_shape:
		spell.queue_free()
		return null

	if is_child_spell:
		_apply_child_spell_effects(spell_array, spawn_transform)

	if spell.has_trail:
		var trail := Node.new()
		trail.set_script(TRAIL_SCRIPT)
		spell.add_child(trail)

	get_tree().current_scene.add_child(spell)
	spell.global_transform = spawn_transform
	spell.scale = spell.scale_mult
	return spell

func _apply_modifiers(arr: Array, spell: SpellBase) -> void:
	for component in arr:
		var v := int(component["value"])
		match component["type"]:
			"mod_float":
				var amount: float = component.get("amount", 1.0)
				match v:
					SpellGlobals.SpellModifierFloat.MoveSpeed:  spell.speed      *= amount
					SpellGlobals.SpellModifierFloat.Duration:   spell.lifetime   *= amount
					SpellGlobals.SpellModifierFloat.CastForce:  spell.cast_force  = amount
			"mod_vec":
				var amt = component.get("amount", {"x": 1.0, "y": 1.0, "z": 1.0})
				match v:
					SpellGlobals.SpellModifierVec.Size:
						spell.scale_mult = Vector3(amt.get("x", 1.0), amt.get("y", 1.0), amt.get("z", 1.0))
			"mod_bool":
				var amount: bool = component.get("amount", false)
				match v:
					SpellGlobals.SpellModifierBool.Piercing:            spell.is_piercing = amount
					SpellGlobals.SpellModifierBool.Ricochet:            spell.does_ricochet = amount
					SpellGlobals.SpellModifierBool.EnvironmentPiercing: spell.is_environment_piercing = amount
					SpellGlobals.SpellModifierBool.Trail:               spell.has_trail = amount

func _attach_components(arr: Array, spell: SpellBase) -> bool:
	var has_shape := false
	for component in arr:
		var v := int(component["value"])
		match component["type"]:
			"shape":
				if SpellGlobals.SHAPE_SCENES.has(v):
					spell.add_child(SpellGlobals.SHAPE_SCENES[v].instantiate())
					has_shape = true
			"path":
				if SpellGlobals.PATH_SCRIPTS.has(v):
					var path_node := Node.new()
					path_node.set_script(SpellGlobals.PATH_SCRIPTS[v])
					spell.add_child(path_node)
			"element":
				spell.element = v
			"trigger":
				spell.trigger_type = v
				spell.child_spell_array = component.get("child_spell", [])
				spell.spawn_child = func(child_arr: Array, xform: Transform3D):
					_spawn_spell_object(xform, 0.0, child_arr)
				if v == SpellGlobals.SpellTrigger.OnTimer:
					spell.timer_trigger_interval = maxf(0.1, component.get("amount", 1.0))
	return has_shape

# ── Lookup helpers ────────────────────────────────────────────────────────────

func _make_effect_node(ev: int, component: Dictionary, dur: float) -> Node:
	var node := Node.new()
	node.set_script(SpellGlobals.EFFECT_SCRIPTS[ev])
	node.player_root = player_root
	node.duration = dur
	_apply_effect_amount(node, component)
	return node

func _apply_effect_amount(node: Node, component: Dictionary) -> void:
	var raw = component.get("amount", null)
	if raw == null:
		return
	if raw is Dictionary:
		node.set("amount_vec", Vector3(raw.get("x", 1.0), raw.get("y", 1.0), raw.get("z", 1.0)))
	else:
		node.set("amount", float(raw))

## Find the first flat-array entry with the given type string and integer value.
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

func _array_has_shape(arr: Array) -> bool:
	for c in arr:
		if c["type"] == "shape":
			return true
	return false

func _get_duration_mult() -> float:
	var c := _find_mod("mod_float", SpellGlobals.SpellModifierFloat.Duration)
	return maxf(0.1, c.get("amount", 1.0)) if not c.is_empty() else 1.0

func _get_cast_delay() -> float:
	var c := _find_mod("mod_float", SpellGlobals.SpellModifierFloat.Delay)
	return c.get("amount", DEFAULT_CAST_DELAY) if not c.is_empty() else 0.0

func _get_split_count() -> int:
	var c := _find_mod("mod_int", SpellGlobals.SpellModifierInt.Split)
	return maxi(1, c.get("amount", 1)) if not c.is_empty() else 1

func _flatten_spell_refs(arr: Array) -> Array:
	var result: Array = []
	for entry in arr:
		if entry["type"] == "spell_ref":
			var ref_array := SpellLibrary.get_spell(entry["name"])
			if not ref_array.is_empty():
				result.append_array(_flatten_spell_refs(ref_array))
		elif entry.has("child_spell"):
			var flat_entry: Dictionary = entry.duplicate()
			flat_entry["child_spell"] = _flatten_spell_refs(entry["child_spell"])
			result.append(flat_entry)
		else:
			result.append(entry)
	return result
