extends "res://src/modes/base/BaseManager.gd"

var players_score := {}

func _do_match_setup() -> void:
	._do_match_setup()
	
	game.connect("player_dead", self, "_on_game_player_dead")

func start_new_round() -> void:
	var operation = RemoteOperations.synchronized_rpc(game, "game_setup", [OnlineMatch.get_player_names_by_peer_id()])
	if yield(operation, "completed"):
		game.rpc("game_start")
	else:
		match_scene.quit_match()

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("You lose!")
		game.enable_watch_camera()
	
	if get_tree().is_network_server() and game.players_alive.size() == 1:
		var player_keys = game.players_alive.keys()
		var winner_id = player_keys[0]

		if not players_score.has(winner_id):
			players_score[winner_id] = 1
		else:
			players_score[winner_id] += 1
		
		var is_match: bool = players_score[winner_id] >= config['points_to_win']
		rpc("show_winner", winner_id, players_score, is_match)

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
		match_scene.finish_match()
	elif get_tree().is_network_server():
		start_new_round()
