class_name SpellFactory
extends Node

## Assembles and spawns SpellBase objects from a compiled spell array.
## Spell_Casting owns one instance of this and delegates all object creation here.

const TRAIL_SCRIPT = preload("res://Scripts/Spell/Modifiers/Trail_Component.gd")


const CONTINUOUS_INTERVAL: float = 0.5
const CONTINUOUS_DURATION: float = 3.0

var player_root: Node3D

## Flatten, build, and add a spell to the scene. Pass is_child=true when spawning
## a trigger child spell (skips top-level-only setup).
func spawn(spell_array: Array, spawn_transform: Transform3D, charge_multiplier: float = 0.0, is_child: bool = false, hit_body: Node3D = null) -> Node3D:
	spell_array = flatten_spell_refs(spell_array)

	# Child spells with a Continuous casting entry repeat the shape at the hit
	# point for CONTINUOUS_DURATION seconds instead of firing only once.
	if is_child:
		for c in spell_array:
			if c["type"] == "casting" and int(c["value"]) == SpellGlobals.SpellCasting.Continous:
				var shape_array := spell_array.filter(func(e): return e["type"] != "casting")
				_run_continuous_child(shape_array, spawn_transform, hit_body)
				return null

	var spell := SpellBase.new()
	spell.name = "ActiveSpell"

	if charge_multiplier > 0.0:
		spell.damage *= (1.0 + charge_multiplier)
		spell.speed  *= (1.0 + charge_multiplier * 0.5)

	_apply_modifiers(spell_array, spell)
	var has_shape := _attach_components(spell_array, spell)

	# Apply effects before the shape guard so effect-only child spells still
	# fire (e.g. OnHit → Poison with no shape in the child).
	if is_child:
		_apply_child_effects(spell_array, spawn_transform, hit_body)

	if not has_shape:
		spell.queue_free()
		return null

	if spell.has_trail:
		var trail := Node.new()
		trail.set_script(TRAIL_SCRIPT)
		spell.add_child(trail)

	get_tree().current_scene.add_child(spell)
	spell.global_transform = spawn_transform
	spell.scale = spell.scale_mult
	return spell

func make_effect_node(ev: int, component: Dictionary, dur: float) -> Node:
	var node := Node.new()
	node.set_script(SpellGlobals.EFFECT_SCRIPTS[ev])
	node.set("target", player_root)  # default; overridden for hit-targeted effects
	node.set("caster", player_root)  # always the player; never overridden
	node.duration = dur
	_apply_effect_amount(node, component)
	return node

static func flatten_spell_refs(arr: Array) -> Array:
	var result: Array = []
	for entry in arr:
		if entry["type"] == "spell_ref":
			var ref_array := SpellLibrary.get_spell(entry["name"])
			if not ref_array.is_empty():
				result.append_array(flatten_spell_refs(ref_array))
		elif entry.has("child_spell"):
			var flat_entry: Dictionary = entry.duplicate()
			flat_entry["child_spell"] = flatten_spell_refs(entry["child_spell"])
			result.append(flat_entry)
		else:
			result.append(entry)
	return result

static func array_has_shape(arr: Array) -> bool:
	for c in arr:
		if c["type"] == "shape":
			return true
	return false

# ── Private helpers ───────────────────────────────────────────────────────────

func _apply_modifiers(arr: Array, spell: SpellBase) -> void:
	for component in arr:
		var v := int(component["value"])
		match component["type"]:
			"mod_float":
				var amount: float = component.get("amount", 1.0)
				match v:
					SpellGlobals.SpellModifierFloat.MoveSpeed:  spell.speed     *= amount
					SpellGlobals.SpellModifierFloat.Duration:   spell.lifetime  *= amount
					SpellGlobals.SpellModifierFloat.CastForce:  spell.cast_force = amount
			"mod_vec":
				var amt = component.get("amount", {"x": 1.0, "y": 1.0, "z": 1.0})
				match v:
					SpellGlobals.SpellModifierVec.Size:
						spell.scale_mult = Vector3(amt.get("x", 1.0), amt.get("y", 1.0), amt.get("z", 1.0))
			"mod_bool":
				var amount: bool = component.get("amount", false)
				match v:
					SpellGlobals.SpellModifierBool.Piercing:            spell.is_piercing             = amount
					SpellGlobals.SpellModifierBool.Ricochet:            spell.does_ricochet            = amount
					SpellGlobals.SpellModifierBool.EnvironmentPiercing: spell.is_environment_piercing  = amount
					SpellGlobals.SpellModifierBool.Trail:               spell.has_trail                = amount

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
				spell.spawn_child = func(child_arr: Array, xform: Transform3D, hit_body: Node3D = null):
					spawn(child_arr, xform, 0.0, true, hit_body)
				if v == SpellGlobals.SpellTrigger.OnTimer:
					spell.timer_trigger_interval = maxf(0.1, component.get("amount", 1.0))
	return has_shape

func _apply_child_effects(arr: Array, hit_transform: Transform3D, hit_body: Node3D = null) -> void:
	for component in arr:
		if component["type"] != "effect":
			continue
		var ev := int(component["value"])
		if not SpellGlobals.EFFECT_SCRIPTS.has(ev):
			continue
		var node := make_effect_node(ev, component, SpellGlobals.DEFAULT_EFFECT_DURATION)
		node.set("hit_position", hit_transform.origin)
		# Effects with target_self=true (e.g. TeleportToHit, ThrowLook) always
		# affect the caster. All others target the body that was hit.
		var is_self : bool = node.get("target_self") == true
		var effect_target: Node3D = player_root if (is_self or not is_instance_valid(hit_body)) else hit_body
		node.set("target", effect_target)
		effect_target.add_child(node)

func _apply_effect_amount(node: Node, component: Dictionary) -> void:
	var raw = component.get("amount", null)
	if raw == null:
		return
	if raw is Dictionary:
		node.set("amount_vec", Vector3(raw.get("x", 1.0), raw.get("y", 1.0), raw.get("z", 1.0)))
	else:
		node.set("amount", float(raw))

## Spawn `shape_array` once immediately, then repeat every CONTINUOUS_INTERVAL
## for CONTINUOUS_DURATION seconds. Called for child spells with Continuous casting.
func _run_continuous_child(shape_array: Array, spawn_transform: Transform3D, hit_body: Node3D = null) -> void:
	spawn(shape_array, spawn_transform, 0.0, true, hit_body)
	var elapsed := CONTINUOUS_INTERVAL
	while elapsed < CONTINUOUS_DURATION:
		await get_tree().create_timer(CONTINUOUS_INTERVAL).timeout
		if not is_instance_valid(self):
			return
		spawn(shape_array, spawn_transform, 0.0, true, hit_body)
		elapsed += CONTINUOUS_INTERVAL
