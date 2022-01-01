extends "res://src/components/modes/BaseManager.gd"

onready var you_lose_timer := $YouLoseTimer
onready var show_winner_timer := $ShowWinnerTimer
onready var show_score_timer := $ShowScoreTimer
onready var next_round_timer := $NextRoundTimer

var round_over := false
var match_over := false
var winner_id := -1

func _do_match_setup() -> void:
	._do_match_setup()
	
	game.connect("player_dead", self, "_on_game_player_dead")

func start_new_round() -> void:
	game.game_reset()
	game.game_start()
	round_over = false
	winner_id = -1

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['round_over'] = round_over
	state['match_over'] = match_over
	state['winner_id'] = winner_id
	return state

func _load_state(state: Dictionary) -> void:
	._load_state(state)
	round_over = state['round_over']
	match_over = state['match_over']
	winner_id = state['winner_id']

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		you_lose_timer.start()
	
	if not round_over and (game.players_alive.size() == 1 or (use_teams and not _check_team_alive(player_id))):
		round_over = true
		if use_teams:
			# The other team wins
			winner_id = 1 if get_player_team(player_id) == 0 else 0
		else:
			var player_keys = game.players_alive.keys()
			winner_id = player_keys[0]

		score.increment_score(winner_id)
		match_over = score.get_score(winner_id) >= config['points_to_win']
		
		show_winner_timer.start()

func _check_team_alive(player_id: int) -> bool:
	var team_id = get_player_team(player_id)
	for team_player_id in teams[team_id]:
		if game.players_alive.has(team_player_id):
			return true
	return false

func _on_YouLoseTimer_timeout() -> void:
	game.enable_watch_camera()
	if not round_over and not match_over:
		ui_layer.show_message("You lose!")

func _on_ShowWinnerTimer_timeout() -> void:
	var winner_name = score.get_name(winner_id)
	
	if match_over:
		ui_layer.show_message(winner_name + " WINS THE WHOLE MATCH!")
	else:
		ui_layer.show_message(winner_name + " wins this round!")
	
	show_score_timer.start()

func _on_ShowScoreTimer_timeout() -> void:
	ui_layer.show_screen("RoundScreen", {score = score.to_dict()})
	next_round_timer.start()

func _on_NextRoundTimer_timeout() -> void:
	if match_over:
		match_scene.finish_match()
	else:
		start_new_round()
