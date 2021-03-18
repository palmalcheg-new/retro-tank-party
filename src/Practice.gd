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
	
	game.game_start(players)
	ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	get_tree().change_scene("res://src/TitleScreen.tscn")
