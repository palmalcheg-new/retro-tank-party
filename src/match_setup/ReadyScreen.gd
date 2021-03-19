extends Control

signal ready_pressed ()

func _on_ReadyButton_pressed() -> void:
	emit_signal("ready_pressed")
