extends Control

var simpleGraphNode = load("res://Scripts/Spell_Creation/Scenes/graph_node.tscn")
var nodeCount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var node = simpleGraphNode.instantiate();
	$GraphEdit.add_child(node);
	nodeCount += 1
	node.delete_request.connect(_on_node_delete_request.bind(node))

func _on_node_delete_request(node_to_delete: Node) -> void:
	nodeCount -= 1
	print("Node deleted! Current count is: ", nodeCount)
