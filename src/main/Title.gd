extends Node2D

onready var ui_layer = $UILayer

func _ready() -> void:
	if not Globals.title_shown:
		ui_layer.show_screen("StartScreen")
		Globals.title_shown = true
	else:
		ui_layer.show_screen("MenuScreen")
	
	yield(get_tree().create_timer(0.5), "timeout")
	Music.play("Title")

func _on_UILayer_back_button() -> void:
	ui_layer.show_screen("MenuScreen")

func _on_UILayer_change_screen(name, screen) -> void:
	if name in ['StartScreen', 'MenuScreen']:
		ui_layer.hide_back_button()
	else:
		ui_layer.show_back_button()
