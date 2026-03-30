extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SpellSystem/SpellCreation.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_TAB:
			if $SpellSystem/SpellCreation.visible:
				$SpellSystem/SpellCreation.hide() 
			else: 
				$SpellSystem/SpellCreation.show()
