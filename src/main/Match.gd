extends Node2D

onready var game := $Game
onready var ui_layer := $UILayer

var match_manager
var match_info: Dictionary

func _ready() -> void:
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	
	randomize()
	
	var songs := ['Track1', 'Track2', 'Track3']
	Music.play(songs[randi() % songs.size()])

func scene_setup(operation: RemoteOperations.ClientOperation, info: Dictionary) -> void:
	# Store the match info for when we return to the match setup screen.
	match_info = info
	
	match_manager = load(info['manager_path']).instance()
	match_manager.name = "MatchManager"
	add_child(match_manager)
	match_manager.match_setup(info, self, game, ui_layer)
	
	ui_layer.show_back_button()
	
	operation.mark_done()

func scene_start() -> void:
	match_manager.match_start()

func finish_match() -> void:
	if get_tree().is_network_server():
		match_manager.match_stop()
		# @todo pass current config so we start from the same settings
		RemoteOperations.change_scene("res://src/main/MatchSetup.tscn", match_info)

func quit_match() -> void:
	OnlineMatch.leave()
	get_tree().change_scene("res://src/main/SessionSetup.tscn")

func _on_Game_game_error(message) -> void:
	_on_OnlineMatch_error(message)

func _on_Game_game_started() -> void:
	ui_layer.hide_screen()
	ui_layer.hide_all()
	ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	if ui_layer.current_screen_name in ['', 'SettingsScreen']:
		ui_layer.show_screen('MenuScreen')
	else:
		ui_layer.hide_screen()

func _on_MenuScreen_exit_pressed() -> void:
	var alert_content: String
	
	if get_tree().is_network_server():
		alert_content = 'This will end the match for everyone and return to the match setup screen.'
	else:
		alert_content = 'You will leave the session and won\'t be able to to rejoin.'
	
	ui_layer.show_alert('Are you sure you want to exit?', alert_content)
	var result: bool = yield(ui_layer, "alert_completed")
	if result:
		if get_tree().is_network_server():
			finish_match()
		else:
			quit_match()

#func _unhandled_input(event: InputEvent) -> void:
#	# Trigger debugging action!
#	if event.is_action_pressed("special_debug"):
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
		for team_id in teams:
			if peer_id in teams[team_id]:
				teams[team_id].erase(peer_id)
				if teams[team_id].size() == 0:
					return false
	return true

func _on_OnlineMatch_player_left(player) -> void:
	# Call deferred so we can still access the player on the players array
	# in all the other signal handlers.
	game.call_deferred("remove_player", player.peer_id)
	
	if not _remove_from_team(player.peer_id) or OnlineMatch.players.size() < 2:
		_on_OnlineMatch_error(player.username + " has left - not enough players!")
	else:
		ui_layer.show_message(player.username + " has left")
