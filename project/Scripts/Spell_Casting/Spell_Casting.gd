extends Node

@export var player_root: Node3D
var wand : Node
# State tracking
var our_spell_array : Array
var current_casting_type: int = -1 # We will cache this when equipped!

# Continuous variables
const BASE_FIRE_RATE: float = 0.2  # seconds between shots at cast_speed 1.0
var fire_rate_timer: Timer
var current_cast_speed: float = 1.0

# ChargeUp variables
const DEFAULT_CHARGE_DURATION: float = 1.5
var _is_charging: bool = false
var _charge_cancelled: bool = false

# SelfInstant / SelfToggle / SelfHold
const DEFAULT_EFFECT_DURATION: float = 5.0
var active_toggle_effects: Dictionary = {}  # { SpellEffect value: Node }
var _active_hold_effects: Dictionary = {}   # { SpellEffect value: Node }

# SelfHold / SelfToggle repeat — re-fires one-shot effects (e.g. throws) while active
const HOLD_REPEAT_INTERVAL: float = 0.5
var _hold_repeat_timer: Timer
var _toggle_repeat_timer: Timer

# Delayed modifier
const DEFAULT_CAST_DELAY: float = 2.0

# Split modifier
const SPLIT_ANGLE_STEP_DEG: float = 20.0  # degrees between adjacent split projectiles
const SPLIT_POS_OFFSET: float = 0.8       # metres of lateral separation between splits at spawn

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
	if spell_array.is_empty():
		print("spell_casting.gd empty spell array!")
		return
	print("spell_casting.gd cached spell creation data!!!")
	our_spell_array = spell_array

	# Flatten spell_refs so casting type / cast speed nested inside them are visible.
	# Also reset casting type so a stale value from a previous spell can't carry over.
	var flat := _flatten_spell_refs(spell_array)
	current_casting_type = -1
	current_cast_speed = 1.0
	for component in flat:
		if component["type"] == "casting":
			current_casting_type = int(component["value"])
		elif component["type"] == "mod_float" and int(component["value"]) == SpellGlobals.SpellModifierFloat.CastSpeed:
			current_cast_speed = maxf(0.1, component.get("amount", 1.0))

	wand.cast_speed = current_cast_speed
	fire_rate_timer.wait_time = BASE_FIRE_RATE / current_cast_speed

func _on_spell_cast():
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

		SpellGlobals.SpellCasting.SelfToggle:
			_apply_self_effects(true)

		SpellGlobals.SpellCasting.SelfHold:
			_apply_hold_effects()

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
	var right := spawn_transform.basis.x  # camera-right, works for any aim direction
	for i in range(split_count):
		# Centre both the angular fan and the lateral offset around shot 0.
		var t := i - (split_count - 1) / 2.0
		var angle := deg_to_rad(SPLIT_ANGLE_STEP_DEG * t)
		var rotated := Transform3D(
			Basis(Vector3.UP, angle) * spawn_transform.basis,
			spawn_transform.origin + right * SPLIT_POS_OFFSET * t
		)
		_spawn_spell_object(rotated, charge_multiplier)

func _get_split_count() -> int:
	for component in _flatten_spell_refs(our_spell_array):
		if component["type"] == "mod_int" and int(component["value"]) == SpellGlobals.SpellModifierInt.Split:
			return maxi(1, component.get("amount", 1))
	return 1

func _apply_effect_amount(node: Node, component: Dictionary) -> void:
	var raw = component.get("amount", null)
	if raw == null:
		return
	if raw is Dictionary:
		node.set("amount_vec", Vector3(raw.get("x", 1.0), raw.get("y", 1.0), raw.get("z", 1.0)))
	else:
		node.set("amount", float(raw))

func _get_duration_mult() -> float:
	for component in _flatten_spell_refs(our_spell_array):
		if component["type"] == "mod_float" and int(component["value"]) == SpellGlobals.SpellModifierFloat.Duration:
			return maxf(0.1, component.get("amount", 1.0))
	return 1.0

func _get_cast_delay() -> float:
	for component in _flatten_spell_refs(our_spell_array):
		if component["type"] == "mod_float" and int(component["value"]) == SpellGlobals.SpellModifierFloat.Delay:
			return component.get("amount", DEFAULT_CAST_DELAY)
	return 0.0

func _apply_self_effects(is_toggle: bool) -> void:
	for component in our_spell_array:
		if component["type"] != "effect":
			continue
		var effect_value: int = component["value"]
		if not SpellGlobals.EFFECT_SCRIPTS.has(effect_value):
			continue
		if is_toggle:
			if active_toggle_effects.has(effect_value):
				# toggle OFF — has(effect_value) is the source of truth, not node validity
				var existing = active_toggle_effects[effect_value]
				active_toggle_effects.erase(effect_value)
				if is_instance_valid(existing):
					existing.remove_effect()
					existing.queue_free()
				if active_toggle_effects.is_empty():
					_toggle_repeat_timer.stop()
				continue
			# toggle ON — fire immediately and start repeat timer
			var node := Node.new()
			node.set_script(SpellGlobals.EFFECT_SCRIPTS[effect_value])
			node.player_root = player_root
			node.duration = -1.0
			_apply_effect_amount(node, component)
			player_root.add_child(node)
			active_toggle_effects[effect_value] = node
			if _toggle_repeat_timer.is_stopped():
				_toggle_repeat_timer.start()
		else:
			var node := Node.new()
			node.set_script(SpellGlobals.EFFECT_SCRIPTS[effect_value])
			node.player_root = player_root
			node.duration = DEFAULT_EFFECT_DURATION * _get_duration_mult()
			_apply_effect_amount(node, component)
			player_root.add_child(node)

func _apply_hold_effects() -> void:
	if not _active_hold_effects.is_empty():
		return  # already holding — avoid re-entry from looping animation
	for component in our_spell_array:
		if component["type"] != "effect":
			continue
		var effect_value: int = component["value"]
		if not SpellGlobals.EFFECT_SCRIPTS.has(effect_value):
			continue
		var node := Node.new()
		node.set_script(SpellGlobals.EFFECT_SCRIPTS[effect_value])
		node.player_root = player_root
		node.duration = -1.0
		_apply_effect_amount(node, component)
		player_root.add_child(node)
		_active_hold_effects[effect_value] = node
	if not _active_hold_effects.is_empty():
		_hold_repeat_timer.start()

func _on_hold_repeat_timeout() -> void:
	for effect_value in _active_hold_effects.keys():
		if not is_instance_valid(_active_hold_effects[effect_value]):
			# one-shot effect (e.g. throw) freed itself — re-fire it
			var component := _find_effect_component(effect_value)
			if component.is_empty():
				continue
			var node := Node.new()
			node.set_script(SpellGlobals.EFFECT_SCRIPTS[effect_value])
			node.player_root = player_root
			node.duration = -1.0
			_apply_effect_amount(node, component)
			player_root.add_child(node)
			_active_hold_effects[effect_value] = node

func _on_toggle_repeat_timeout() -> void:
	for effect_value in active_toggle_effects.keys():
		if not is_instance_valid(active_toggle_effects[effect_value]):
			var component := _find_effect_component(effect_value)
			if component.is_empty():
				continue
			var node := Node.new()
			node.set_script(SpellGlobals.EFFECT_SCRIPTS[effect_value])
			node.player_root = player_root
			node.duration = -1.0
			_apply_effect_amount(node, component)
			player_root.add_child(node)
			active_toggle_effects[effect_value] = node

func _find_effect_component(effect_value: int) -> Dictionary:
	for component in our_spell_array:
		if component["type"] == "effect" and component["value"] == effect_value:
			return component
	return {}

func _on_spell_stop() -> void:
	_charge_cancelled = true
	_is_charging = false
	fire_rate_timer.stop()
	_hold_repeat_timer.stop()
	for effect_value in _active_hold_effects:
		if is_instance_valid(_active_hold_effects[effect_value]):
			_active_hold_effects[effect_value].remove_effect()
			_active_hold_effects[effect_value].queue_free()
	_active_hold_effects.clear()

func _on_fire_rate_timeout() -> void:
	if wand:
		_schedule_spell(wand.get_spell_spawn_transform())

func _flatten_spell_refs(arr: Array) -> Array:
	var result: Array = []
	for entry in arr:
		if entry["type"] == "spell_ref":
			var ref_array := SpellLibrary.get_spell(entry["name"])
			if not ref_array.is_empty():
				result.append_array(ref_array)
		else:
			result.append(entry)
	return result

func _spawn_spell_object(spawn_transform: Transform3D, charge_multiplier: float = 0.0, spell_array: Array = []) -> Node3D:
	if spell_array.is_empty():
		spell_array = our_spell_array

	# Expand any spell_ref entries so both passes see a flat component list
	spell_array = _flatten_spell_refs(spell_array)

	var new_spell = SpellBase.new()
	new_spell.name = "ActiveSpell"

	if charge_multiplier > 0.0:
		new_spell.damage *= (1.0 + charge_multiplier)
		new_spell.speed  *= (1.0 + charge_multiplier * 0.5)

	# First pass: apply modifier nodes to SpellBase stats
	for component in spell_array:
		match component["type"]:
			"mod_float":
				var amount: float = component.get("amount", 1.0)
				match component["value"]:
					SpellGlobals.SpellModifierFloat.MoveSpeed:
						new_spell.speed *= amount
					SpellGlobals.SpellModifierFloat.Duration:
						new_spell.lifetime *= amount
					SpellGlobals.SpellModifierFloat.CastForce:
						pass # reserved
			"mod_int":
				var amount: int = component.get("amount", 1)
				match component["value"]:
					SpellGlobals.SpellModifierInt.Split:
						new_spell.split_count = amount
			"mod_vec":
				var amt = component.get("amount", {"x": 1.0, "y": 1.0, "z": 1.0})
				match component["value"]:
					SpellGlobals.SpellModifierVec.Size:
						new_spell.scale_mult = Vector3(amt.get("x", 1.0), amt.get("y", 1.0), amt.get("z", 1.0))
			"mod_bool":
				var amount: bool = component.get("amount", false)
				match component["value"]:
					SpellGlobals.SpellModifierBool.Piercing:
						new_spell.is_piercing = amount
					SpellGlobals.SpellModifierBool.Ricochet:
						new_spell.does_ricochet = amount
					SpellGlobals.SpellModifierBool.EnvironmentPiercing:
						new_spell.is_environment_piercing = amount
					SpellGlobals.SpellModifierBool.Trail:
						new_spell.has_trail = amount

	# Second pass: attach shape, path, element, trigger, and spell_ref components
	# Values from JSON are floats (0.0 instead of 0); cast to int so dict lookups
	# using enum keys work correctly (Godot 4 hashes int and float differently).
	var has_shape := false
	for component in spell_array:
		match component["type"]:
			"shape":
				var sv := int(component["value"])
				if SpellGlobals.SHAPE_SCENES.has(sv):
					new_spell.add_child(SpellGlobals.SHAPE_SCENES[sv].instantiate())
					has_shape = true
			"path":
				var pv := int(component["value"])
				if SpellGlobals.PATH_SCRIPTS.has(pv):
					var path_node = Node.new()
					path_node.set_script(SpellGlobals.PATH_SCRIPTS[pv])
					new_spell.add_child(path_node)
			"element":
				new_spell.element = int(component["value"])
			"trigger":
				new_spell.trigger_type = int(component["value"])
				new_spell.child_spell_array = component.get("child_spell", [])
				new_spell.spawn_child = func(child_arr: Array, xform: Transform3D):
					_spawn_spell_object(xform, 0.0, child_arr)
				if int(component["value"]) == SpellGlobals.SpellTrigger.OnTimer:
					new_spell.timer_trigger_interval = maxf(0.1, component.get("amount", 1.0))

	# Don't add an invisible ghost container if no shape was attached
	if not has_shape:
		new_spell.queue_free()
		return null

	if new_spell.has_trail:
		var trail := Node.new()
		trail.set_script(load("res://Scripts/Spell_Stuff/trail_component.gd"))
		new_spell.add_child(trail)

	get_tree().current_scene.add_child(new_spell)
	new_spell.global_transform = spawn_transform
	new_spell.scale = new_spell.scale_mult

	return new_spell
