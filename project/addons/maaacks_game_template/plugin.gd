@tool
class_name MaaacksGameTemplatePlugin
extends EditorPlugin

const PLUGIN_PATH = "res://addons/maaacks_game_template/"
const PLUGIN_NAME = "Maaack's Game Template"
const PROJECT_SETTINGS_PATH = "maaacks_game_template/"
const APP_CONFIG_RELATIVE_PATH = "base/nodes/autoloads/app_config/app_config.tscn"
const SCENE_LOADER_RELATIVE_PATH = "base/nodes/autoloads/scene_loader/scene_loader.tscn"
const AVAILABLE_TRANSLATIONS : Array = ["en"]

static var instance : MaaacksGameTemplatePlugin

static func get_plugin_name() -> String:
	return PLUGIN_NAME

static func get_settings_path() -> String:
	return PROJECT_SETTINGS_PATH

static func get_plugin_path() -> String:
	return PLUGIN_PATH

static func get_app_config_path() -> String:
	return get_plugin_path() + APP_CONFIG_RELATIVE_PATH

static func get_scene_loader_path() -> String:
	return get_plugin_path() + SCENE_LOADER_RELATIVE_PATH

func _add_audio_bus(bus_name : String) -> void:
	var has_bus_name := false
	for bus_idx in range(AudioServer.bus_count):
		var existing_bus_name := AudioServer.get_bus_name(bus_idx)
		if existing_bus_name == bus_name:
			has_bus_name = true
			break
	if not has_bus_name:
		AudioServer.add_bus()
		var new_bus_idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(new_bus_idx, bus_name)
		AudioServer.set_bus_send(new_bus_idx, &"Master")
	ProjectSettings.save()

func _install_audio_busses() -> void:
	if ProjectSettings.has_setting(PROJECT_SETTINGS_PATH + "disable_install_audio_busses"):
		if ProjectSettings.get_setting(PROJECT_SETTINGS_PATH + "disable_install_audio_busses") :
			return
	_add_audio_bus("Music")
	_add_audio_bus("SFX")
	ProjectSettings.set_setting(PROJECT_SETTINGS_PATH + "disable_install_audio_busses", true)
	ProjectSettings.save()

func _add_translations() -> void:
	var dir := DirAccess.open("res://")
	var translations : PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations", [])
	for available_translation in AVAILABLE_TRANSLATIONS:
		var translation_path = get_plugin_path() + ("base/translations/menus_translations.%s.translation" % available_translation)
		if dir.file_exists(translation_path) and translation_path not in translations:
			translations.append(translation_path)
	ProjectSettings.set_setting("internationalization/locale/translations", translations)

func _enable_plugin():
	add_autoload_singleton("AppConfig", get_app_config_path())
	add_autoload_singleton("SceneLoader", get_scene_loader_path())
	add_autoload_singleton("ProjectMusicController", get_plugin_path() + "base/nodes/autoloads/music_controller/project_music_controller.tscn")
	add_autoload_singleton("ProjectUISoundController", get_plugin_path() + "base/nodes/autoloads/ui_sound_controller/project_ui_sound_controller.tscn")

func _disable_plugin():
	remove_autoload_singleton("AppConfig")
	remove_autoload_singleton("SceneLoader")
	remove_autoload_singleton("ProjectMusicController")
	remove_autoload_singleton("ProjectUISoundController")

func _enter_tree() -> void:
	_install_audio_busses()
	_add_translations()
	instance = self

func _exit_tree() -> void:
	instance = null
