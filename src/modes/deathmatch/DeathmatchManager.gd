extends "res://src/modes/base/BaseManager.gd"

onready var countdown_timer := $CanvasLayer/Control/CountdownTimer
onready var instant_death_label := $CanvasLayer/Control/InstantDeathLabel

var players_score := {}

var instant_death := false
var winners := []

func _do_match_setup() -> void:
	._do_match_setup()
	
	game.connect("player_dead", self, "_on_game_player_dead")
	
	countdown_timer.connect("countdown_finished", self, "_on_countdown_finished")

func match_start() -> void:
	.match_start()
	countdown_timer.start_countdown(config['timelimit'] * 60)

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("Wasted!")
		game.enable_watch_camera(true)
	
	if get_tree().is_network_server():
		if killer_id != -1:
			if not players_score.has(killer_id):
				players_score[killer_id] = 1
			else:
				players_score[killer_id] += 1

		if instant_death:
			winners.erase(player_id)
			if winners.size() == 1:
				rpc("show_winner", winners[0], players_score)
		elif OnlineMatch.get_player_by_peer_id(player_id) != null:
			yield(get_tree().create_timer(2.0), "timeout")
			respawn_player(player_id)

func respawn_player(player_id: int) -> void:
	if instant_death and not player_id in winners:
		return
	
	var player = OnlineMatch.get_player_by_peer_id(player_id)
	var operation = RemoteOperations.synchronized_rpc(game, "respawn_player", [player_id, player.username])
	if yield(operation, "completed"):
		rpc_id(player_id, "_take_control_of_my_player")
	else:
		# @todo what can we do if this fails?
		print ("player failed to respawn!!!!")

remotesync func _take_control_of_my_player() -> void:
	ui_layer.hide_message()
	game.enable_watch_camera(false)
	
	var player_id = get_tree().get_network_unique_id()
	game.make_player_controlled(player_id)

func _on_countdown_finished() -> void:
	var max_score = players_score.values().max()
	for player_id in players_score:
		var score = players_score[player_id]
		if score == max_score:
			winners.append(player_id)
	
	if winners.size() == 1:
		rpc("show_winner", winners[0], players_score)
	else:
		instant_death = true
		
		# Kill all the players that aren't winners.
		for player_id in game.players_alive:
			if not player_id in winners:
				rpc("kill_player", player_id)
		
		instant_death_label.visible = true

remotesync func kill_player(peer_id: int) -> void:
	if get_tree().get_rpc_sender_id() != 1:
		return
	game.kill_player(peer_id)

remotesync func show_winner(peer_id: int, host_players_score: Dictionary) -> void:
	var name = OnlineMatch.get_player_by_peer_id(peer_id).username
	ui_layer.show_message(name + " WINS THIS DEATHMATCH!")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	ui_layer.show_screen("RoundScreen", {players_score = host_players_score})
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	match_scene.finish_match()
