extends Control

var simpleGraphNode = load("res://Scripts/Spell_Creation/Scenes/graph_node.tscn")
var initial_position = Vector2(40,40)
var nodeCount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
		# 1. Grab the actual node instance using its StringName
		var node_to_delete = $GraphEdit.get_node(NodePath(node_name))
		
		# 2. Make sure it exists, then delete it
		if node_to_delete:
			nodeCount -= 1
			node_to_delete.queue_free()
			
	print("Nodes deleted via keyboard! Current count is: ", nodeCount)
