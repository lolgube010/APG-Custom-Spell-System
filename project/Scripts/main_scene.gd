extends Node

@onready var spellsystem = $SpellCreation
@onready var _spell_casting = $SpellCasting

func _ready() -> void:
	spellsystem.hide()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			if spellsystem.visible:
				spellsystem.hide()
			elif not _spell_casting.is_hold_casting():
				spellsystem.show()
