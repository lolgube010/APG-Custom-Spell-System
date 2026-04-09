extends Node

@onready var spellsystem = $SpellCreation
@onready var _spell_casting = $SpellCasting

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spellsystem.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_TAB:
			if spellsystem.visible:
				spellsystem.hide()
			elif _spell_casting.is_hold_casting():
				pass  # Cannot open editor while SelfHold cast is active — release LMB first.
			else:
				spellsystem.show()
		if event.pressed and event.keycode == KEY_4:
			if spellsystem.visible:
				var results = spellsystem.compile_spell()
				for result in results:
					print(result)
