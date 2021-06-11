extends "res://src/components/modes/BaseManager.gd"

const Tank = preload("res://src/objects/Tank.gd")

const TANK_SIZE := Vector2(128, 128)

onready var hud := $CanvasLayer/TimedMatchHUD
onready var weapon_warning_timer := $WeaponWarningTimer
onready var weapon_timeout_timer := $WeaponTimeoutTimer

var instant_death := false
var winners := []
var game_over := false

var map_rect: Rect2

func _do_match_setup() -> void:
	# Needs to happen before players are created.
	game.connect("make_player_controlled", self, "_on_game_make_player_controlled")
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
	
	if config.get('weapon_timeout', 0) != 0:
		weapon_timeout_timer.wait_time = config['weapon_timeout']
		weapon_warning_timer.wait_time = config['weapon_timeout'] - 2.0
	
	OnlineMatch.connect("player_left", self, '_on_OnlineMatch_player_left')
	
	game.connect("player_dead", self, "_on_game_player_dead")
	
	hud.countdown_timer.connect("countdown_finished", self, "_on_countdown_finished")

func match_start() -> void:
	.match_start()
	hud.countdown_timer.start_countdown(config['timelimit'] * 60)

	map_rect = game.map.get_map_rect()

func match_stop() -> void:
	.match_stop()

func _on_OnlineMatch_player_left(online_player) -> void:
	if not use_teams:
		score.remove_entity(online_player.peer_id)
		hud.score.hide_entity_score(players[online_player.peer_id].index)

func _on_game_make_player_controlled(tank, player_id) -> void:
	tank.connect("weapon_type_changed", self, "_on_tank_weapon_type_changed")

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("Wasted!")
	
	if get_tree().is_network_server() and not game_over:
		if killer_id != -1 and not game_over:
			if use_teams:
				var killer_team = get_player_team(killer_id)
				var player_team = get_player_team(player_id)
				if killer_team != -1:
					if killer_team != player_team:
						score.increment_score(killer_team)
					else:
						score.decrement_score(killer_team)
					hud.score.rpc("set_score", killer_team + 1, score.get_score(killer_team))
			else:
				if killer_id != player_id:
					score.increment_score(killer_id)
				else:
					score.decrement_score(killer_id)
				var player_index = players[killer_id].index
				hud.score.rpc("set_score", player_index, score.get_score(killer_id))

		if instant_death:
			rpc_id(player_id, "enable_watch_camera")
			
			winners = score.find_highest()
			if winners.size() == 1:
				game_over = true
				rpc("show_winner", score.get_name(winners[0]), score.to_dict())
		elif OnlineMatch.get_player_by_peer_id(player_id) != null:
			yield(get_tree().create_timer(2.0), "timeout")
			respawn_player(player_id)

func respawn_player(player_id: int) -> void:
	if instant_death and not player_id in winners:
		return
	
	var detector = game.create_free_space_detector()
	detector.connect("free_space_found", self, "_on_respawn_position_found", [player_id, detector])
	detector.start_detecting(map_rect, TANK_SIZE)

func _on_respawn_position_found(spawn_position, player_id, detector) -> void:
	detector.queue_free()
	
	var spawn_transform = Transform2D(deg2rad(randi() % 360), spawn_position)
	var operation = RemoteOperations.synchronized_rpc(game, "respawn_player", [player_id, spawn_transform])
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
	winners = score.find_highest()
	
	if winners.size() == 1:
		game_over = true
		rpc("show_winner", score.get_name(winners[0]), score.to_dict())
	else:
		instant_death = true
		
		if not use_teams:
			# Kill all the players that aren't winners.
			var players_alive = game.players_alive.duplicate()
			for player_id in players_alive:
				if not player_id in winners:
					rpc("kill_player", player_id)
		
		hud.rpc("show_instant_death_label")

remotesync func kill_player(peer_id: int) -> void:
	if get_tree().get_rpc_sender_id() != 1:
		return
	game.kill_player(peer_id)

remotesync func enable_watch_camera() -> void:
	game.enable_watch_camera()

remotesync func show_winner(winner_name: String, host_score: Dictionary) -> void:
	ui_layer.show_message(winner_name + " WINS THIS DEATHMATCH!")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	ui_layer.show_screen("RoundScreen", {score = host_score})
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	match_scene.finish_match()

func _on_tank_weapon_type_changed(weapon_type: WeaponType) -> void:
	if config.get('weapon_timeout', 0) == 0:
		return
	if weapon_type != Tank.BaseWeaponType:
		weapon_warning_timer.start()
		weapon_timeout_timer.start()

func _on_WeaponWarningTimer_timeout() -> void:
	game.hud.weapon_label.blinking = true

func _on_WeaponTimeoutTimer_timeout() -> void:
	game.get_my_tank().set_weapon_type(Tank.BaseWeaponType)
