extends Node2D

onready var game := $Game
onready var ui_layer := $UILayer

func _ready() -> void:
	var faux_multiplayer = WebRTCMultiplayer.new()
	faux_multiplayer.initialize(1)
	get_tree().set_network_peer(faux_multiplayer)
	
	var players = {
		1: "Practice",
	}
	
	game.game_setup(players, "res://mods/core/maps/Battlefield.tscn")
	game.game_start()
	ui_layer.show_back_button()
	
	var songs := ['Track1', 'Track2', 'Track3']
	Music.play(songs[randi() % songs.size()])

func _on_UILayer_back_button() -> void:
	get_tree().change_scene("res://src/main/Title.tscn")

func _on_Game_game_error(message) -> void:
	ui_layer.show_message(message)
	yield(get_tree().create_timer(2.0), "timeout")
	_on_UILayer_back_button()
