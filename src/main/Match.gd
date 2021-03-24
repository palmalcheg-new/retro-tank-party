extends Node2D

onready var game := $Game
onready var ui_layer := $UILayer

var match_manager

func _ready() -> void:
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	
	randomize()
	
	var songs := ['Track1', 'Track2', 'Track3']
	Music.play(songs[randi() % songs.size()])

func scene_setup(operation: RemoteOperations.ClientOperation, info: Dictionary) -> void:
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
		RemoteOperations.change_scene("res://src/main/MatchSetup.tscn")

func quit_match() -> void:
	OnlineMatch.leave()
	get_tree().change_scene("res://src/main/SessionSetup.tscn")

func _on_Game_game_started() -> void:
	ui_layer.hide_screen()
	ui_layer.hide_all()
	ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	# @todo add some kind of confirmation dialog
	if get_tree().is_network_server():
		finish_match()
	else:
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
	#_on_OnlineMatch_error("Disconnected from host")
	_on_OnlineMatch_error('')

func _on_OnlineMatch_player_left(player) -> void:
	game.kill_player(player.peer_id)
	if OnlineMatch.players.size() < 2:
		_on_OnlineMatch_error(player.username + " has left - not enough players!")
	else:
		ui_layer.show_message(player.username + " has left")
