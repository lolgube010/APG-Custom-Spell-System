extends Control

const simpleGraphNode = preload("res://Scenes/GraphNodes/graph_node.tscn")
const startGraphNode  = preload("res://Scenes/GraphNodes/start_node.tscn")
const spellRefNode    = preload("res://Scenes/GraphNodes/spell_ref_node.tscn")

var nodeCount: int = 0
@onready var nodeCountText = $HBoxContainer/Label
@export var player_root: Node3D

signal spell_data_created(spell_array: Array)

var _save_path: String

var _library_list: VBoxContainer
var _library_panel: Panel

const PANEL_WIDTH    = 290
const PANEL_TOP      = 40
const PANEL_HEADER_H = 76
const PANEL_ROW_H    = 32
const PANEL_MIN_H    = 110
const PANEL_MAX_H    = 460

func _ready() -> void:
	if OS.has_feature("editor"):
		_save_path = "res://Data/graph_layout_debug.json"
	else:
		_save_path = OS.get_executable_path().get_base_dir().path_join("graph_layout.json")

	var start_node = startGraphNode.instantiate()
	start_node.name = "StartNode"
	start_node.position_offset = Vector2(50, 200)
	$GraphEdit.add_child(start_node)
	_build_library_panel()

# ---------------------------------------------------------------------------
# Compilation
# ---------------------------------------------------------------------------

func compile_spell() -> Array:
	var spell_sequence: Array = []
	var connections = $GraphEdit.get_connection_list()
	var current_node_name: StringName = "StartNode"
	while current_node_name != "":
		var outgoing_conn = _get_outgoing_connection(current_node_name, connections)
		if not outgoing_conn.is_empty():
			var target_node_name = outgoing_conn["to_node"]
			var target_node = $GraphEdit.get_node(NodePath(target_node_name))
			if target_node.has_method("get_selected_spell_name"):
				var ref_name = target_node.get_selected_spell_name()
				if ref_name != "":
					spell_sequence.append({"type": "spell_ref", "name": ref_name})
			else:
				spell_sequence.append(target_node.get_data_for_port(outgoing_conn["to_port"]))
			current_node_name = target_node_name
		else:
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
		if conn["from_node"] == node_name:
			return conn
	return {}

# ---------------------------------------------------------------------------
# Graph interaction
# ---------------------------------------------------------------------------

func broadcast_spell_update() -> void:
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
	_add_graph_node(simpleGraphNode, "Node_%d" % nodeCount, _rightmost_spawn_pos())

func _on_add_spell_ref_pressed() -> void:
	_add_graph_node(spellRefNode, "SpellRef_%d" % nodeCount, _rightmost_spawn_pos())

func _on_node_delete_request(node_to_delete: Node) -> void:
	nodeCount -= 1
	_update_node_count()
	node_to_delete.queue_free.call_deferred()
	broadcast_spell_update()

func _on_node_settings_changed() -> void:
	broadcast_spell_update()

func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_disconnect_where(func(c): return c["from_node"] == from_node or c["to_node"] == to_node)
	$GraphEdit.connect_node(from_node, from_port, to_node, to_port)
	broadcast_spell_update()

func _on_graph_edit_connection_to_empty(from_node: StringName, from_port: int, _release_position: Vector2) -> void:
	_disconnect_where(func(c): return c["from_node"] == from_node and c["from_port"] == from_port)
	broadcast_spell_update()

func _on_graph_edit_connection_from_empty(to_node: StringName, to_port: int, _release_position: Vector2) -> void:
	_disconnect_where(func(c): return c["to_node"] == to_node and c["to_port"] == to_port)
	broadcast_spell_update()

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	$GraphEdit.disconnect_node(from_node, from_port, to_node, to_port)
	broadcast_spell_update()

func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		if node_name == "StartNode":
			continue
		_disconnect_where(func(c): return c["from_node"] == node_name or c["to_node"] == node_name)
		var node_to_delete = $GraphEdit.get_node(NodePath(node_name))
		if node_to_delete:
			nodeCount -= 1
			_update_node_count()
			node_to_delete.queue_free()
	broadcast_spell_update()

# ---------------------------------------------------------------------------
# Spell Library
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
	_library_panel.offset_bottom = PANEL_TOP + clampi(needed, PANEL_MIN_H, PANEL_MAX_H)

func _load_spell_to_graph(array: Array) -> void:
	_clear_dynamic_nodes()
	nodeCount = 0
	_update_node_count()
	await get_tree().process_frame

	var flat := _flatten_spell_array(array)
	var prev_name: StringName = "StartNode"
	var prev_out_port := 0
	var x := 300.0

	for entry in flat:
		var port := _type_to_port(entry["type"])
		var scene := spellRefNode if entry["type"] == "spell_ref" else simpleGraphNode
		var node := _add_graph_node(scene, "Node_%d" % nodeCount, Vector2(x, 200))
		await get_tree().process_frame

		if entry["type"] == "spell_ref":
			node.set_dropdown_states([entry.get("name", "")])
		else:
			var states := []
			for i in SpellGlobals.attribute_configs.size():
				states.append({"dropdown": 0} if i != port else _entry_to_row_state(entry))
			node.set_dropdown_states(states)

		$GraphEdit.connect_node(prev_name, prev_out_port, node.name, port)
		prev_name = node.name
		prev_out_port = port
		x += node.size.x + 30.0

	_update_node_count()
	broadcast_spell_update()

## Reverse _split_at_triggers: expand trigger child_spells back into a flat sequence.
func _flatten_spell_array(array: Array) -> Array:
	var result: Array = []
	for entry in array:
		result.append(entry)
		if entry["type"] == "trigger" and entry.has("child_spell"):
			result.append_array(_flatten_spell_array(entry["child_spell"]))
	return result

func _type_to_port(type: String) -> int:
	match type:
		"element":                                    return 0
		"mod_float", "mod_vec", "mod_bool", "mod_int": return 1
		"path":                                       return 2
		"shape":                                      return 3
		"casting":                                    return 4
		"effect":                                     return 5
		"trigger":                                    return 6
	return 0

func _entry_to_row_state(entry: Dictionary) -> Dictionary:
	var state := {"dropdown": 0}
	match entry["type"]:
		"element", "path", "shape", "casting", "effect", "trigger":
			state["dropdown"] = entry.get("value", 0)
		"mod_float", "mod_vec", "mod_bool", "mod_int":
			for i in SpellGlobals.MODIFIER_ITEMS.size():
				var item = SpellGlobals.MODIFIER_ITEMS[i]
				if item["spell_type"] == entry["type"] and item["spell_value"] == entry.get("value", 0):
					state["dropdown"] = i
					break
	if entry.has("amount"):
		state["amount"] = entry["amount"]
	return state

func _on_save_to_library_pressed() -> void:
	var compiled := compile_spell()
	if not compiled.is_empty():
		SpellLibrary.save_spell(compiled)

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

func save_graph_layout() -> void:
	var graph_data = {"nodes": {}, "connections": []}
	var has_dynamic_nodes := false
	for child in $GraphEdit.get_children():
		if not child is GraphNode:
			continue
		var is_dynamic := child.name != "StartNode"
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
	if not has_dynamic_nodes:
		print("No dynamic nodes on screen. Skipping save.")
		return
	graph_data["connections"] = $GraphEdit.get_connection_list()
	graph_data["spell_library"] = SpellLibrary.get_library_dict()
	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(graph_data, "\t"))
		file.close()
		print("Graph layout saved successfully.")
	broadcast_spell_update()

func load_graph_layout() -> void:
	if not FileAccess.file_exists(_save_path):
		print("save file not found!")
		return
	var file := FileAccess.open(_save_path, FileAccess.READ)
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK:
		return
	var graph_data = json.data
	if graph_data.has("spell_library"):
		SpellLibrary.load_library_dict(graph_data["spell_library"])
	_clear_dynamic_nodes()
	nodeCount = 0
	await get_tree().process_frame
	for node_name in graph_data.get("nodes", {}):
		var node_data = graph_data["nodes"][node_name]
		var pos := Vector2(node_data["x"], node_data["y"])
		if node_data.get("is_dynamic", false):
			var scene := spellRefNode if node_data.get("node_type", "simple") == "spell_ref" else simpleGraphNode
			var new_node := _add_graph_node(scene, node_name, pos)
			var states = node_data.get("dropdown_states", [])
			if states.size() > 0 and new_node.has_method("set_dropdown_states"):
				await get_tree().process_frame
				new_node.set_dropdown_states(states)
		else:
			var start_node = $GraphEdit.get_node_or_null("StartNode")
			if start_node:
				start_node.position_offset = pos
	for conn in graph_data.get("connections", []):
		$GraphEdit.connect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
	print("Graph layout loaded successfully.")
	_update_node_count()
	broadcast_spell_update()

func clear_saved_graph_layout() -> void:
	if FileAccess.file_exists(_save_path):
		var dir := DirAccess.open(_save_path.get_base_dir())
		var err := dir.remove(_save_path.get_file()) if dir else ERR_CANT_OPEN
		print("Saved graph layout deleted." if err == OK else "Error deleting save file. Code: %d" % err)
	else:
		print("No save file found to clear.")
	_clear_dynamic_nodes()
	var start_node = $GraphEdit.get_node_or_null("StartNode")
	if start_node:
		start_node.position_offset = Vector2(50, 200)
	nodeCount = 0
	_update_node_count()
	broadcast_spell_update()

func _on_button_2_pressed() -> void:
	save_graph_layout()

func _on_button_3_pressed() -> void:
	load_graph_layout()

func _on_button_4_pressed() -> void:
	clear_saved_graph_layout()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Instantiate a graph node, wire up its signals, add it to the GraphEdit.
func _add_graph_node(scene: PackedScene, node_name: String, pos: Vector2) -> GraphNode:
	var node := scene.instantiate() as GraphNode
	node.name = node_name
	node.title = node_name
	node.position_offset = pos
	$GraphEdit.add_child(node)
	nodeCount += 1
	_update_node_count()
	node.delete_request.connect(_on_node_delete_request.bind(node))
	node.setting_changed.connect(_on_node_settings_changed)
	return node

## Remove all non-StartNode GraphNodes and clear all connections.
func _clear_dynamic_nodes() -> void:
	for child in $GraphEdit.get_children():
		if child is GraphNode and child.name != "StartNode":
			child.queue_free()
	$GraphEdit.clear_connections()

## Disconnect all connections that match predicate(conn) -> bool.
func _disconnect_where(predicate: Callable) -> void:
	var to_remove: Array = $GraphEdit.get_connection_list().filter(predicate)
	for conn in to_remove:
		$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])

## Returns the position just to the right of the rightmost graph node.
func _rightmost_spawn_pos() -> Vector2:
	var x := 50.0
	var y := 200.0
	for child in $GraphEdit.get_children():
		if child is GraphNode:
			var right_edge : float = child.position_offset.x + child.size.x
			if right_edge > x:
				x = right_edge
				y = child.position_offset.y
	return Vector2(x + 30.0, y)

func _update_node_count() -> void:
	nodeCountText.text = "Node Count: %d" % nodeCount
