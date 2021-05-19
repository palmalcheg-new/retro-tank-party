extends "res://src/components/modes/BaseManager.gd"

const FootballWeaponType = preload("res://mods/core/weapons/football.tres")
const FootballScene = preload("res://mods/core/modes/football/Football.tscn")

const TANK_SIZE := Vector2(128, 128)

onready var hud := $CanvasLayer/TimedMatchHUD

var football

var instant_death := false
var winners := []

var map_rect: Rect2
var ball_start_position: Vector2

func _get_synchronized_rpc_methods() -> Array:
	return ['_setup_new_round']

func _do_match_setup() -> void:
	._do_match_setup()
	
	map_rect = game.map.get_map_rect()
	
	if game.map.has_node('BallStartPosition'):
		ball_start_position = game.map.get_node('BallStartPosition').global_position
	else:
		
		ball_start_position = map_rect.position + (map_rect.size / 2.0)
	
	football = FootballScene.instance()
	football.name = 'Football'
	game.add_child(football)
	football.setup_football(self, map_rect)
	football.global_position = ball_start_position
	
	hud.score.set_entity_count(score.entities.size())
	for team_id in score.entities:
		hud.score.set_entity_name(team_id + 1, score.entities[team_id].name)
	
	OnlineMatch.connect("player_left", self, '_on_OnlineMatch_player_left')
	
	game.connect("player_dead", self, "_on_game_player_dead")
	
	hud.countdown_timer.connect("countdown_finished", self, "_on_countdown_finished")

func match_start() -> void:
	.match_start()
	hud.countdown_timer.start_countdown(config['timelimit'] * 60)

func match_stop() -> void:
	.match_stop()

remotesync func grab_football(tank_path: NodePath) -> void:
	var tank = get_node(tank_path)
	if tank:
		# @todo Ensure that whoever was holding the ball before has it removed.
		
		var previous_weapon_type = tank.weapon_type
		tank.set_weapon_type(FootballWeaponType)
		tank.weapon.previous_weapon_type = previous_weapon_type
		football.mark_as_held(tank)
	else:
		# @todo Can we do something smart here?
		pass

remotesync func pass_football(_position: Vector2, _rotation: float) -> void:
	football.pass_football(_position, _rotation)

remotesync func start_new_round(message: String, team_with_ball: int) -> void:
	ui_layer.show_message(message)
	
	if get_tree().is_network_server():
		yield(get_tree().create_timer(2.0), "timeout")
		
		# @todo Get the specific player with the ball.
		var player_with_ball = -1
		var operation = RemoteOperations.synchronized_rpc(self, "_setup_new_round", [player_with_ball])
		if yield(operation, "completed"):
			rpc("_start_new_round")
		else:
			# @todo what can we do if this fails?
			print ("client failed to setup new round!!!!")

func _setup_new_round(player_with_ball: int) -> void:
	get_tree().paused = true
	
	# @todo Give the ball to the right player
	football.global_position = ball_start_position
	
	# @todo Restore the players to their starting positions

remotesync func _start_new_round() -> void:
	ui_layer.hide_message()
	get_tree().paused = false

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("Wasted!")
	
	if get_tree().is_network_server():
		if OnlineMatch.get_player_by_peer_id(player_id) != null:
			yield(get_tree().create_timer(2.0), "timeout")
			respawn_player(player_id)

func respawn_player(player_id: int) -> void:
	var player = OnlineMatch.get_player_by_peer_id(player_id)
	var operation = RemoteOperations.synchronized_rpc(game, "respawn_player", [player_id])
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
