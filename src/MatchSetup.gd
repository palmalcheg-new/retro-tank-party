extends Node2D

onready var ui_layer = $UILayer
onready var mode_screen = $UILayer/Screens/ModeScreen

func _ready() -> void:
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	
	ui_layer.show_screen("ModeScreen")
	ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	# @todo: this should actually allow us to backwards in the screen stack
	OnlineMatch.leave()
	get_tree().change_scene("res://src/SessionSetup.tscn")

func _on_ReadyScreen_ready_pressed() -> void:
	var match_info = {
		manager_path = mode_screen.get_mode().manager_scene,
		config = mode_screen.get_config_values(),
	}
	RemoteOperations.change_scene("res://src/Match.tscn", match_info)

func _on_OnlineMatch_error(message: String):
	if message != '':
		ui_layer.show_message(message)
	ui_layer.hide_screen()
	yield(get_tree().create_timer(2.0), "timeout")
	get_tree().change_scene("res://src/Match.tscn")

func _on_OnlineMatch_disconnected():
	#_on_OnlineMatch_error("Disconnected from host")
	_on_OnlineMatch_error('')

func _on_OnlineMatch_player_left(player) -> void:
	ui_layer.show_message(player.username + " has left")
