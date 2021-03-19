extends Node2D

onready var ui_layer = $UILayer
onready var mode_screen = $UILayer/Screens/ModeScreen

func _ready() -> void:
	ui_layer.show_screen("ModeScreen")
	ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	# @todo: this should actually allow us to backwards in the screen stack
	OnlineMatch.leave()
	get_tree().change_scene("res://src/SessionSetup.tscn")

func _on_ReadyScreen_ready_pressed() -> void:
	var match_info = {
		mode_path = mode_screen.get_mode_path(),
		config = mode_screen.get_config_values(),
	}
	RemoteOperations.change_scene("res://src/Match.tscn", match_info)
