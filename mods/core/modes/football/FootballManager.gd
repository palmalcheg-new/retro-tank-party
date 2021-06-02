extends "res://src/components/modes/BaseManager.gd"

const FootballWeaponType = preload("res://mods/core/weapons/football.tres")
const FootballScene = preload("res://mods/core/modes/football/Football.tscn")
const GoalScene = preload("res://mods/core/modes/football/Goal.tscn")

const TANK_SIZE := Vector2(128, 128)

onready var hud := $CanvasLayer/TimedMatchHUD

var football

var round_over := false
var instant_death := false
var team_starters := [0, 0]
var team_start_transforms := []
var player_start_transforms := []
var goals := []

var map_rect: Rect2
var bounds_rect: Rect2
var ball_start_position: Vector2

func _get_synchronized_rpc_methods() -> Array:
	return ['_setup_new_round']

func _do_match_setup() -> void:
	var map_temp = load(map_path).instance()
	team_start_transforms.resize(2)
	for i in range(2):
		team_start_transforms[i] = map_temp.get_team_start_transforms(i)
	_game_setup_with_start_positions()
	
	map_rect = game.map.get_map_rect()
	bounds_rect = Rect2(map_rect.position + Vector2(32, 32), map_rect.size - Vector2(64, 64))
	ball_start_position = game.map.get_ball_start_position()
	
	football = FootballScene.instance()
	football.name = 'Football'
	game.add_child(football)
	football.setup_football(bounds_rect)
	football.global_position = ball_start_position
	if get_tree().is_network_server():
		football.connect("out_of_bounds", self, "_on_football_out_of_bounds")
		football.connect("grabbed", self, "_on_football_grabbed")
	
	var goal_transforms = game.map.get_goal_transforms()
	for i in range(2):
		var goal = GoalScene.instance()
		goal.name = 'Goal%s' % (i + 1)
		goal.goal_color = i
		game.add_child_below_node(game.map, goal)
		goal.global_transform = goal_transforms[i]
		if get_tree().is_network_server():
			goal.connect("tank_present", self, "_on_goal_tank_present")
		goals.append(goal)
	
	hud.set_instant_death_text("OVERTIME!")
	hud.score.set_entity_count(score.entities.size())
	for team_id in score.entities:
		hud.score.set_entity_name(team_id + 1, score.entities[team_id].name)
	
	game.connect("player_dead", self, "_on_game_player_dead")
	if get_tree().is_network_server():
		game.connect("game_started", self, "_on_game_started")
	
	hud.countdown_timer.connect("countdown_finished", self, "_on_countdown_finished")

func match_start() -> void:
	.match_start()
	hud.countdown_timer.start_countdown(config['timelimit'] * 60)

func _on_game_started() -> void:
	get_tree().call_group("drop_crate_spawn_area", "spawn_drop_crate")

func _on_football_out_of_bounds() -> void:
	if not round_over:
		round_over = true
		rpc("start_new_round", "OUT OF BOUNDS!", -1)

func _on_football_grabbed(tank) -> void:
	rpc("grab_football", tank.get_path())

remotesync func grab_football(tank_path: NodePath) -> void:
	var tank = get_node(tank_path)
	if tank:
		var previous_weapon_type = tank.weapon_type
		tank.set_weapon_type(FootballWeaponType)
		tank.weapon.previous_weapon_type = previous_weapon_type
		football.mark_as_held(tank)
		
		# Just in case the ball was passed to a tank already in the goal.
		check_goals()

remotesync func pass_football(_position: Vector2, _vector: Vector2) -> void:
	football.pass_football(_position, _vector)

func _on_goal_tank_present(tank, goal) -> void:
	if round_over:
		return
	if football.held == tank:
		var player_team = get_player_team(tank.get_network_master())
		if player_team != goal.goal_color:
			round_over = true
			score.increment_score(player_team)
			hud.score.rpc("set_score", player_team + 1, score.get_score(player_team))
			goal.rpc("celebrate")
			
			if not instant_death:
				rpc("start_new_round", "%s SCORES!" % score.get_name(player_team), 1 if player_team == 0 else 0)
			else:
				rpc("show_winner", score.get_name(player_team), score.to_dict())

func check_goals() -> void:
	if get_tree().is_network_server():
		for goal in goals:
			goal.check_for_tanks()

remotesync func start_new_round(message: String, team_with_ball: int) -> void:
	ui_layer.show_message(message)
	
	if get_tree().is_network_server():
		yield(get_tree().create_timer(4.0), "timeout")
		
		# Get the specific player with the ball.
		var player_with_ball = -1
		if team_with_ball != -1:
			if teams[team_with_ball].size() > 1:
				player_with_ball = team_starters[team_with_ball]
				team_starters[team_with_ball] = 1 if player_with_ball == 0 else 0
				player_with_ball = teams[team_with_ball][player_with_ball]
			else:
				player_with_ball = teams[team_with_ball][0]
		
		var player_health := {}
		for player_id in game.players_alive:
			var tank = game.get_tank(player_id)
			player_health[player_id] = tank.health
		
		var operation = RemoteOperations.synchronized_rpc(self, "_setup_new_round", [player_with_ball, player_health])
		if yield(operation, "completed"):
			rpc("_start_new_round")
		else:
			# @todo what can we do if this fails?
			print ("client failed to setup new round!!!!")

func _get_player_start_transforms() -> Array:
	var player_start_transforms := []
	player_start_transforms.resize(players.size())
	for team_id in range(teams.size()):
		for team_player_index in range(teams[team_id].size()):
			var player_id = teams[team_id][team_player_index]
			var player = players[player_id]
			player_start_transforms[player.index - 1] = team_start_transforms[team_id][team_player_index]
	return player_start_transforms

func _game_setup_with_start_positions() -> void:
	game.game_setup(players, map_path, _get_player_start_transforms())

func _setup_new_round(player_with_ball: int, player_health: Dictionary) -> void:
	_game_setup_with_start_positions()
	
	for player_id in game.players_alive:
		var tank = game.get_tank(player_id)
		tank.update_health(player_health[player_id])
	
	if player_with_ball == -1:
		# Restore the football to its starting position.
		football.pass_football(ball_start_position, Vector2.ZERO)
	else:
		grab_football(game.get_tank(player_with_ball).get_path())

remotesync func _start_new_round() -> void:
	round_over = false
	ui_layer.hide_message()
	game.game_start()

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("Wasted!")
	
	if get_tree().is_network_server():
		if OnlineMatch.get_player_by_peer_id(player_id) != null:
			yield(get_tree().create_timer(2.0), "timeout")
			respawn_player(player_id)

func respawn_player(player_id: int) -> void:
	var player = players[player_id]
	var player_start_transforms = _get_player_start_transforms()
	var operation = RemoteOperations.synchronized_rpc(game, "respawn_player", [player_id, player_start_transforms[player.index - 1]])
	if yield(operation, "completed"):
		rpc_id(player_id, "_take_control_of_my_player")
	else:
		# @todo what can we do if this fails?
		print ("player failed to respawn!!!!")

remotesync func _take_control_of_my_player() -> void:
	ui_layer.hide_message()
	
	var player_id = get_tree().get_network_unique_id()
	game.make_player_controlled(player_id)

func _on_countdown_finished() -> void:
	var winners = score.find_highest()
	if winners.size() == 1:
		rpc("show_winner", score.get_name(winners[0]), score.to_dict())
	else:
		instant_death = true
		hud.rpc("show_instant_death_label")

remotesync func show_winner(winner_name: String, host_score: Dictionary) -> void:
	ui_layer.show_message(winner_name + " WINS THIS MATCH!")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	ui_layer.show_screen("RoundScreen", {score = host_score})
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	match_scene.finish_match()
