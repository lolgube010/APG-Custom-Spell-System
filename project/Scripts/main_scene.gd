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
		if event.pressed and event.keycode == KEY_4:
			if $SpellSystem/SpellCreation.visible:
				var results = $SpellSystem/SpellCreation.compile_spell()
				for result in results:
					print(result)
