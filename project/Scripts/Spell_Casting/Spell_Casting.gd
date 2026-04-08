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

func _ready() -> void:
	wand = player_root.get_node("Head/CameraSmooth/Camera3D/WandMesh")
	#var trans = wand.get_spell_spawn_transform()
	fire_rate_timer = Timer.new()
	fire_rate_timer.wait_time = 0.2 # Shoots 5 times a second
	fire_rate_timer.timeout.connect(_on_fire_rate_timeout)
	add_child(fire_rate_timer)
	
	wand.spell_cast.connect(_on_spell_cast)

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
		
	var spellTransform = wand.get_spell_spawn_transform()
		
	match current_casting_type:
		SpellGlobals.SpellCasting.Burst:
			_spawn_spell_object(spellTransform)
			
		SpellGlobals.SpellCasting.Continous:
			_spawn_spell_object(spellTransform)
			fire_rate_timer.start()
			
		SpellGlobals.SpellCasting.ChargeUp:
			is_charging = true
			charge_start_time = Time.get_ticks_msec()
			print("Charging spell...")
			# (Optional) You could spawn a visual-only particle effect on the wand tip here
			
		SpellGlobals.SpellCasting.SelfInstant:
			# Override the wand transform with the player's center/feet
			_spawn_spell_object(player_root.global_transform)
			
		SpellGlobals.SpellCasting.SelfToggle:
			pass
			#if is_instance_valid(active_toggle_spell):
				# If it's already on, turn it off
				#active_toggle_spell.queue_free()
				#active_toggle_spell = null
			#else:
				## If it's off, turn it on and save the reference
				#active_toggle_spell = _spawn_spell_object(player_root.global_transform)
				
		SpellGlobals.SpellCasting.Delayed:
			# Pass a special flag to the factory so the spell knows it's a time-bomb
			_spawn_spell_object(spellTransform, 0.0, true)
			
	## 2. Parse the recipe!
	#for component in our_spell_array:
		#match component["type"]:
			#"casting":
				#if component["value"] == SpellGlobals.SpellCasting.Burst:
					#print("Applying Burst Logic...")
					## Burst just means "fire once right now". 
					## Later, "Continuous" might spawn a timer here instead.
					#
			#"shape":
				#if component["value"] == SpellGlobals.SpellShape.Orb:
					#print("Applying Orb Shape...")
					#var orb = OrbComponent.instantiate()
					#new_spell.add_child(orb)
					#
			## You can easily add "element" here later to turn it red, or "mod_float" to boost speed!
#
	## 3. Put it in the world
	#get_tree().current_scene.add_child(new_spell)
	#new_spell.global_transform = wand.get_spell_spawn_transform()
	pass

func _on_fire_rate_timeout() -> void:
	if wand:
		_spawn_spell_object(wand.get_spell_spawn_transform())

func _spawn_spell_object(spawn_transform: Transform3D, charge_multiplier: float = 0.0, is_delayed: bool = false) -> Node3D:
	var new_spell = SpellBase.new()
	new_spell.name = "ActiveSpell"
	
	# Apply special casting modifiers to the base spell before checking shapes
	if charge_multiplier > 0.0:
		new_spell.damage *= (1.0 + charge_multiplier)
		new_spell.speed *= (1.0 + charge_multiplier * 0.5)
	
	if is_delayed:
		new_spell.is_time_bomb = true # Assume SpellBase has this variable to handle its own delay logic
	
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
