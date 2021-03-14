extends "res://main/Screen.gd"

signal play_local
signal play_online

func _show_screen(info: Dictionary = {}) -> void:
	$HBoxContainer/OnlineButton.grab_focus()

func _on_LocalButton_pressed() -> void:
	emit_signal("play_local")

func _on_OnlineButton_pressed() -> void:
	emit_signal("play_online")

func _on_SettingsButton_pressed() -> void:
	ui_layer.show_screen("SettingsScreen")
