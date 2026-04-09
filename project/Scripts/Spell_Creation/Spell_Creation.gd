extends Control

const simpleGraphNode = preload("res://Scripts/Spell_Creation/Scenes/graph_node.tscn")
const startGraphNode  = preload("res://Scripts/Spell_Creation/Scenes/start_node.tscn")
const spellRefNode    = preload("res://Scripts/Spell_Creation/Scenes/spell_ref_node.tscn")
var nodeCount = 0
@onready var nodeCountText = $HBoxContainer/Label
@export var player_root: Node3D
signal spell_data_created(spell_array: Array)
const SAVE_PATH = "res://Scripts/Data/graph_layout_debug.json"

var _library_list: VBoxContainer
var _library_panel: Panel

const PANEL_WIDTH        = 290
const PANEL_TOP          = 40
const PANEL_HEADER_H     = 76   # title label + button row + VBox separation
const PANEL_ROW_H        = 32
const PANEL_MIN_H        = 110
const PANEL_MAX_H        = 460

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Spawn the Start Node immediately
	var start_node = startGraphNode.instantiate()
	start_node.name = "StartNode"
	start_node.position_offset = Vector2(50, 200)
	$GraphEdit.add_child(start_node)

	# Build the library panel (top-right corner)
	_build_library_panel()
	
	#var spell_node = find_node_with_signal(player_root)
	#if spell_node:
		#spell_node.spell_cast.connect(_on_spell_data_created)

#func find_node_with_signal(root: Node) -> Node:
	## Check if this node has the script you are looking for
	#if "spell_cast" in root: 
		#return root
	#
	## Otherwise, check children
	#for child in root.get_children():
		#var found = find_node_with_signal(child)
		#if found: return found
	#return null

# ---------------------------------------------------------------------------
# Spell Library UI
# ---------------------------------------------------------------------------

func _build_library_panel() -> void:
	_library_panel = Panel.new()
	_library_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_library_panel.offset_left   = -PANEL_WIDTH
	_library_panel.offset_top    = PANEL_TOP
	_library_panel.offset_right  = 0
	_library_panel.offset_bottom = PANEL_TOP + PANEL_MIN_H
	add_child(_library_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	_library_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Spell Library"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn_row := HBoxContainer.new()
	var btn_ref := Button.new()
	btn_ref.text = "Add Spell Ref"
	btn_ref.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ref.pressed.connect(_on_add_spell_ref_pressed)
	btn_row.add_child(btn_ref)
	var btn_lib := Button.new()
	btn_lib.text = "Save to Library"
	btn_lib.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_lib.pressed.connect(_on_save_to_library_pressed)
	btn_row.add_child(btn_lib)
	vbox.add_child(btn_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_library_list = VBoxContainer.new()
	_library_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_library_list)
	vbox.add_child(scroll)

	SpellLibrary.library_changed.connect(_refresh_library_panel)
	_refresh_library_panel()

func _refresh_library_panel() -> void:
	for child in _library_list.get_children():
		child.queue_free()
	var names := SpellLibrary.get_all_names()
	for spell_name in names:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured: String = spell_name
		var name_field := LineEdit.new()
		name_field.text = spell_name
		name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_field.text_submitted.connect(func(new_name: String): SpellLibrary.rename_spell(captured, new_name.strip_edges()))
		name_field.focus_exited.connect(func(): SpellLibrary.rename_spell(captured, name_field.text.strip_edges()))
		var load_btn := Button.new()
		load_btn.text = "Load"
		load_btn.custom_minimum_size = Vector2(48, 0)
		load_btn.pressed.connect(func(): _load_spell_to_graph(SpellLibrary.get_spell(captured)))
		var del_btn := Button.new()
		del_btn.text = "X"
		del_btn.custom_minimum_size = Vector2(28, 0)
		del_btn.pressed.connect(func(): SpellLibrary.delete_spell(captured))
		row.add_child(name_field)
		row.add_child(load_btn)
		row.add_child(del_btn)
		_library_list.add_child(row)
	_update_panel_size(names.size())

func _update_panel_size(spell_count: int) -> void:
	if not is_instance_valid(_library_panel):
		return
	var needed := PANEL_HEADER_H + spell_count * PANEL_ROW_H
	var h := clampi(needed, PANEL_MIN_H, PANEL_MAX_H)
	_library_panel.offset_bottom = PANEL_TOP + h

func _load_spell_to_graph(array: Array) -> void:
	# Clear existing dynamic nodes and connections
	for child in $GraphEdit.get_children():
		if child is GraphNode and child.name != "StartNode":
			child.queue_free()
	$GraphEdit.clear_connections()
	nodeCount = 0
	updateNodeCount()
	await get_tree().process_frame

	# Flatten triggers back into a linear sequence (inverse of _split_at_triggers)
	var flat := _flatten_spell_array(array)

	var prev_name: StringName = "StartNode"
	var prev_out_port := 0  # StartNode only has output port 0
	var x := 300.0

	for entry in flat:
		var node: GraphNode
		var port := _type_to_port(entry["type"])

		if entry["type"] == "spell_ref":
			node = spellRefNode.instantiate()
			node.name = "SpellRef_%d" % nodeCount
			node.position_offset = Vector2(x, 200)
			$GraphEdit.add_child(node)
			node.delete_request.connect(_on_node_delete_request.bind(node))
			node.setting_changed.connect(_on_node_settings_changed)
			await get_tree().process_frame
			node.set_dropdown_states([entry.get("name", "")])
		else:
			node = simpleGraphNode.instantiate()
			node.name = "Node_%d" % nodeCount
			node.title = node.name
			node.position_offset = Vector2(x, 200)
			$GraphEdit.add_child(node)
			node.delete_request.connect(_on_node_delete_request.bind(node))
			node.setting_changed.connect(_on_node_settings_changed)
			await get_tree().process_frame
			# Build the 7-row states array; all rows default to index 0
			var states := []
			for i in SpellGlobals.attribute_configs.size():
				states.append({"dropdown": 0} if i != port else _entry_to_row_state(entry))
			node.set_dropdown_states(states)

		$GraphEdit.connect_node(prev_name, prev_out_port, node.name, port)
		prev_name = node.name
		prev_out_port = port
		nodeCount += 1
		x += node.size.x + 30.0

	updateNodeCount()
	broadcast_spell_update()

# Reverse _split_at_triggers: expand trigger child_spells back into a flat sequence.
func _flatten_spell_array(array: Array) -> Array:
	var result: Array = []
	for entry in array:
		result.append(entry)
		if entry["type"] == "trigger" and entry.has("child_spell"):
			result.append_array(_flatten_spell_array(entry["child_spell"]))
	return result

# Maps a spell entry type to its attribute_configs row index (= GraphNode slot index).
func _type_to_port(type: String) -> int:
	match type:
		"element":                               return 0
		"mod_float", "mod_vec", "mod_bool", "mod_int": return 1
		"path":                                  return 2
		"shape":                                 return 3
		"casting":                               return 4
		"effect":                                return 5
		"trigger":                               return 6
	return 0

# Converts a spell array entry into the row-state dict that set_dropdown_states expects.
func _entry_to_row_state(entry: Dictionary) -> Dictionary:
	var state := {"dropdown": 0}
	match entry["type"]:
		"element", "path", "shape", "casting", "effect", "trigger":
			state["dropdown"] = entry.get("value", 0)
		"mod_float", "mod_vec", "mod_bool", "mod_int":
			# Find the matching MODIFIER_ITEMS index
			for i in SpellGlobals.MODIFIER_ITEMS.size():
				var item = SpellGlobals.MODIFIER_ITEMS[i]
				if item["spell_type"] == entry["type"] and item["spell_value"] == entry.get("value", 0):
					state["dropdown"] = i
					break
	if entry.has("amount"):
		state["amount"] = entry["amount"]
	return state

func _on_add_spell_ref_pressed() -> void:
	var node = spellRefNode.instantiate()
	var rightmost_x := 50.0
	var spawn_y := 200.0
	for child in $GraphEdit.get_children():
		if child is GraphNode:
			var right_edge : float = child.position_offset.x + child.size.x
			if right_edge > rightmost_x:
				rightmost_x = right_edge
				spawn_y = child.position_offset.y
	node.position_offset = Vector2(rightmost_x + 30.0, spawn_y)
	node.name = "SpellRef_%d" % nodeCount
	$GraphEdit.add_child(node)
	nodeCount += 1
	updateNodeCount()
	node.delete_request.connect(_on_node_delete_request.bind(node))
	node.setting_changed.connect(_on_node_settings_changed)

func _on_save_to_library_pressed() -> void:
	var compiled := compile_spell()
	if compiled.is_empty():
		return
	var saved_name := SpellLibrary.save_spell(compiled)
	print("Saved spell to library as: ", saved_name)

# ---------------------------------------------------------------------------

func broadcast_spell_update() -> void:
	# CRITICAL: We wait one frame before compiling.
	# This ensures GraphEdit has fully processed any deleted nodes or new wire arrays.
	await get_tree().process_frame
	_update_highlights()
	var compiled_array = compile_spell()
	spell_data_created.emit(compiled_array)
	print("Spell updated! Current array: ", compiled_array)

func _update_highlights() -> void:
	for child in $GraphEdit.get_children():
		if child is GraphNode and child.has_method("clear_highlights"):
			child.clear_highlights()
	for conn in $GraphEdit.get_connection_list():
		var from_node = $GraphEdit.get_node_or_null(NodePath(conn["from_node"]))
		var to_node   = $GraphEdit.get_node_or_null(NodePath(conn["to_node"]))
		if from_node and from_node.has_method("highlight_port"):
			from_node.highlight_port(conn["from_port"], true)
		if to_node and to_node.has_method("highlight_port"):
			to_node.highlight_port(conn["to_port"], true)

func _on_button_pressed() -> void:
	var node = simpleGraphNode.instantiate()
	# Place new node just to the right of the rightmost existing node
	var rightmost_x := 50.0
	var spawn_y := 200.0
	for child in $GraphEdit.get_children():
		if child is GraphNode:
			var right_edge : float = child.position_offset.x + child.size.x
			if right_edge > rightmost_x:
				rightmost_x = right_edge
				spawn_y = child.position_offset.y
	node.position_offset = Vector2(rightmost_x + 30.0, spawn_y)
	node.title += str(nodeCount)
	node.name = node.title
	$GraphEdit.add_child(node)
	nodeCount += 1
	updateNodeCount()
	node.delete_request.connect(_on_node_delete_request.bind(node))
	node.setting_changed.connect(_on_node_settings_changed)
	
func _on_node_delete_request(node_to_delete: Node) -> void:
	nodeCount -= 1
	updateNodeCount()
	node_to_delete.queue_free.call_deferred() #todo, maybe move to nodes.
	broadcast_spell_update()

func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	# Enforce one connection per node side: remove any existing outgoing wire from
	# from_node (any port) and any existing incoming wire to to_node (any port).
	var to_remove: Array = []
	for conn in $GraphEdit.get_connection_list():
		if conn["from_node"] == from_node or conn["to_node"] == to_node:
			to_remove.append(conn)
	for conn in to_remove:
		$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])

	$GraphEdit.connect_node(from_node, from_port, to_node, to_port)
	broadcast_spell_update()
	
func _on_graph_edit_connection_to_empty(from_node: StringName, from_port: int, _release_position: Vector2) -> void:
	# Loop through all active connections in the GraphEdit
	for conn in $GraphEdit.get_connection_list():
		# Check if this connection starts at the exact node and port we just dragged from
		if conn["from_node"] == from_node and conn["from_port"] == from_port:
			# Disconnect it! We use the destination data stored in the connection dictionary
			$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
	broadcast_spell_update()

func _on_graph_edit_connection_from_empty(to_node: StringName, to_port: int, _release_position: Vector2) -> void:
	for conn in $GraphEdit.get_connection_list():
		# This time we check the destination side of the wire
		if conn["to_node"] == to_node and conn["to_port"] == to_port:
			$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
	broadcast_spell_update()

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	$GraphEdit.disconnect_node(from_node, from_port, to_node, to_port)
	broadcast_spell_update()

func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		
		# --- THE SHIELD ---
		# If the node trying to be deleted is our protected Start Node, skip it!
		if node_name == "StartNode":
			continue 
		# ------------------
		
		# Clean up attached wires
		for conn in $GraphEdit.get_connection_list():
			if conn["from_node"] == node_name or conn["to_node"] == node_name:
				$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])

		# Delete the node
		var node_to_delete = $GraphEdit.get_node(NodePath(node_name))
		if node_to_delete:
			nodeCount -= 1
			updateNodeCount()
			node_to_delete.queue_free()
	broadcast_spell_update()
#[
  #{"type": "Casting", "value": 0}, 
  #{"type": "Shape", "value": 2},   
  #{"type": "Trigger", "value": 0}, 
  #{"type": "Shape", "value": 3}    
#]

func compile_spell() -> Array:
	var spell_sequence: Array = []
	var connections = $GraphEdit.get_connection_list()
	
	# 1. Start explicitly at our dedicated Start Node
	var current_node_name: StringName = "StartNode"
	
	# 2. Walk the graph sequentially
	while current_node_name != "":
		# Find the wire leaving the current node
		var outgoing_conn = _get_outgoing_connection(current_node_name, connections)
		
		if not outgoing_conn.is_empty():
			# Get the node this wire connects TO, and the port it plugs INTO
			var target_node_name = outgoing_conn["to_node"]
			var target_port = outgoing_conn["to_port"]
			
			var target_node = $GraphEdit.get_node(NodePath(target_node_name))
			
			# Ask the target node for its data based on the port the wire entered.
			# SpellRefNodes emit a spell_ref marker instead of a regular component.
			if target_node.has_method("get_selected_spell_name"):
				var ref_name = target_node.get_selected_spell_name()
				if ref_name != "":
					spell_sequence.append({"type": "spell_ref", "name": ref_name})
			else:
				var component_data = target_node.get_data_for_port(target_port)
				spell_sequence.append(component_data)
			
			# Move our "current" pointer to this target node for the next loop iteration
			current_node_name = target_node_name
		else:
			# No outgoing wires from the current node. The chain is finished!
			current_node_name = "" 
			
	return _split_at_triggers(spell_sequence)

func _split_at_triggers(array: Array) -> Array:
	for i in range(array.size()):
		if array[i]["type"] == "trigger":
			var child := array.slice(i + 1)
			array[i]["child_spell"] = _split_at_triggers(child)
			return array.slice(0, i + 1)
	return array

func _get_outgoing_connection(node_name: StringName, connections: Array) -> Dictionary:
	for conn in connections:
		# Find the connection where the origin matches our current node
		if conn["from_node"] == node_name:
			return conn
			
	# Return an empty dictionary if no outgoing wire is found
	return {}

#func _on_spell_data_created():
	#print("System received signal! Launching Spell")
	#spell_data_created.emit(compile_spell())

# --- UPDATED SAVING AND LOADING ---

func save_graph_layout() -> void:
	var graph_data = {
		"nodes": {},
		"connections": []
	}
	
	# Flag to track if we found anything worth saving
	var has_dynamic_nodes = false 
	
	for child in $GraphEdit.get_children():
		if child is GraphNode:
			var is_dynamic = child.name != "StartNode"
			
			if is_dynamic:
				has_dynamic_nodes = true
				
			var node_data = {
				"x": child.position_offset.x,
				"y": child.position_offset.y,
				"is_dynamic": is_dynamic,
				"node_type": "spell_ref" if child.has_method("get_selected_spell_name") else "simple"
			}
			
			if child.has_method("get_dropdown_states"):
				node_data["dropdown_states"] = child.get_dropdown_states()

			graph_data["nodes"][child.name] = node_data
			
	# If we only found the Start Node, abort the save process entirely
	if not has_dynamic_nodes:
		print("No dynamic nodes on screen. Skipping save.")
		return
		
	graph_data["connections"] = $GraphEdit.get_connection_list()
	graph_data["spell_library"] = SpellLibrary.get_library_dict()

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(graph_data, "\t"))
		file.close()
		print("Graph layout saved successfully.")
	broadcast_spell_update()

func load_graph_layout():
	if not FileAccess.file_exists(SAVE_PATH):
		print("save file not found!")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error == OK:
		var graph_data = json.data
		if graph_data.has("spell_library"):
			SpellLibrary.load_library_dict(graph_data["spell_library"])
		var saved_nodes = graph_data.get("nodes", {})
		
		# 1. Clear out existing dynamic nodes
		for child in $GraphEdit.get_children():
			if child is GraphNode and child.name != "StartNode":
				child.queue_free()
		
		nodeCount = 0		
		await get_tree().process_frame
		
		# 2. Restore Nodes
		for node_name in saved_nodes:
			var node_data = saved_nodes[node_name]
			var pos = Vector2(node_data["x"], node_data["y"])
			
			if node_data.get("is_dynamic", false):
				nodeCount += 1
				var new_node = spellRefNode.instantiate() if node_data.get("node_type", "simple") == "spell_ref" else simpleGraphNode.instantiate()
				new_node.name = node_name
				new_node.title = node_name
				new_node.position_offset = pos
				$GraphEdit.add_child(new_node)
				new_node.delete_request.connect(_on_node_delete_request.bind(new_node))
				new_node.setting_changed.connect(_on_node_settings_changed)

				# FIX: If we saved dropdown states, apply them to the node we just spawned!
				var states = node_data.get("dropdown_states", [])
				if states.size() > 0 and new_node.has_method("set_dropdown_states"):
					# We need to wait one frame for the node's _ready() function to 
					# build the UI rows before we try to set their values
					await get_tree().process_frame 
					new_node.set_dropdown_states(states)
				
				#var num_str = node_name.replace("SimpleNode_", "")
				#if num_str.is_valid_int():
					#nodeCount = maxi(nodeCount, num_str.to_int() + 1)
			else:
				var start_node = $GraphEdit.get_node_or_null("StartNode")
				if start_node:
					start_node.position_offset = pos
					
		# 3. Restore Connections
		$GraphEdit.clear_connections()
		var saved_connections = graph_data.get("connections", [])
		for conn in saved_connections:
			$GraphEdit.connect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
			
		print("Graph layout loaded successfully.")
		updateNodeCount()
	broadcast_spell_update()

func updateNodeCount():
	nodeCountText.text = "Node Count: " + str(nodeCount)

func clear_saved_graph_layout() -> void:
	# Check if the file actually exists before trying to delete it
	if FileAccess.file_exists(SAVE_PATH):
		# Attempt to delete the file
		var error = DirAccess.remove_absolute(SAVE_PATH)
		
		if error == OK:
			print("Saved graph layout successfully deleted.")
		else:
			print("Error deleting save file. Code: ", error)
	else:
		print("No save file found to clear.")
# --- Optional: Wipe the visible graph too ---
	for child in $GraphEdit.get_children():
		if child is GraphNode and child.name != "StartNode":
			child.queue_free()
	
	$GraphEdit.clear_connections()
	
	# Reset the start node to its default position
	var start_node = $GraphEdit.get_node_or_null("StartNode")
	if start_node:
		start_node.position_offset = Vector2(50, 200)
		
	# Reset your counter
	nodeCount = 0
	updateNodeCount()
	broadcast_spell_update()

func _on_node_settings_changed():
	print("node settings changed in spell_creation.gd!")
	broadcast_spell_update()

func _on_button_2_pressed() -> void:
	save_graph_layout()
	pass # Replace with function body.


func _on_button_3_pressed() -> void:
	load_graph_layout()
	pass # Replace with function body.


func _on_button_4_pressed() -> void:
	clear_saved_graph_layout()
	pass # Replace with function body.
