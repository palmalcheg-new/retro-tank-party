extends Node2D

onready var online_button = $CanvasLayer/Control/HBoxContainer/OnlineButton
onready var ui_layer = $UILayer

func _ready() -> void:
	online_button.focus.grab_without_sound()
	
	yield(get_tree().create_timer(0.5), "timeout")
	Music.play("Title")

func _on_LocalButton_pressed() -> void:
	get_tree().change_scene("res://src/main/Practice.tscn")

func _on_OnlineButton_pressed() -> void:
	get_tree().change_scene("res://src/main/SessionSetup.tscn")

func _on_SettingsButton_pressed() -> void:
	ui_layer.show_screen("SettingsScreen")
	ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	ui_layer.hide_all()
	online_button.focus.grab_without_sound()
