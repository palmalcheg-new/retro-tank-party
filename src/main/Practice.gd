extends Node2D

const Game = preload("res://src/Game.gd")

onready var game := $Game
onready var respawn_timer := $RespawnTimer
onready var ui_layer := $UILayer

func _ready() -> void:
	var faux_multiplayer = WebRTCMultiplayer.new()
	faux_multiplayer.initialize(1)
	get_tree().set_network_peer(faux_multiplayer)
	
	var players = {
		1: Game.Player.new(1, "Practice", 1),
	}
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	game.game_setup(players, "res://mods/core/maps/Battlefield.tscn", rng.seed)
	SyncManager.start()
	yield(SyncManager, "sync_started")
	game.game_start()
	
	ui_layer.show_back_button()
	
	var songs := ['Track1', 'Track2', 'Track3']
	Music.play(songs[randi() % songs.size()])
	
	if OS.has_feature('editor'):
		ui_layer.add_screen(load("res://src/ui/DebugScreen.tscn").instance())

func _unhandled_input(event: InputEvent) -> void:
	if OS.has_feature('editor') and event.is_action_pressed('special_debug'):
		var my_tank = game.get_my_tank()
		if my_tank:
			ui_layer.show_screen("DebugScreen", {tank = my_tank})

func _on_UILayer_back_button() -> void:
	if ui_layer.current_screen_name == 'DebugScreen':
		ui_layer.hide_screen()
	else:
		SyncManager.stop()
		get_tree().change_scene("res://src/main/Title.tscn")

func _on_Game_game_error(message) -> void:
	ui_layer.show_message(message)
	yield(get_tree().create_timer(2.0), "timeout")
	_on_UILayer_back_button()

func _on_Game_player_dead(player_id, killer_id) -> void:
	respawn_timer.start()

func _on_RespawnTimer_timeout() -> void:
	SyncManager.stop()
	game.game_reset()
	SyncManager.start()
	yield(SyncManager, "sync_started")
	game.game_start()
