extends "res://src/components/modes/BaseManager.gd"

const ScoreCounter = preload("res://src/components/modes/ScoreCounter.gd")

onready var countdown_timer := $CanvasLayer/Control/CountdownTimer
onready var instant_death_label := $CanvasLayer/Control/InstantDeathLabel
onready var score_hud := $CanvasLayer/Control/ScoreHUD

var score := ScoreCounter.new()

var instant_death := false
var winners := []

func _do_match_setup() -> void:
	._do_match_setup()
	
	for player_id in players:
		var player = players[player_id]
		score.add_entity(player_id, player.name)
		score_hud.set_player_name(player.index, player.name)
	
	score_hud.set_player_count(OnlineMatch.players.size())
	OnlineMatch.connect("player_left", self, '_on_OnlineMatch_player_left')
	
	game.connect("player_dead", self, "_on_game_player_dead")
	
	countdown_timer.connect("countdown_finished", self, "_on_countdown_finished")

func match_start() -> void:
	.match_start()
	countdown_timer.start_countdown(config['timelimit'] * 60)

func _on_OnlineMatch_player_left(player) -> void:
	score.remove_entity(player.peer_id)
	score_hud.hide_player_score(player.player_index)

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("Wasted!")
	
	if get_tree().is_network_server():
		if killer_id != -1 and not instant_death:
			score.increment_score(killer_id)
			var player_index = players[killer_id].index
			score_hud.rpc("set_score", player_index, score.get_score(killer_id))

		if instant_death:
			rpc_id(player_id, "enable_watch_camera")
			winners.erase(player_id)
			if winners.size() == 1:
				rpc("show_winner", score.get_name(winners[0]), score.get_all_scores())
		elif OnlineMatch.get_player_by_peer_id(player_id) != null:
			yield(get_tree().create_timer(2.0), "timeout")
			respawn_player(player_id)

func respawn_player(player_id: int) -> void:
	if instant_death and not player_id in winners:
		return
	
	var player = OnlineMatch.get_player_by_peer_id(player_id)
	# @todo How to respawn the player now that it takes an object?
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
	winners = score.find_highest()
	
	if winners.size() == 1:
		rpc("show_winner", winners[0], score.get_all_scores())
	else:
		instant_death = true
		
		# Kill all the players that aren't winners.
		var players_alive = game.players_alive.duplicate()
		for player_id in players_alive:
			if not player_id in winners:
				rpc("kill_player", player_id)
		
		rpc("show_instant_death_label")

remotesync func show_instant_death_label() -> void:
	instant_death_label.visible = true

remotesync func kill_player(peer_id: int) -> void:
	if get_tree().get_rpc_sender_id() != 1:
		return
	game.kill_player(peer_id)

remotesync func enable_watch_camera() -> void:
	game.enable_watch_camera()

remotesync func show_winner(winner_name: String, host_players_score: Dictionary) -> void:
	ui_layer.show_message(winner_name + " WINS THIS DEATHMATCH!")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	ui_layer.show_screen("RoundScreen", {players_score = host_players_score})
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	match_scene.finish_match()
