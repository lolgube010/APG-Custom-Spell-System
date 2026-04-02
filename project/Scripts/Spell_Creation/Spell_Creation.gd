extends Control

var simpleGraphNode = load("res://Scripts/Spell_Creation/Scenes/graph_node.tscn")
var startGraphNode = load("res://Scripts/Spell_Creation/Scenes/start_node.tscn")
var initial_position = Vector2(40,40)
var nodeCount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Spawn the Start Node immediately
	var start_node = startGraphNode.instantiate()
	# Hardcode its name so we can easily find it later
	start_node.name = "StartNode" 
	
	# Position it nicely on the left side of the screen
	start_node.position_offset = Vector2(50, 200) 
	
	$GraphEdit.add_child(start_node)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var node = simpleGraphNode.instantiate();
	node.position_offset += initial_position + (nodeCount * Vector2(20,20))
	node.title += str(nodeCount)
	$GraphEdit.add_child(node);
	nodeCount += 1
	print("Node added! Current count is: ", nodeCount)
	node.delete_request.connect(_on_node_delete_request.bind(node))

func _on_node_delete_request(node_to_delete: Node) -> void:
	nodeCount -= 1
	print("Node deleted! Current count is: ", nodeCount)
	node_to_delete.queue_free.call_deferred() #todo, maybe move to nodes.


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	# 1. Look through all existing connections in the graph
	for conn in $GraphEdit.get_connection_list():
		
		# 2. Does the OUTPUT port we are dragging FROM already have a wire?
		if conn["from_node"] == from_node and conn["from_port"] == from_port:
			# Unplug the old wire
			$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
			
		# 3. Does the INPUT port we are dragging TO already have a wire?
		if conn["to_node"] == to_node and conn["to_port"] == to_port:
			# Unplug the old wire
			$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
			
	# 4. Now that the ports are guaranteed to be empty, make the new connection!
	$GraphEdit.connect_node(from_node, from_port, to_node, to_port)

func _on_graph_edit_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	# Loop through all active connections in the GraphEdit
	for conn in $GraphEdit.get_connection_list():
		# Check if this connection starts at the exact node and port we just dragged from
		if conn["from_node"] == from_node and conn["from_port"] == from_port:
			# Disconnect it! We use the destination data stored in the connection dictionary
			$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])


func _on_graph_edit_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	for conn in $GraphEdit.get_connection_list():
		# This time we check the destination side of the wire
		if conn["to_node"] == to_node and conn["to_port"] == to_port:
			$GraphEdit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])


func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	$GraphEdit.disconnect_node(from_node, from_port, to_node, to_port)


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
			node_to_delete.queue_free()

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
			
			# Ask the target node for its data based on the port the wire entered
			var component_data = target_node.get_data_for_port(target_port)
			spell_sequence.append(component_data)
			
			# Move our "current" pointer to this target node for the next loop iteration
			current_node_name = target_node_name
		else:
			# No outgoing wires from the current node. The chain is finished!
			current_node_name = "" 
			
	return spell_sequence

# --- Helper Function ---

func _get_outgoing_connection(node_name: StringName, connections: Array) -> Dictionary:
	for conn in connections:
		# Find the connection where the origin matches our current node
		if conn["from_node"] == node_name:
			return conn
			
	# Return an empty dictionary if no outgoing wire is found
	return {}
