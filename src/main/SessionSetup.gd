extends Node2D

onready var ui_layer: UILayer = $UILayer
onready var ready_screen = $UILayer/Screens/ReadyScreen

var players_ready := {}

func _ready() -> void:
	# Make extra sure that we aren't in an existing match when this scene starts.
	OnlineMatch.leave()
	
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
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
	
		if get_tree().is_network_server():
			alert_content = 'This will end the match for everyone.'
		else:
			alert_content = 'You will leave the session and won\'t be able to to rejoin.'
		
		ui_layer.show_alert('Are you sure you want to exit?', alert_content)
		var result: bool = yield(ui_layer, "alert_completed")
		if not result:
			return
	
	OnlineMatch.leave()
	
	if ui_layer.current_screen_name in ['ConnectionScreen', 'MatchScreen']:
		get_tree().change_scene("res://src/main/Title.tscn")
	else:
		ui_layer.show_screen("MatchScreen")

func _on_ReadyScreen_ready_pressed() -> void:
	rpc("player_ready", OnlineMatch.get_my_session_id())

remotesync func player_ready(session_id: String) -> void:
	ready_screen.set_status(session_id, "READY!")
	
	if get_tree().is_network_server() and not players_ready.has(session_id):
		players_ready[session_id] = true
		if players_ready.size() == OnlineMatch.players.size():
			if OnlineMatch.match_state != OnlineMatch.MatchState.PLAYING:
				OnlineMatch.start_playing()
			
			RemoteOperations.change_scene("res://src/main/MatchSetup.tscn")

#####
# OnlineMatch callbacks
#####

func _on_OnlineMatch_error(message: String):
	if message != '':
		ui_layer.show_message(message)
	ui_layer.show_screen("MatchScreen")

func _on_OnlineMatch_disconnected():
	#_on_OnlineMatch_error("Disconnected from host")
	_on_OnlineMatch_error('')

func _on_OnlineMatch_player_left(player) -> void:
	ui_layer.show_message(player.username + " has left")
	players_ready.erase(player.peer_id)

func _on_OnlineMatch_player_status_changed(player, status) -> void:
	if status == OnlineMatch.PlayerStatus.CONNECTED:
		if get_tree().is_network_server():
			# Tell this new player about all the other players that are already ready.
			for session_id in players_ready:
				rpc_id(player.peer_id, "player_ready", session_id)
