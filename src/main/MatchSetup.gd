extends Node2D

onready var ui_layer = $UILayer
onready var mode_screen = $UILayer/Screens/ModeScreen
onready var map_screen = $UILayer/Screens/MapScreen
onready var map_parent = $MapParent

func _ready() -> void:
	if OnlineMatch.players.size() < 2:
		get_tree().change_scene("res://src/main/SessionSetup.tscn")
		return
	
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	
	# Make the host in charge of this scene.
	set_network_master(1)
	show_default_message()
	if not is_network_master():
		ui_layer.show_cover()
		for screen in ui_layer.get_screens():
			if screen.has_method('disable_screen'):
				screen.disable_screen()
	
	ui_layer.show_screen("ModeScreen")
	ui_layer.show_back_button()
	
	Music.play("Menu")

func show_default_message() -> void:
	if get_tree().is_network_server():
		ui_layer.show_message("You're the host! How you wanna do this?")
	else:
		ui_layer.show_message("The host is configuring the match...")

func _on_UILayer_change_screen(name, screen) -> void:
	show_default_message()

func _on_UILayer_back_button() -> void:
	var current_screen = ui_layer.current_screen_name
	
	if not is_network_master() or current_screen == "ModeScreen":
		var alert_content: String
	
		if get_tree().is_network_server():
			alert_content = 'This will end the session for everyone.'
		else:
			alert_content = 'You will leave the session and won\'t be able to to rejoin.'
		
		ui_layer.show_alert('Are you sure you want to exit?', alert_content)
		var result: bool = yield(ui_layer, "alert_completed")
		if result:
			OnlineMatch.leave()
			get_tree().change_scene("res://src/main/SessionSetup.tscn")
		elif not is_network_master():
			ui_layer.show_cover()
	elif current_screen == 'ReadyScreen':
		ui_layer.show_screen('MapScreen')
	elif current_screen == 'TeamScreen':
		ui_layer.show_screen('ModeScreen')
	elif current_screen == 'MapScreen':
		var config = mode_screen.get_config_values()
		if config.get('teams', false):
			ui_layer.show_screen('TeamScreen')
		else:
			ui_layer.show_screen('ModeScreen')

func _on_MapScreen_map_changed(map_scene_path) -> void:
	if not map_parent:
		return
	
	if map_parent.has_node('Map'):
		var old_map_scene = map_parent.get_node('Map')
		map_parent.remove_child(old_map_scene)
		old_map_scene.queue_free()
	
	var map_scene = load(map_scene_path).instance()
	map_scene.name = 'Map'
	map_parent.add_child(map_scene)
	
	# Scale map to fit in the viewport.
	var map_rect = map_scene.get_map_rect()
	map_scene.position -= map_rect.position
	map_scene.scale = get_viewport_rect().size / map_rect.size

func _on_ReadyScreen_ready_pressed() -> void:
	var match_info = {
		manager_path = mode_screen.get_mode_manager_scene_path(),
		config = mode_screen.get_config_values(),
		map_path = map_screen.get_map_scene_path(),
	}
	RemoteOperations.change_scene("res://src/main/Match.tscn", match_info)

func scene_setup(operation: RemoteOperations.ClientOperation, info: Dictionary) -> void:
	# Start with the values from the last match.
	if info.has('manager_path'):
		mode_screen.set_mode_manager_scene_path(info['manager_path'])
		if info.has('config'):
			mode_screen.set_config_values(info['config'])
	if info.has('map_path'):
		map_screen.set_map_scene_path(info['map_path'])
	
	operation.mark_done()

func _on_OnlineMatch_error(message: String):
	if message != '':
		ui_layer.show_message(message)
	ui_layer.hide_screen()
	yield(get_tree().create_timer(2.0), "timeout")
	get_tree().change_scene("res://src/main/SessionSetup.tscn")

func _on_OnlineMatch_disconnected():
	#_on_OnlineMatch_error("Disconnected from host")
	_on_OnlineMatch_error('')

func _on_OnlineMatch_player_left(player) -> void:
	if OnlineMatch.players.size() < 2:
		_on_OnlineMatch_error(player.username + " has left - not enough players!")
	else:
		ui_layer.show_message(player.username + " has left")
