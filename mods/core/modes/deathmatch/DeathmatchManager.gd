extends "res://src/components/modes/BaseManager.gd"

const PlayerManager := preload("res://mods/core/modes/deathmatch/DeathmatchPlayerManager.tscn")

const TANK_DIMENSION = 128 * SGFixed.ONE

onready var hud := $CanvasLayer/TimedMatchHUD
onready var player_managers_node := $PlayerManagers
onready var rng := $RandomNumberGenerator
onready var you_lose_timer := $YouLoseTimer
onready var show_winner_timer := $ShowWinnerTimer
onready var show_score_timer := $ShowScoreTimer
onready var match_finished_timer := $MatchFinishedTimer

var instant_death := false
var winners := []
var game_over := false

var player_managers := {}
var detector

func _do_match_setup() -> void:
	# Needs to happen before players are created.
	for player_id in players:
		var player_manager = PlayerManager.instance()
		player_manager.name = str(player_id)
		player_managers_node.add_child(player_manager)
		player_manager.setup_player_manager(players[player_id], config, game)
		player_manager.connect("respawn_player", self, "_on_player_manager_respawn_player")
		if player_id == get_tree().get_network_unique_id():
			player_manager.connect("weapon_warning", self, "_on_player_manager_weapon_warning")
			player_manager.connect("weapon_timeout", self, "_on_player_manager_weapon_timeout")
		player_managers[player_id] = player_manager
	game.connect("player_spawned", self, "_on_game_player_spawned")
	
	._do_match_setup()
	
	if use_teams:
		hud.score.set_entity_count(score.entities.size())
		for team_id in score.entities:
			hud.score.set_entity_name(team_id + 1, score.entities[team_id].name)
	else:
		hud.score.set_entity_count(OnlineMatch.players.size())
		for player_id in players:
			var player = players[player_id]
			hud.score.set_entity_name(player.index, player.name)
	
	detector = game.create_free_space_detector(
		game.map.get_map_fixed_rect(),
		SGFixed.vector2(TANK_DIMENSION, TANK_DIMENSION),
		rng)
	
	OnlineMatch.connect("player_left", self, '_on_OnlineMatch_player_left')
	
	game.connect("player_dead", self, "_on_game_player_dead")
	
	hud.countdown_timer.start_countdown(config['timelimit'] * 60)
	hud.countdown_timer.connect("countdown_finished", self, "_on_countdown_finished")

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['instant_death'] = instant_death
	state['winners'] = winners.duplicate()
	state['game_over'] = game_over
	return state

func _load_state(state: Dictionary) -> void:
	._load_state(state)
	instant_death = state['instant_death']
	winners = state['winners'].duplicate()
	game_over = state['game_over']

func _on_OnlineMatch_player_left(online_player) -> void:
	if not use_teams:
		score.remove_entity(online_player.peer_id)
		hud.score.hide_entity_score(players[online_player.peer_id].index)
	
	var player_manager = player_managers[online_player.peer_id]
	player_manager.shutdown_player_manager()
	player_managers_node.remove_child(player_manager)
	player_manager.queue_free()

func _on_game_player_spawned(tank) -> void:
	var player_manager = player_managers[tank.get_network_master()]
	player_manager.set_player_tank(tank)

func _on_player_manager_weapon_warning() -> void:
	game.hud.weapon_label.blinking = true

func _on_player_manager_weapon_timeout() -> void:
	pass

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		you_lose_timer.start()
	
	if not game_over:
		if killer_id != -1:
			if use_teams:
				var killer_team = get_player_team(killer_id)
				var player_team = get_player_team(player_id)
				if killer_team != -1:
					if killer_team != player_team:
						score.increment_score(killer_team)
					else:
						score.decrement_score(killer_team)
					hud.score.set_score(killer_team + 1, score.get_score(killer_team))
			else:
				if killer_id != player_id:
					score.increment_score(killer_id)
				else:
					score.decrement_score(killer_id)
				var player_index = players[killer_id].index
				hud.score.set_score(player_index, score.get_score(killer_id))
	
		if instant_death:
			winners = score.find_highest()
			if winners.size() == 1:
				game_over = true
				show_winner_timer.start()
		elif player_managers.has(player_id):
			var player_manager = player_managers[player_id]
			player_manager.start_respawn_timer()

func _on_player_manager_respawn_player(player_id: int) -> void:
	if instant_death and not player_id in winners:
		return
	
	var spawn_position = detector.detect_free_space()
	var spawn_transform = SGFixedTransform2D.new()
	spawn_transform = spawn_transform.rotated(rng.randi() % SGFixed.TAU)
	spawn_transform.set_origin(spawn_position)
	
	game.respawn_player(player_id, spawn_transform)
	
	if player_id == get_tree().get_network_unique_id():
		ui_layer.hide_message()

func _on_countdown_finished() -> void:
	winners = score.find_highest()
	
	if winners.size() == 1:
		game_over = true
		show_winner_timer.start()
	else:
		instant_death = true
		
		if not use_teams:
			# Kill all the players that aren't winners.
			var players_alive = game.players_alive.duplicate()
			for player_id in players_alive:
				if not player_id in winners:
					game.kill_player(player_id)
		
		hud.show_instant_death_label()

func _on_YouLoseTimer_timeout() -> void:
	if not game_over:
		ui_layer.show_message("Wasted!")
	if instant_death:
		game.enable_watch_camera()

func _on_ShowWinnerTimer_timeout() -> void:
	var winner_name = score.get_name(winners[0])
	ui_layer.show_message(winner_name + " WINS THIS DEATHMATCH!")
	show_score_timer.start()

func _on_ShowScoreTimer_timeout() -> void:
	ui_layer.show_screen("RoundScreen", {score = score.to_dict()})
	match_finished_timer.start()

func _on_MatchFinishedTimer_timeout() -> void:
	match_scene.finish_match()

