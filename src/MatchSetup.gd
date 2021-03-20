extends Node2D

onready var ui_layer = $UILayer
onready var mode_screen = $UILayer/Screens/ModeScreen

func _ready() -> void:
	OnlineMatch.connect("error", self, "_on_OnlineMatch_error")
	OnlineMatch.connect("disconnected", self, "_on_OnlineMatch_disconnected")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	
	# Make the host in charge of this scene.
	set_network_master(1)
	if get_tree().is_network_server():
		ui_layer.show_message("You're the host! How you wanna do this tank party?")
	else:
		ui_layer.show_cover()
		ui_layer.show_message("The host is configuring the match...")
		for screen in ui_layer.get_screens():
			if screen.has_method('disable_screen'):
				screen.disable_screen()
	
	ui_layer.show_screen("ModeScreen")
	ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	var current_screen = ui_layer.current_screen_name
	if not is_network_master() or current_screen == 'ModeScreen':
		OnlineMatch.leave()
		get_tree().change_scene("res://src/SessionSetup.tscn")
	elif current_screen == 'ReadyScreen':
		ui_layer.show_screen('ModeScreen')

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
	get_tree().change_scene("res://src/SessionSetup.tscn")

func _on_OnlineMatch_disconnected():
	#_on_OnlineMatch_error("Disconnected from host")
	_on_OnlineMatch_error('')

func _on_OnlineMatch_player_left(player) -> void:
	if OnlineMatch.players.size() < 2:
		_on_OnlineMatch_error(player.username + " has left - not enough players!")
	else:
		ui_layer.show_message(player.username + " has left")
