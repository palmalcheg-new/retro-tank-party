extends "res://src/modes/base/BaseManager.gd"

onready var countdown_timer := $CanvasLayer/Control/CountdownTimer

var players_score := {}

func _do_match_setup() -> void:
	._do_match_setup()
	
	game.connect("player_dead", self, "_on_game_player_dead")
	
	countdown_timer.connect("countdown_finished", self, "_on_countdown_finished")

func match_start() -> void:
	.match_start()
	countdown_timer.start_countdown(config['timelimit'] * 60)

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("Wasted!")
		game.enable_watch_camera(true)
	
	if get_tree().is_network_server() and killer_id != -1:
		if not players_score.has(killer_id):
			players_score[killer_id] = 1
		else:
			players_score[killer_id] += 1
		print (players_score)
		
		yield(get_tree().create_timer(2.0), "timeout")
		respawn_player(player_id)

func respawn_player(player_id: int) -> void:
	var player = OnlineMatch.get_player_by_peer_id(player_id)
	var operation = RemoteOperations.synchronized_rpc(game, "respawn_player", [player_id, player.username])
	if yield(operation, "completed"):
		rpc_id(player_id, "_take_control_of_my_player")
	else:
		# @todo what can we do if this fails?
		pass

remotesync func _take_control_of_my_player() -> void:
	game.enable_watch_camera(false)
	
	var player_id = get_tree().get_network_unique_id()
	game.make_player_controlled(player_id)

func _on_countdown_finished() -> void:
	pass

remotesync func show_winner(peer_id: int, host_players_score: Dictionary) -> void:
	var name = OnlineMatch.get_player_by_peer_id(peer_id).username
	ui_layer.show_message(name + " WINS THIS DEATHMATCH!")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	ui_layer.show_screen("RoundScreen", {players_score = host_players_score})
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	match_scene.finish_match()
