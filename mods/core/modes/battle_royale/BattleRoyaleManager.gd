extends "res://src/components/modes/BaseManager.gd"

var score := ScoreCounter.new()

func _get_synchronized_rpc_methods() -> Array:
	return ['_do_start_new_round']

func _do_match_setup() -> void:
	._do_match_setup()
	
	for player_id in players:
		var player = players[player_id]
		score.add_entity(player_id, player.name)
	
	game.connect("player_dead", self, "_on_game_player_dead")

func start_new_round() -> void:
	var operation = RemoteOperations.synchronized_rpc(self, "_do_start_new_round")
	if yield(operation, "completed"):
		game.rpc("game_start")
	else:
		match_scene.quit_match()

func _do_start_new_round() -> void:
	game.game_setup(players, map_path)

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("You lose!")
		game.enable_watch_camera()
	
	if get_tree().is_network_server() and game.players_alive.size() == 1:
		var player_keys = game.players_alive.keys()
		var winner_id = player_keys[0]

		score.increment_score(winner_id)
		
		var is_match: bool = score.get_score(winner_id) >= config['points_to_win']
		rpc("show_winner", score.get_name(winner_id), score.to_dict(), is_match)

remotesync func show_winner(winner_name: String, host_score: Dictionary, is_match: bool = false) -> void:
	if is_match:
		ui_layer.show_message(winner_name + " WINS THE WHOLE MATCH!")
	else:
		ui_layer.show_message(winner_name + " wins this round!")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	ui_layer.show_screen("RoundScreen", {score = host_score})
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	if is_match:
		match_scene.finish_match()
	elif get_tree().is_network_server():
		start_new_round()
