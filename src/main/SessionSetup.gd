extends Node2D

onready var ui_layer: UILayer = $UILayer
onready var ready_screen = $UILayer/Screens/ReadyScreen

var players_ready := {}

func _ready() -> void:
	# Make extra sure that we aren't in an existing match when this scene starts.
	OnlineMatch.leave()
	SyncManager.stop()
	SyncManager.clear_peers()

	# Reset the network adaptor if it has been changed by Practice mode.
	SyncManager.reset_network_adaptor()

	OnlineMatch.connect("error_code", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_status_changed", self, "_on_OnlineMatch_player_status_changed")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")

	ui_layer.show_screen("ConnectionScreen")
	ui_layer.show_back_button()

	Music.play("Menu")

#####
# UI callbacks
#####

func _on_UILayer_back_button() -> void:
	ui_layer.hide_message()

	if ui_layer.current_screen_name == 'ReadyScreen':
		var alert_content: String

		if SyncManager.network_adaptor.is_network_host():
			alert_content = 'ALERT_LEAVE_MATCH_SETUP_HOST'
		else:
			alert_content = 'ALERT_LEAVE_MATCH'

		ui_layer.show_alert('ALERT_LEAVE_MATCH_TITLE', alert_content)
		var result: bool = yield(ui_layer, "alert_completed")
		if not result:
			return

	OnlineMatch.leave()

	if ui_layer.current_screen_name in ['ConnectionScreen', 'MatchScreen']:
		get_tree().change_scene("res://src/main/Title.tscn")
	else:
		_return_to_match_screen()

func _on_ReadyScreen_ready_pressed() -> void:
	rpc("player_ready", OnlineMatch.get_my_session_id())

remotesync func player_ready(session_id: String) -> void:
	ready_screen.set_status(session_id, "PLAYER_STATUS_READY")

	if SyncManager.network_adaptor.is_network_host() and not players_ready.has(session_id):
		players_ready[session_id] = true
		_start_match_if_all_ready()

func _check_players_ready() -> bool:
	for session_id in OnlineMatch.players:
		if not players_ready.has(session_id):
			return false
	return true

func _start_match_if_all_ready() -> void:
	if _check_players_ready():
		if OnlineMatch.match_state != OnlineMatch.MatchState.PLAYING:
			OnlineMatch.start_playing()

		RemoteOperations.change_scene("res://src/main/MatchSetup.tscn")

func _return_to_match_screen() -> void:
	SyncManager.clear_peers()
	ui_layer.show_screen("MatchScreen")

#####
# OnlineMatch callbacks
#####

func _error(message: String):
	ui_layer.show_message(message)
	_return_to_match_screen()

func _on_OnlineMatch_error(code: int, message: String, extra):
	_error(Utils.translate_online_match_error(code, message, extra))

func _on_OnlineMatch_disconnected():
	_return_to_match_screen()

func _on_OnlineMatch_player_left(player) -> void:
	ui_layer.show_message(tr("MESSAGE_PLAYER_HAS_LEFT") % player.username)
	players_ready.erase(player.session_id)
	SyncManager.remove_peer(player.peer_id)

	# It's possible that all players marked ready except for the one who left,
	# so check if all are ready, and if so, start the match.
	call_deferred("_start_match_if_all_ready")

func _on_OnlineMatch_player_status_changed(player, status) -> void:
	if status == OnlineMatch.PlayerStatus.CONNECTED:
		if SyncManager.network_adaptor.is_network_host():
			# Tell this new player about all the other players that are already ready.
			for session_id in players_ready:
				rpc_id(player.peer_id, "player_ready", session_id)
