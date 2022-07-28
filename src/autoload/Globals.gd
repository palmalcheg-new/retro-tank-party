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

onready var art = $Art
onready var rumble = $Rumble

var title_shown := false
var arguments := {}

const EXTRA_FONTS := [
#	'silver.tres',
#	'silver_credits.tres',
#	'silver_mini.tres',
#	'silver_small.tres',
	'monogram.tres',
	'monogram_credits.tres',
	'monogram_mini.tres',
	'monogram_small.tres',
]
var extra_fonts := {}

func _ready() -> void:
	# Parse valid command-line arguments into a dictionary
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			arguments[argument.lstrip("--")] = true

	_load_extra_fonts_hack()

# There is a bug with loading translation remapped resources, when the
# resources are converted to binary for export. This workes around that
# by ensuring the resources are already loaded.
func _load_extra_fonts_hack() -> void:
	for font in EXTRA_FONTS:
		extra_fonts[font] = load("res://assets/fonts/%s" % font)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
