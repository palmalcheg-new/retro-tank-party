extends Node2D

onready var game := $Game
onready var ui_layer := $UILayer

var match_manager

var players_score := {}

func _ready() -> void:
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	
	randomize()

func scene_setup(operation: RemoteOperations.ClientOperation, info: Dictionary) -> void:
	print (info)
	if info.has('mode_path'):
		var match_mode: MatchMode = load(info['mode_path'])
		match_manager = match_mode.manager_scene.instance()
		match_manager.name = "MatchManager"
		add_child(match_manager)
		match_manager.match_manager_setup(info, self, game, ui_layer)
	
	game.game_setup(OnlineMatch.get_player_names_by_peer_id())
	ui_layer.show_back_button()
	
	operation.mark_done()

func scene_start() -> void:
	game.rpc("game_start")

func quit_match() -> void:
	game.game_stop()
	OnlineMatch.leave()
	get_tree().change_scene("res://src/SessionSetup.tscn")

#####
# UI callbacks
#####

func _on_UILayer_back_button() -> void:
	# TODO: allow the host to go back to match setup rather than leaving.
	quit_match()

#func _unhandled_input(event: InputEvent) -> void:
#	# Trigger debugging action!
#	if event.is_action_pressed("player_debug"):
#		# Close all our peers to force a reconnect (to make sure it works).
#		for session_id in OnlineMatch.webrtc_peers:
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
	if game.game_started:
		game.game_stop()
	
	#_on_OnlineMatch_error("Disconnected from host")
	_on_OnlineMatch_error('')

func _on_OnlineMatch_player_left(player) -> void:
	ui_layer.show_message(player.username + " has left")
	game.kill_player(player.peer_id)

#####
# Gameplay methods and callbacks
#####

func restart() -> void:
	var operation = RemoteOperations.synchronized_rpc(game, "game_setup", [OnlineMatch.get_player_names_by_peer_id()])
	if yield(operation, "completed"):
		game.rpc("game_start")
	else:
		quit_match()

func _on_Game_game_started() -> void:
	ui_layer.hide_screen()
	ui_layer.hide_all()
	ui_layer.show_back_button()

func _on_Game_player_dead(player_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("You lose!")

func _on_Game_game_over(player_id: int) -> void:
	if get_tree().is_network_server():
		if not players_score.has(player_id):
			players_score[player_id] = 1
		else:
			players_score[player_id] += 1
		
		var player_session_id = OnlineMatch.get_session_id(player_id)
		var is_match: bool = players_score[player_id] >= 5
		rpc("show_winner", player_id, players_score, is_match)

remotesync func show_winner(peer_id: int, host_players_score: Dictionary, is_match: bool = false) -> void:
	var name = OnlineMatch.get_player_by_peer_id(peer_id).username
	
	if is_match:
		ui_layer.show_message(name + " WINS THE WHOLE MATCH!")
	else:
		ui_layer.show_message(name + " wins this round!")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	ui_layer.show_screen("RoundScreen", {players_score = host_players_score})
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	if is_match:
		quit_match()
	elif get_tree().is_network_server():
		restart()
