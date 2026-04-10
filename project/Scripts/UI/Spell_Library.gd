extends Node

# { "Spell_1": [...array...], "Spell_2": [...] }
var _library: Dictionary = {}

signal library_changed

func _ready() -> void:
	_load()

func save_spell(array: Array) -> String:
	var savedSpellName := _next_name()
	_library[savedSpellName] = array
	_persist()
	library_changed.emit()
	return savedSpellName

func delete_spell(savedSpellName: String) -> void:
	_library.erase(savedSpellName)
	_persist()
	library_changed.emit()

func rename_spell(old_name: String, new_name: String) -> void:
	if old_name == new_name or new_name.is_empty() or not _library.has(old_name):
		return
	# Preserve insertion order by rebuilding the dict
	var rebuilt: Dictionary = {}
	for key in _library.keys():
		rebuilt[new_name if key == old_name else key] = _library[key]
	_library = rebuilt
	_persist()
	library_changed.emit()

func get_spell(spellName: String) -> Array:
	return _library.get(spellName, [])

func get_all_names() -> Array:
	return _library.keys()

func get_library_dict() -> Dictionary:
	return _library.duplicate(true)

func load_library_dict(data: Dictionary) -> void:
	_library = data
	_persist()
	library_changed.emit()

func _next_name() -> String:
	var i := 1
	while _library.has("Spell_%d" % i):
		i += 1
	return "Spell_%d" % i

func _get_path() -> String:
	if OS.has_feature("editor"):
		return "res://Data/spell_library.json"
	return OS.get_executable_path().get_base_dir().path_join("spell_library.json")

func _persist() -> void:
	var file := FileAccess.open(_get_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_library, "\t"))
		file.close()

func _load() -> void:
	var path := _get_path()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_library = json.data
	file.close()
