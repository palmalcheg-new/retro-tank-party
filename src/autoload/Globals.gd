extends Node

enum Teams {
	RED = 0,
	BLUE = 1,
}

const TEAM_COLORS := [
	Color('#e74c3c'),
	Color('#419fdd'),
]

onready var rumble = $Rumble

var title_shown := false
var my_player_position: Vector2
var use_positional_audio := false

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
