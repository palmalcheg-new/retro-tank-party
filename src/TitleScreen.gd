extends Node2D

onready var ui_layer = $UILayer

func _ready() -> void:
	$CanvasLayer/Control/HBoxContainer/OnlineButton.grab_focus()

func _on_LocalButton_pressed() -> void:
	get_tree().change_scene("res://src/Practice.tscn")

func _on_OnlineButton_pressed() -> void:
	get_tree().change_scene("res://src/Main.tscn")

func _on_SettingsButton_pressed() -> void:
	ui_layer.show_screen("SettingsScreen")
	ui_layer.show_back_button()

func _on_UILayer_back_button() -> void:
	ui_layer.hide_all()
