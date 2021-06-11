extends "res://src/components/modes/BaseManager.gd"

var round_over := false

func _get_synchronized_rpc_methods() -> Array:
	return ['_setup_new_round']

func _do_match_setup() -> void:
	._do_match_setup()
	
	game.connect("player_dead", self, "_on_game_player_dead")

func start_new_round() -> void:
	var operation = RemoteOperations.synchronized_rpc(self, "_setup_new_round")
	if yield(operation, "completed"):
		game.rpc("game_start")
	else:
		match_scene.quit_match()

func _setup_new_round() -> void:
	round_over = false
	game.game_setup(players, map_path)

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("You lose!")
		game.enable_watch_camera()
	
	if get_tree().is_network_server() and not round_over and  (game.players_alive.size() == 1 or not _check_team_alive(player_id)):
		round_over = true
		var winner_id := -1
		if use_teams:
			# The other team wins
			winner_id = 1 if get_player_team(player_id) == 0 else 0
		else:
			var player_keys = game.players_alive.keys()
			winner_id = player_keys[0]

		score.increment_score(winner_id)
		
		var is_match: bool = score.get_score(winner_id) >= config['points_to_win']
		rpc("show_winner", score.get_name(winner_id), score.to_dict(), is_match)

func _check_team_alive(player_id: int) -> bool:
	var team_id = get_player_team(player_id)
	for team_player_id in teams[team_id]:
		if game.players_alive.has(team_player_id):
			return true
	return false

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
