extends Node

enum Teams {
	RED = 0,
	BLUE = 1,
	MAX,
}

const TEAM_COLORS := [
	Color('#e74c3c'),
	Color('#419fdd'),
]

const TEAM_NAMES := [
	"Red Team",
	"Blue Team",
]

onready var rumble = $Rumble

var title_shown := false
var my_player_position: Vector2
var use_positional_audio := false

var arguments := {}

func _ready() -> void:
	# Parse valid command-line arguments into a dictionary
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
