extends AudioStreamPlayer
class_name MyAudioStreamPlayer2D

# This is a simplied implementation of AudioStreamPlayer2D, that dampes the
# volume based on distance to the player (rather than the center of the screen).
# This can't do positional panning, because we can only set panning on a bus,
# not in an AudioStreamPlayer.
#
# This PR is the real solution:
#
#   https://github.com/godotengine/godot/pull/44844

export (float) var max_distance := 2000.0
export (float) var attenuation := 1.0

onready var _original_volume_db: float = volume_db

func _ready() -> void:
	adjust_volume()

func _physics_process(delta: float) -> void:
	adjust_volume()

func adjust_volume() -> void:
	var parent = get_parent()
	
	var linear_volume: float = 0.0
	
	# It's too far away, we can't hear it.
	var distance = Globals.my_player_position.distance_to(parent.global_position)
	if distance < max_distance:
		linear_volume = pow(1.0 - (distance / max_distance), attenuation) * db2linear(_original_volume_db)
	
	volume_db = linear2db(linear_volume)

