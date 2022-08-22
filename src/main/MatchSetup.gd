extends Node2D

onready var ui_layer = $UILayer
onready var mode_screen = $UILayer/Screens/ModeScreen
onready var map_screen = $UILayer/Screens/MapScreen
onready var team_screen = $UILayer/Screens/TeamScreen

onready var map_parent = $MapParent

func _ready() -> void:
	if OnlineMatch.get_active_player_count() < 2:
		get_tree().change_scene("res://src/main/SessionSetup.tscn")
		return

	OnlineMatch.connect("error_code", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")

	# Make the host in charge of this scene.
	set_network_master(1)
	show_default_message()
	if not SyncManager.network_adaptor.is_network_host():
		ui_layer.show_cover()
		for screen in ui_layer.get_screens():
			if screen.has_method('disable_screen'):
				screen.disable_screen()

	ui_layer.show_screen("ModeScreen")
	ui_layer.show_back_button()

	Music.play("Menu")

func show_default_message() -> void:
	if SyncManager.network_adaptor.is_network_host():
		ui_layer.show_message("MESSAGE_SETUP_HOST")
	else:
		ui_layer.show_message("MESSAGE_SETUP_CLIENT")

func _on_UILayer_change_screen(name, screen, info) -> void:
	show_default_message()
	if SyncManager.network_adaptor.is_network_host():
		ui_layer.rpc("show_screen", name, info)

func _on_UILayer_back_button() -> void:
	var current_screen = ui_layer.current_screen_name

	if not SyncManager.network_adaptor.is_network_host() or current_screen == "ModeScreen":
		var alert_content: String

		if SyncManager.network_adaptor.is_network_host():
			alert_content = 'ALERT_LEAVE_MATCH_SETUP_HOST'
		else:
			alert_content = 'ALERT_LEAVE_MATCH'

		ui_layer.show_alert('ALERT_LEAVE_MATCH_TITLE', alert_content)
		var result: bool = yield(ui_layer, "alert_completed")
		if result:
			OnlineMatch.leave()
			get_tree().change_scene("res://src/main/SessionSetup.tscn")
		elif not SyncManager.network_adaptor.is_network_host():
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

	var old_map_scene = map_parent.get_node_or_null(@"Map")
	if old_map_scene:
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
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var player_session_ids := {}
	for session_id in OnlineMatch.get_active_players():
		player_session_ids[OnlineMatch.players[session_id].peer_id] = session_id

	var match_info = {
		manager_path = mode_screen.get_mode_manager_scene_path(),
		config = mode_screen.get_config_values(),
		map_path = map_screen.get_map_scene_path(),
		teams = team_screen.get_teams(),
		random_seed = rng.seed,
		player_names = OnlineMatch.get_active_player_names_by_peer_id(),
		player_session_ids = player_session_ids,

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
	if info.has('teams'):
		team_screen.set_teams(info['teams'])

	operation.mark_done()

func _error(message: String):
	if message != '':
		ui_layer.show_message(message)
	ui_layer.hide_screen()
	yield(get_tree().create_timer(2.0), "timeout")
	get_tree().change_scene("res://src/main/SessionSetup.tscn")

func _on_OnlineMatch_error(code: int, message: String, extra):
	_error(Utils.translate_online_match_error(code, message, extra))

func _on_OnlineMatch_disconnected():
	#_error("Disconnected from host")
	_error('')

func _on_OnlineMatch_player_left(player) -> void:
	SyncManager.remove_peer(player.peer_id)
	if OnlineMatch.get_active_player_count() < 2:
		_error(tr("MESSAGE_PLAYER_HAS_LEFT_NOT_ENOUGH_PLAYERS") % player.username)
	else:
		ui_layer.show_message(tr("MESSAGE_PLAYER_HAS_LEFT") % player.username)
