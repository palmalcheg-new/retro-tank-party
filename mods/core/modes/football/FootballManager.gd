extends "res://src/components/modes/BaseManager.gd"

const TANK_SIZE := Vector2(128, 128)

onready var hud := $CanvasLayer/TimedMatchHUD

var instant_death := false
var winners := []

func _do_match_setup() -> void:
	._do_match_setup()
	
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
