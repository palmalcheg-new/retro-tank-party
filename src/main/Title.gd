extends Node2D

onready var ui_layer = $UILayer

func _ready() -> void:
	ui_layer.show_screen("MenuScreen")
	
	yield(get_tree().create_timer(0.5), "timeout")
	Music.play("Title")

func _on_UILayer_back_button() -> void:
	ui_layer.show_screen("MenuScreen")

