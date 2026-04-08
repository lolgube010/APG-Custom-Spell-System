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

# Delayed modifier
const DEFAULT_CAST_DELAY: float = 2.0

func _ready() -> void:
	wand = player_root.get_node("Head/CameraSmooth/Camera3D/WandMesh")
	fire_rate_timer = Timer.new()
	fire_rate_timer.wait_time = BASE_FIRE_RATE
	fire_rate_timer.timeout.connect(_on_fire_rate_timeout)
	add_child(fire_rate_timer)

	wand.spell_cast.connect(_on_spell_cast)
	wand.spell_stop.connect(_on_spell_stop)

func _on_spell_creation_spell_data_created(spell_array: Array) -> void:
	if spell_array.is_empty():
		print("spell_casting.gd empty spell array!")
		return
	print("spell_casting.gd cached spell creation data!!!")
	our_spell_array = spell_array

	current_cast_speed = 1.0
	for component in spell_array:
		if component["type"] == "casting":
			current_casting_type = component["value"]
		elif component["type"] == "mod_float" and component["value"] == SpellGlobals.SpellModifierFloat.CastSpeed:
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
	_spawn_spell_object(spawn_transform, charge_multiplier)

func _get_cast_delay() -> float:
	for component in our_spell_array:
		if component["type"] == "mod_float" and component["value"] == SpellGlobals.SpellModifierFloat.Delay:
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
			if active_toggle_effects.has(effect_value) and is_instance_valid(active_toggle_effects[effect_value]):
				active_toggle_effects[effect_value].remove_effect()
				active_toggle_effects[effect_value].queue_free()
				active_toggle_effects.erase(effect_value)
			else:
				var node := Node.new()
				node.set_script(SpellGlobals.EFFECT_SCRIPTS[effect_value])
				node.player_root = player_root
				node.duration = -1.0
				player_root.add_child(node)
				active_toggle_effects[effect_value] = node
		else:
			var node := Node.new()
			node.set_script(SpellGlobals.EFFECT_SCRIPTS[effect_value])
			node.player_root = player_root
			node.duration = DEFAULT_EFFECT_DURATION
			player_root.add_child(node)

func _apply_hold_effects() -> void:
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
		player_root.add_child(node)
		_active_hold_effects[effect_value] = node

func _on_spell_stop() -> void:
	_charge_cancelled = true
	_is_charging = false
	fire_rate_timer.stop()
	for effect_value in _active_hold_effects:
		if is_instance_valid(_active_hold_effects[effect_value]):
			_active_hold_effects[effect_value].remove_effect()
			_active_hold_effects[effect_value].queue_free()
	_active_hold_effects.clear()

func _on_fire_rate_timeout() -> void:
	if wand:
		_schedule_spell(wand.get_spell_spawn_transform())

func _spawn_spell_object(spawn_transform: Transform3D, charge_multiplier: float = 0.0) -> Node3D:
	var new_spell = SpellBase.new()
	new_spell.name = "ActiveSpell"

	if charge_multiplier > 0.0:
		new_spell.damage *= (1.0 + charge_multiplier)
		new_spell.speed  *= (1.0 + charge_multiplier * 0.5)

	# First pass: apply modifier nodes to SpellBase stats
	for component in our_spell_array:
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

	# Second pass: attach shape, path, and element components
	for component in our_spell_array:
		match component["type"]:
			"shape":
				if SpellGlobals.SHAPE_SCENES.has(component["value"]):
					new_spell.add_child(SpellGlobals.SHAPE_SCENES[component["value"]].instantiate())
			"path":
				if SpellGlobals.PATH_SCRIPTS.has(component["value"]):
					var path_node = Node.new()
					path_node.set_script(SpellGlobals.PATH_SCRIPTS[component["value"]])
					new_spell.add_child(path_node)
			"element":
				new_spell.element = component["value"]

	get_tree().current_scene.add_child(new_spell)
	new_spell.global_transform = spawn_transform
	new_spell.scale = new_spell.scale_mult

	return new_spell
