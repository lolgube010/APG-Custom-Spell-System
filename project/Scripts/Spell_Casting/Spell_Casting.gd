extends Node

@export var player_root: Node3D
const OrbComponent = preload("res://Scripts/Spell_Stuff/Shape_Orb.tscn")

func _on_spell_creation_spell_data_created(spell_array: Array, spawn_transform: Transform3D) -> void:
	#momo temp
	print("_on_spell_creation_spell_data_created ran!!!")
	if spell_array.is_empty():
		print("empty spell array!")
		return
	for result in spell_array:
		print(result)
	#momo temp 
	
	if spell_array.is_empty(): return
	
	# 1. Create the blank container
	var new_spell = SpellBase.new()
	new_spell.name = "ActiveSpell"
	
	# 2. Parse the recipe!
	for component in spell_array:
		match component["type"]:
			"casting":
				if component["value"] == SpellGlobals.SpellCasting.Burst:
					print("Applying Burst Logic...")
					# Burst just means "fire once right now". 
					# Later, "Continuous" might spawn a timer here instead.
					
			"shape":
				if component["value"] == SpellGlobals.SpellShape.Orb:
					print("Applying Orb Shape...")
					var orb = OrbComponent.instantiate()
					new_spell.add_child(orb)
					
			# You can easily add "element" here later to turn it red, or "mod_float" to boost speed!

	# 3. Put it in the world
	get_tree().current_scene.add_child(new_spell)
	new_spell.global_transform = player_root.global_transform
	new_spell.global_transform.origin += Vector3(0, 2, 0)
	#new_spell.global_transform = spawn_transform




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
