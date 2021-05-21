extends "res://src/ui/Screen.gd"

onready var mode_field = $Panel/VBoxContainer/ModeSwitcher
onready var description_label = $Panel/VBoxContainer/DescriptionLabel
onready var config_parent = $Panel/VBoxContainer/ConfigParent

var match_modes := {}
var current_config

const DEFAULT_MODE = "res://mods/core/modes/battle_royale.tres"

func _ready() -> void:
	_load_match_modes()
	
	for match_mode_id in match_modes:
		mode_field.add_item(match_modes[match_mode_id].name, match_mode_id)
	mode_field.value = DEFAULT_MODE

func _show_screen(info: Dictionary = {}) -> void:
	mode_field.focus.grab_without_sound()

func _load_match_modes() -> void:
	for file_path in Modding.find_resources('modes'):
		var resource = load(file_path)
		if resource is MatchMode:
			match_modes[file_path] = resource

func change_mode(mode: MatchMode) -> void:
	for child in config_parent.get_children():
		config_parent.remove_child(child)
		child.queue_free()
	
	description_label.text = mode.description
	
	if mode.config_scene:
		current_config = mode.config_scene.instance()
		config_parent.add_child(current_config)
		current_config.connect("changed", self, "_on_config_changed")
	else:
		current_config = null

func disable_screen() -> void:
	mode_field.disabled = true
	current_config.disabled = true

func _on_ModeSwitcher_item_selected(value, index) -> void:
	change_mode(match_modes[value])
	send_remote_update()

func _on_NextButton_pressed() -> void:
	var config = get_config_values()
	if config.get('teams', false):
		ui_layer.show_screen("TeamScreen")
	else:
		ui_layer.show_screen("MapScreen")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed('ui_accept'):
		get_tree().set_input_as_handled()
		_on_NextButton_pressed()

func _on_config_changed() -> void:
	send_remote_update()

func send_remote_update() -> void:
	if is_network_master():
		rpc("_remote_update", mode_field.value, get_config_values())

puppet func _remote_update(mode_path: String, config_values: Dictionary) -> void:
	mode_field.value = mode_path
	set_config_values(config_values)

func get_mode() -> MatchMode:
	return match_modes[mode_field.value]

func get_mode_manager_scene_path() -> String:
	return get_mode().manager_scene.resource_path

func set_mode_manager_scene_path(manager_scene_path: String) -> void:
	var mode: MatchMode
	for resource_path in match_modes:
		mode = match_modes[resource_path]
		if mode.manager_scene.resource_path == manager_scene_path: 
			mode_field.value = resource_path
			break

func set_config_values(values: Dictionary) -> void:
	if current_config:
		current_config.set_config_values(values)

func get_config_values() -> Dictionary:
	if current_config:
		return current_config.get_config_values()
	return {}
