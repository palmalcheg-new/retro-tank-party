extends "res://src/components/modes/BaseManager.gd"

const PlayerManager = preload("res://mods/core/modes/football/FootballPlayerManager.tscn")
const FootballWeaponType = preload("res://mods/core/weapons/football.tres")
const FootballScene = preload("res://mods/core/modes/football/Football.tscn")
const GoalScene = preload("res://mods/core/modes/football/Goal.tscn")

const TANK_DIMENSION = 128 * SGFixed.ONE

const THIRTY_TWO = 32 * SGFixed.ONE
const SIXTY_FOUR = 64 * SGFixed.ONE

onready var hud := $CanvasLayer/TimedMatchHUD
onready var player_managers_node := $PlayerManagers
onready var next_round_timer := $NextRoundTimer
onready var show_score_timer := $ShowScoreTimer
onready var match_finished_timer := $MatchFinishedTimer

var football

var round_over := false
var instant_death := false
var next_team_with_ball := -1

var team_starters := [0, 0]
var team_start_transforms := []
var player_start_transforms := []
var goals := []
var player_managers := {}

var map_rect: SGFixedRect2
var bounds_rect: SGFixedRect2
var ball_start_position: SGFixedVector2

func _do_match_setup() -> void:
	for player_id in players:
		var player_manager = PlayerManager.instance()
		player_manager.name = str(player_id)
		player_managers_node.add_child(player_manager)
		player_manager.setup_player_manager(players[player_id], config, game)
		player_manager.connect("respawn_player", self, "_on_player_manager_respawn_player")
		player_managers[player_id] = player_manager
	game.connect("player_spawned", self, "_on_game_player_spawned")
	
	var map_temp = load(map_path).instance()
	team_start_transforms.resize(2)
	for i in range(2):
		team_start_transforms[i] = map_temp.get_team_start_transforms(i)
	game.game_setup(players, map_path, random_seed, _get_player_start_transforms())
	
	map_rect = game.map.get_map_fixed_rect()
	bounds_rect = SGFixed.rect2(map_rect.position.sub(THIRTY_TWO), map_rect.size.sub(SIXTY_FOUR))
	ball_start_position = game.map.get_ball_start_position()
	
	football = FootballScene.instance()
	football.name = 'Football'
	game.add_child(football)
	football.setup_football(bounds_rect)
	football.set_global_fixed_position(ball_start_position)
	football.sync_to_physics_engine()
	football.connect("out_of_bounds", self, "_on_football_out_of_bounds")
	football.connect("grabbed", self, "grab_football")
	
	var goal_transforms = game.map.get_goal_transforms()
	for i in range(2):
		var goal = GoalScene.instance()
		goal.name = 'Goal%s' % (i + 1)
		goal.goal_color = i
		game.add_child_below_node(game.map, goal)
		goal.set_global_fixed_transform(goal_transforms[i])
		goal.sync_to_physics_engine()
		goal.connect("tank_present", self, "_on_goal_tank_present")
		goals.append(goal)
	
	hud.set_instant_death_text("OVERTIME!")
	hud.score.set_entity_count(score.entities.size())
	for team_id in score.entities:
		hud.score.set_entity_name(team_id + 1, score.entities[team_id].name)
	
	OnlineMatch.connect("player_left", self, '_on_OnlineMatch_player_left')
	
	game.connect("player_dead", self, "_on_game_player_dead")
	game.connect("game_started", self, "_on_game_started")
	
	hud.countdown_timer.start_countdown(config['timelimit'] * 60)
	hud.countdown_timer.connect("countdown_finished", self, "_on_countdown_finished")

func _get_player_start_transforms() -> Array:
	var player_start_transforms := []
	player_start_transforms.resize(players.size())
	for team_id in range(teams.size()):
		for team_player_index in range(teams[team_id].size()):
			var player_id = teams[team_id][team_player_index]
			var player = players[player_id]
			player_start_transforms[player.index - 1] = team_start_transforms[team_id][team_player_index]
	return player_start_transforms

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['instant_death'] = instant_death
	state['round_over'] = round_over
	state['next_team_with_ball'] = next_team_with_ball
	return state

func _load_state(state: Dictionary) -> void:
	._load_state(state)
	instant_death = state['instant_death']
	round_over = state['round_over']
	next_team_with_ball = state['next_team_with_ball']

func _on_game_player_spawned(tank) -> void:
	var player_id = tank.get_network_master()
	if player_managers.has(player_id):
		var player_manager = player_managers[player_id]
		player_manager.set_player_tank(tank)
	
	tank.connect("player_dead", self, "_on_tank_player_dead", [tank])
	tank.connect("hurt", self, "_on_tank_hurt", [tank])

func _on_OnlineMatch_player_left(online_player) -> void:
	var player_manager = player_managers[online_player.peer_id]
	player_manager.shutdown_player_manager()
	player_managers_node.remove_child(player_manager)
	player_manager.queue_free()

func _on_game_started() -> void:
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "drop_crate_spawn_area", "spawn_drop_crate")

func _on_football_out_of_bounds() -> void:
	if not round_over:
		round_over = true
		start_new_round("OUT OF BOUNDS!", -1)

func grab_football(tank) -> void:
	if tank:
		tank.set_weapon_type(FootballWeaponType)
		football.mark_as_held(tank)
		
		# Just in case the ball was passed to a tank already in the goal.
		check_goals()

func pass_football(_position: SGFixedVector2, _vector: SGFixedVector2) -> void:
	if football.held:
		var player_id = football.held.get_network_master()
		if player_managers.has(player_id):
			var player_manager = player_managers[player_id]
			player_manager.restore_previous_weapon()
	
	football.pass_football(_position, _vector)

func _on_goal_tank_present(tank, goal) -> void:
	if round_over:
		return
	if football.held == tank:
		var player_team = get_player_team(tank.get_network_master())
		if player_team != goal.goal_color:
			round_over = true
			score.increment_score(player_team)
			hud.score.set_score(player_team + 1, score.get_score(player_team))
			goal.celebrate()
			
			if not instant_death:
				start_new_round("%s SCORES!" % score.get_name(player_team), 1 if player_team == 0 else 0)
			else:
				show_winner(score.get_name(player_team))

func check_goals() -> void:
	if get_tree().is_network_server():
		for goal in goals:
			goal.check_for_tanks()

func start_new_round(message: String, team_with_ball: int) -> void:
	ui_layer.show_message(message)
	round_over = true
	next_round_timer.start()

func _on_NextRoundTimer_timeout() -> void:
	# Get the specific player with the ball.
	var player_with_ball = -1
	if next_team_with_ball != -1:
		if teams[next_team_with_ball].size() > 1:
			player_with_ball = team_starters[next_team_with_ball]
			team_starters[next_team_with_ball] = 1 if player_with_ball == 0 else 0
			player_with_ball = teams[next_team_with_ball][player_with_ball]
		else:
			player_with_ball = teams[next_team_with_ball][0]
	
	next_team_with_ball = -1
	
	var player_health := {}
	for player_id in game.players_alive:
		var tank = game.get_tank(player_id)
		player_health[player_id] = tank.health
	
	game.game_reset()
	
	for player_id in game.players_alive:
		var tank = game.get_tank(player_id)
		tank.update_health(player_health[player_id])
	
	if player_with_ball == -1:
		# Restore the football to its starting position.
		football.pass_football(ball_start_position, SGFixed.vector2(0, 0))
	else:
		grab_football(game.get_tank(player_with_ball))
	
	round_over = false
	ui_layer.hide_message()
	game.game_start()

func _on_tank_player_dead(killer_id: int, tank) -> void:
	var player_id = tank.get_network_master()
	
	var my_id = get_tree().get_network_unique_id()
	if my_id == tank.get_network_master():
		ui_layer.show_message("Wasted!")
	
	if tank == football.held:
		emit_signal("dropped_football", tank.get_global_fixed_position(), SGFixed.vector2(0, 0))
	
	if player_managers.has(player_id):
		var player_manager = player_managers[player_id]
		player_manager.start_respawn_timer()

func _on_tank_hurt(damage: int, attacker_id: int, attack_vector: SGFixedVector2, tank) -> void:
	if tank == football.held:
		pass_football(tank.get_global_fixed_position(), attack_vector)

func _on_player_manager_respawn_player(player_id: int) -> void:
	var player = players[player_id]
	var player_start_transforms = _get_player_start_transforms()
	game.respawn_player(player_id, player_start_transforms[player.index - 1])
	
	if player_id == get_tree().get_network_unique_id():
		ui_layer.hide_message()

func _on_countdown_finished() -> void:
	var winners = score.find_highest()
	if winners.size() == 1:
		round_over = true
		show_winner(score.get_name(winners[0]))
	else:
		instant_death = true
		hud.show_instant_death_label()

func show_winner(winner_name: String) -> void:
	ui_layer.show_message(winner_name + " WINS THIS MATCH!")
	show_score_timer.start()

func _on_ShowScoreTimer_timeout() -> void:
	ui_layer.show_screen("RoundScreen", {score = score.to_dict()})
	match_finished_timer.start()

func _on_MatchFinishedTimer_timeout() -> void:
	match_scene.finish_match()

