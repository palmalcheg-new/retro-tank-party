extends "res://src/ui/Screen.gd"

onready var mode_field = $Panel/VBoxContainer/ModeSwitcher
onready var description_label = $Panel/VBoxContainer/DescriptionLabel
onready var config_parent = $Panel/VBoxContainer/ConfigParent

var match_modes := {}
var current_config

const MODES_PATH = "res://src/modes/"

func _ready() -> void:
	_load_match_modes()
	
	for match_mode_id in match_modes:
		mode_field.add_item(match_modes[match_mode_id].name, match_mode_id)
	change_mode(match_modes[mode_field.value])
	
	mode_field.grab_focus()

func _load_match_modes() -> void:
	var dir = Directory.new()
	if dir.open(MODES_PATH) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var resource = load(MODES_PATH + file_name)
				if resource is MatchMode:
					match_modes[MODES_PATH + file_name] = resource
			file_name = dir.get_next()

func change_mode(mode: MatchMode) -> void:
	for child in config_parent.get_children():
		config_parent.remove_child(child)
		child.queue_free()
	
	description_label.text = mode.description
	
	if mode.config_scene:
		current_config = mode.instance_config_scene()
		config_parent.add_child(current_config)
	else:
		current_config = null

func _on_ModeSwitcher_item_selected(value, index) -> void:
	change_mode(match_modes[value])

func _on_NextButton_pressed() -> void:
	ui_layer.show_screen("ReadyScreen")

func get_mode() -> String:
	return match_modes[mode_field.value]

func get_config_values() -> Dictionary:
	if current_config.has_method('get_config_values'):
		return current_config.get_config_values()
	return {}
