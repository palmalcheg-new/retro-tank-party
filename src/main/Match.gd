extends Node2D

const LOG_FILE_DIRECTORY = 'user://detailed_logs'

onready var game := $Game
onready var ui_layer := $UILayer

onready var regaining_sync_message := $UILayer2/RegainingSyncMessage
onready var regaining_sync_animation_player := $UILayer2/RegainingSyncMessage/AnimationPlayer

var match_manager
var match_info: Dictionary

func _ready() -> void:
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	
	SyncManager.connect("sync_started", self, "_on_SyncManager_sync_started")
	SyncManager.connect("sync_lost", self, "_on_SyncManager_sync_lost")
	SyncManager.connect("sync_regained", self, "_on_SyncManager_sync_regained")
	SyncManager.connect("sync_error", self, "_on_SyncManager_sync_error")
	
	randomize()
	
	var songs := ['Track1', 'Track2', 'Track3']
	Music.play(songs[randi() % songs.size()])

func setup_match_for_replay(my_peer_id: int, peer_ids: Array, match_info: Dictionary) -> void:
	# Hack the player list into OnlineMatch.
	# @todo Handle this with one more layer of indirection?
	var player_names: Dictionary = match_info.get('player_names', {})
	var player_session_ids: Dictionary = match_info.get('player_session_ids', {})
	peer_ids = peer_ids.duplicate()
	peer_ids.push_front(my_peer_id)
	OnlineMatch.players.clear()
	for peer_id in peer_ids:
		var session_id = player_session_ids.get(peer_id, str(peer_id))
		OnlineMatch.players[session_id] = OnlineMatch.Player.new(session_id, player_names.get(peer_id, 'Peer %s' % peer_id), peer_id)
	
	scene_setup(null, match_info)
	scene_start()

func scene_setup(operation: RemoteOperations.ClientOperation, info: Dictionary) -> void:
	# Store the match info for when we return to the match setup screen.
	match_info = info
	
	match_manager = load(info['manager_path']).instance()
	match_manager.name = "MatchManager"
	add_child(match_manager)
	match_manager.match_setup(info, self, game, ui_layer)
	
	if SyncReplay.active:
		ui_layer.show_back_button()
	
	if operation:
		operation.mark_done()
	
	if GameSettings.use_detailed_logging and not SyncReplay.active:
		var dir = Directory.new()
		if not dir.dir_exists(LOG_FILE_DIRECTORY):
			dir.make_dir(LOG_FILE_DIRECTORY)
		
		var datetime = OS.get_datetime(true)
		var match_id = OnlineMatch.match_id
		match_id.erase(match_id.length() - 1, 1)
		
		var log_file_name = "%04d%02d%02d-%02d%02d%02d-%s-%d.log" % [
			datetime['year'],
			datetime['month'],
			datetime['day'],
			datetime['hour'],
			datetime['minute'],
			datetime['second'],
			match_id,
			SyncManager.network_adaptor.get_network_unique_id(),
		]
		
		SyncManager.start_logging(LOG_FILE_DIRECTORY + '/' + log_file_name, match_info)

func scene_start() -> void:
	SyncManager.start()

func finish_match() -> void:
	SyncManager.stop()
	SyncManager.stop_logging()
	
	if SyncManager.network_adaptor.is_network_host() and not SyncReplay.active:
		match_manager.match_stop()
		
		# @todo pass current config so we start from the same settings
		RemoteOperations.change_scene("res://src/main/MatchSetup.tscn", match_info)

func quit_match() -> void:
	SyncManager.stop()
	OnlineMatch.leave()
	
	# Do this last because it will block until the logging thread stops.
	SyncManager.stop_logging()
	
	get_tree().change_scene("res://src/main/SessionSetup.tscn")

func _on_Game_game_error(message) -> void:
	_on_OnlineMatch_error(message)

func _on_Game_game_started() -> void:
	ui_layer.hide_screen()
	ui_layer.hide_all()
	
	if not SyncReplay.active:
		ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	if ui_layer.current_screen_name in ['', 'SettingsScreen']:
		ui_layer.show_screen('MenuScreen')
	else:
		ui_layer.hide_screen()

func _on_MenuScreen_exit_pressed() -> void:
	var alert_content: String
	
	if SyncManager.network_adaptor.is_network_host():
		alert_content = 'This will end the match for everyone and return to the match setup screen.'
	else:
		alert_content = 'You will leave the session and won\'t be able to to rejoin.'
	
	ui_layer.show_alert('Are you sure you want to exit?', alert_content)
	var result: bool = yield(ui_layer, "alert_completed")
	if result:
		if SyncManager.network_adaptor.is_network_host():
			finish_match()
		else:
			quit_match()

#func _unhandled_input(event: InputEvent) -> void:
#	# Trigger debugging action!
#	if event.is_action_pressed('special_debug'):
#		print (" ** DEBUG ** FORCING WEBRTC CONNECTIONS TO CLOSE **")
#		# Close all our peers to force a reconnect (to make sure it works).
#		for session_id in OnlineMatch._webrtc_peers:
#			var webrtc_peer = OnlineMatch._webrtc_peers[session_id]
#			webrtc_peer.close()

#####
# OnlineMatch callbacks
#####

func _on_OnlineMatch_error(message: String):
	if message != '':
		ui_layer.show_message(message)
	ui_layer.hide_screen()
	yield(get_tree().create_timer(2.0), "timeout")
	quit_match()

func _on_OnlineMatch_disconnected():
	#_on_OnlineMatch_error("Disconnected from host")
	_on_OnlineMatch_error('')

# Removes player from their team (if teams are enabled) and returns false if 
# the team still no longer has enough players; otherwise it returns true.
func _remove_from_team(peer_id) -> bool:
	if match_info['config'].get('teams', false):
		var teams = match_info['teams']
		for team in teams:
			if peer_id in team:
				team.erase(peer_id)
				if team.size() == 0:
					return false
	return true

func _on_OnlineMatch_player_left(player) -> void:
	SyncManager.remove_peer(player.peer_id)
	
	# Call deferred so we can still access the player on the players array
	# in all the other signal handlers.
	game.call_deferred("remove_player", player.peer_id)
	
	if not _remove_from_team(player.peer_id) or OnlineMatch.players.size() < 2:
		_on_OnlineMatch_error(player.username + " has left - not enough players!")
	else:
		ui_layer.show_message(player.username + " has left")

#####
# SyncManager callbacks
#####

func _on_SyncManager_sync_started() -> void:
	match_manager.match_start()

func _on_SyncManager_sync_lost() -> void:
	regaining_sync_message.visible = true
	regaining_sync_animation_player.play("Flash")

func _hide_regaining_sync_message() -> void:
	regaining_sync_message.visible = false
	regaining_sync_animation_player.stop()

func _on_SyncManager_sync_regained() -> void:
	_hide_regaining_sync_message()

func _on_SyncManager_sync_error(_msg) -> void:
	_hide_regaining_sync_message()
	_on_OnlineMatch_error('Synchronization lost')
