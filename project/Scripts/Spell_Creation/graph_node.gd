extends GraphNode

@onready var titlebar:HBoxContainer = get_titlebar_hbox()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var close_btn:Button = Button.new()
	close_btn.pressed.connect(_on_delete_request)
	close_btn.pressed.connect(_on_delete_request)
	close_btn.custom_minimum_size = Vector2(32, 0)
	close_btn.text = "x"
	close_btn.theme = theme
	titlebar.add_child(close_btn)

func _on_delete_request() -> void:
	queue_free.call_deferred()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
