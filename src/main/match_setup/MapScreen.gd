extends "res://src/ui/Screen.gd"

onready var map_field = $Panel/VBoxContainer/MapSwitcher
onready var next_button = $Panel/VBoxContainer/NextButton
onready var map_parent = $MapParent

const DEFAULT_MAP = "res://mods/core/maps/map1.tres"

var maps := {}

func _ready() -> void:
	_load_maps()
	
	for map_id in maps:
		map_field.add_item(maps[map_id].name, map_id)
	map_field.value = DEFAULT_MAP

func _show_screen(info: Dictionary = {}) -> void:
	map_field.focus.grab_without_sound()

func _load_maps() -> void:
	for file_path in Modding.find_resources('maps'):
		var resource = load(file_path)
		if resource is GameMap:
			maps[file_path] = resource

func change_map(map: GameMap) -> void:
	if map_parent.has_node('Map'):
		var old_map_scene = map_parent.get_node('Map')
		map_parent.remove_child(old_map_scene)
		old_map_scene.queue_free()
	
	var map_scene = load(map.map_scene).instance()
	map_scene.name = 'Map'
	map_parent.add_child(map_scene)
	
	# Scale map to fit in the viewport.
	map_scene.scale = get_viewport_rect().size / map_scene.get_map_rect().size

func disable_screen() -> void:
	map_field.disabled = true

func _on_MapSwitcher_item_selected(value, index) -> void:
	change_map(maps[value])
	send_remote_update()

func _on_NextButton_pressed() -> void:
	ui_layer.rpc("show_screen", "ReadyScreen")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed('ui_accept'):
		get_tree().set_input_as_handled()
		_on_NextButton_pressed()

func _on_config_changed() -> void:
	send_remote_update()

func send_remote_update() -> void:
	if is_network_master():
		rpc("_remote_update", map_field.value)

puppet func _remote_update(map_id: String) -> void:
	map_field.value = map_id
	change_map(maps[map_id])

func get_map() -> GameMap:
	return maps[map_field.value]
