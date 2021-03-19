extends Node2D

onready var game := $Game
onready var ui_layer := $UILayer

var match_info: Dictionary

func scene_setup(operation: RemoteOperations.ClientOperation, info: Dictionary) -> void:
	match_info = info
	
	game.game_setup(OnlineMatch.get_player_names_by_peer_id())
	operation.mark_done()
	
	ui_layer.show_back_button()

func scene_start() -> void:
	game.rpc("game_start")

func restart() -> void:
	var operation = RemoteOperations.synchronized_rpc(game, "game_setup", [OnlineMatch.get_player_names_by_peer_id()])
	if yield(operation, "completed"):
		game.rpc("game_start")
	else:
		quit_match()

func quit_match() -> void:
	OnlineMatch.leave()
	get_tree().change_scene("res://src/Main.tscn")

func _on_UILayer_back_button() -> void:
	game.game_stop()
	
	# TODO: allow the host to go back to match setup rather than leaving.
	quit_match()

