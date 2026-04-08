extends Node

@export var player_root: Node3D
var wand : Node
# State tracking
var our_spell_array : Array
var current_casting_type: int = -1 # We will cache this when equipped!

# Continuous variables
var fire_rate_timer: Timer

# Charge variables
var is_charging: bool = false
var charge_start_time: float = 0.0

# SelfInstant / SelfToggle
const DEFAULT_EFFECT_DURATION: float = 5.0
var active_toggle_effects: Dictionary = {}  # { SpellEffect value: Node }

# Delayed modifier
const DEFAULT_CAST_DELAY: float = 2.0

func _ready() -> void:
	wand = player_root.get_node("Head/CameraSmooth/Camera3D/WandMesh")
	#var trans = wand.get_spell_spawn_transform()
	fire_rate_timer = Timer.new()
	fire_rate_timer.wait_time = 0.2 # Shoots 5 times a second
	fire_rate_timer.timeout.connect(_on_fire_rate_timeout)
	add_child(fire_rate_timer)
	
	wand.spell_cast.connect(_on_spell_cast)
	wand.spell_stop.connect(_on_spell_stop)

func _on_spell_creation_spell_data_created(spell_array: Array) -> void:
	if spell_array.is_empty():
		print("spell_casting.gd empty spell array!")
		return
	print("spell_casting.gd cached spell creation data!!!")
	#for result in spell_array:
		#print(result)
	our_spell_array = spell_array
	
	for component in spell_array:
		if component["type"] == "casting":
			current_casting_type = component["value"]
			break

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
			is_charging = true
			charge_start_time = Time.get_ticks_msec()
			print("Charging spell...")

		SpellGlobals.SpellCasting.SelfInstant:
			_apply_self_effects(false)

		SpellGlobals.SpellCasting.SelfToggle:
			_apply_self_effects(true)

func _schedule_spell(spawn_transform: Transform3D, charge_multiplier: float = 0.0) -> void:
	var delay := _get_cast_delay()
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_spawn_spell_object(spawn_transform, charge_multiplier)

func _get_cast_delay() -> float:
	for i in our_spell_array.size():
		if our_spell_array[i]["type"] == "casting":
			var next := i + 1
			if next < our_spell_array.size():
				var entry = our_spell_array[next]
				if entry["type"] == "mod_float" and entry["value"] == SpellGlobals.SpellModifierFloat.Delay:
					return DEFAULT_CAST_DELAY
			break
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

func _on_spell_stop() -> void:
	fire_rate_timer.stop()

func _on_fire_rate_timeout() -> void:
	if wand:
		_schedule_spell(wand.get_spell_spawn_transform())

func _spawn_spell_object(spawn_transform: Transform3D, charge_multiplier: float = 0.0) -> Node3D:
	var new_spell = SpellBase.new()
	new_spell.name = "ActiveSpell"

	if charge_multiplier > 0.0:
		new_spell.damage *= (1.0 + charge_multiplier)
		new_spell.speed *= (1.0 + charge_multiplier * 0.5)
	
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
	
	return new_spell

# old ver below

	#if spell_array.is_empty():
		#return
		#
	## 1. Spawn a blank, invisible "container" for our spell
	#var new_spell = Node3D.new()
	#new_spell.name = "CustomSpell"
	#
	## Optional: Give it a baseline script with basic variables (damage, speed, lifetime)
	## new_spell.set_script(preload("res://Scripts/Spells/spell_base.gd"))
	#
	## 2. Iterate through the instructions and build it!
	#for component_data in spell_array:
		#var type = component_data["type"]   # e.g., "shape"
		#var value = component_data["value"] # e.g., 2 (which means BEAM)
		#
		## Route the data to modular handler functions
		#match type:
			#"casting":
				#_apply_casting(new_spell, value)
			#"shape":
				#_apply_shape(new_spell, value)
			#"element":
				#_apply_element(new_spell, value)
			#"trigger":
				#_apply_trigger(new_spell, value)
			#_:
				#print("Unrecognized spell component: ", type)
#
	## 3. Finally, add the fully constructed spell to the world at the player's location!
	#new_spell.global_position = player_root.global_position
	#get_tree().current_scene.add_child(new_spell)
#
#func _apply_casting(spell: Node3D, casting_id: int) -> void:
	#match casting_id:
		#pass
		##SpellGlobals.SpellElement.FIRE:
			### Set damage type, or spawn fire particles
			##var fire_vfx = preload("res://Assets/VFX/fire_particles.tscn").instantiate()
			##spell.add_child(fire_vfx)
			### spell.damage_type = "Fire"
#
#func _apply_shape(spell: Node3D, shape_id: int) -> void:
	#match shape_id:
		#SpellGlobals.SpellShape.Orb:
			#pass
			## Example: Attach an Orb behavior script/node to the spell
			##var orb_component = preload("res://Scripts/Spells/Components/shape_orb.tscn").instantiate()
			##spell.add_child(orb_component)
			#
		#SpellGlobals.SpellShape.Beam:
			#pass
			##var beam_component = preload("res://Scripts/Spells/Components/shape_beam.tscn").instantiate()
			##spell.add_child(beam_component)
			#
		#SpellGlobals.SpellShape.Explode:
			## Maybe this just tweaks a variable on the spell base
			#if spell.get("is_explosive") != null:
				#spell.is_explosive = true
#
#func _apply_element(spell: Node3D, element_id: int) -> void:
	#match element_id:
		#SpellGlobals.SpellElement.FIRE:
			#pass
			## Set damage type, or spawn fire particles
			##var fire_vfx = preload("res://Assets/VFX/fire_particles.tscn").instantiate()
			##spell.add_child(fire_vfx)
			## spell.damage_type = "Fire"
#
#func _apply_trigger(spell: Node3D, casting_id: int) -> void:
	#match casting_id:
		#pass
