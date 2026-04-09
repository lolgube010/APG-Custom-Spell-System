extends GraphNode

@onready var titlebar: HBoxContainer = get_titlebar_hbox()

var _dropdown: OptionButton

signal setting_changed

const SLOT_COLOR := Color(0.4, 1.0, 0.8)  # teal — visually distinct from attribute nodes

func _ready() -> void:
	title = "Spell Ref"

	# Close button
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(32, 0)
	close_btn.pressed.connect(func(): delete_request.emit())
	titlebar.add_child(close_btn)

	# Single row: label + spell dropdown
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = "Spell"
	label.custom_minimum_size = Vector2(60, 0)
	row.add_child(label)

	_dropdown = OptionButton.new()
	_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dropdown.item_selected.connect(func(_i): setting_changed.emit())
	row.add_child(_dropdown)

	panel.add_child(row)
	add_child(panel)

	set_slot(0, true, 0, SLOT_COLOR, true, 0, SLOT_COLOR)

	_refresh_dropdown()
	SpellLibrary.library_changed.connect(_refresh_dropdown)

func _refresh_dropdown() -> void:
	var current := get_selected_spell_name()
	_dropdown.clear()
	_dropdown.add_item("(none)")
	for spell_name in SpellLibrary.get_all_names():
		_dropdown.add_item(spell_name)
	# Restore previous selection by name
	if current != "":
		for i in _dropdown.item_count:
			if _dropdown.get_item_text(i) == current:
				_dropdown.select(i)
				break

func get_selected_spell_name() -> String:
	if not _dropdown or _dropdown.selected <= 0:
		return ""
	return _dropdown.get_item_text(_dropdown.selected)

# Save/load compatibility with Spell_Creation's graph layout system
func get_dropdown_states() -> Array:
	return [get_selected_spell_name()]

func set_dropdown_states(states: Array) -> void:
	if states.is_empty():
		return
	var target: String = states[0]
	for i in _dropdown.item_count:
		if _dropdown.get_item_text(i) == target:
			_dropdown.select(i)
			return
