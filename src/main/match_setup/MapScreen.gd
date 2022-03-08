extends "res://src/ui/Screen.gd"

onready var map_field = $Panel/VBoxContainer/MapSwitcher
onready var next_button = $Panel/VBoxContainer/NextButton

const DEFAULT_MAP = "res://mods/core/maps/battlefield.tres"

var maps := {}

signal map_changed (map_scene_path)

func _ready() -> void:
	_load_maps()
	
	for map_id in maps:
		map_field.add_item(maps[map_id].name, map_id)
	map_field.set_value(DEFAULT_MAP, false)

func _show_screen(info: Dictionary = {}) -> void:
	var mode_screen = ui_layer.get_screen("ModeScreen")
	if mode_screen:
		_update_map_field_for_mode(mode_screen.get_mode())
	
	change_map(maps[map_field.value])
	map_field.focus.grab_without_sound()

func _load_maps() -> void:
	for file_path in Modding.find_resources('maps'):
		var resource = load(file_path)
		if resource is GameMap:
			maps[file_path] = resource

func _update_map_field_for_mode(mode: MatchMode) -> void:
	var old_value = map_field.value
		
	map_field.clear_items()
	for map_id in maps:
		if mode.requires_goals:
			if maps[map_id].has_goals:
				map_field.add_item(maps[map_id].name, map_id)
		else:
			if not maps[map_id].has_goals:
				map_field.add_item(maps[map_id].name, map_id)
	
	if not map_field.set_value(old_value, false):
		if not map_field.set_value(DEFAULT_MAP, false):
			map_field.set_selected(0, false)

func change_map(map: GameMap) -> void:
	emit_signal("map_changed", map.map_scene)

func disable_screen() -> void:
	map_field.disabled = true

func _on_MapSwitcher_item_selected(value, index) -> void:
	change_map(maps[value])
	send_remote_update()

func _on_NextButton_pressed() -> void:
	ui_layer.show_screen("ReadyScreen")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed('ui_accept'):
		get_tree().set_input_as_handled()
		_on_NextButton_pressed()

func _on_config_changed() -> void:
	send_remote_update()

func send_remote_update() -> void:
	if SyncManager.network_adaptor.is_network_host():
		rpc("_remote_update", map_field.value)

puppet func _remote_update(map_id: String) -> void:
	map_field.value = map_id
	change_map(maps[map_id])

func get_map() -> GameMap:
	return maps[map_field.value]

func get_map_scene_path() -> String:
	return get_map().map_scene

func set_map_scene_path(map_scene: String) -> void:
	var map: GameMap
	for resource_path in maps:
		map = maps[resource_path]
		if map.map_scene == map_scene:
			map_field.value = resource_path
			break
