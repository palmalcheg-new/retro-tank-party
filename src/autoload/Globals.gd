extends Node

var title_shown := false
var my_player_position: Vector2

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
