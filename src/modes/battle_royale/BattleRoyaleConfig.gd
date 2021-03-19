extends GridContainer

onready var points_to_win_field = $PointsToWin

func _ready() -> void:
	for i in range(1, 10):
		points_to_win_field.add_item(str(i), i)
	points_to_win_field.value = 5

func get_config_values() -> Dictionary:
	return {
		points_to_win = points_to_win_field.value,
	}
