extends "res://src/ui/Screen.gd"

onready var ready_button = $ReadyButton

signal ready_pressed ()

func _show_screen(info: Dictionary = {}) -> void:
	ready_button.focus.grab_without_sound()

func _on_ReadyButton_pressed() -> void:
	emit_signal("ready_pressed")

func disable_screen() -> void:
	ready_button.disabled = true
