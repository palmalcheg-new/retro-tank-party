extends "res://src/modes/base/BaseConfig.gd"

onready var points_to_win_field = $PointsToWin

func _ready() -> void:
	for i in range(1, 10):
		points_to_win_field.add_item(str(i), i)
	points_to_win_field.value = 5

func _set_disabled(_disabled: bool) -> void:
	points_to_win_field.disabled = _disabled

func get_config_values() -> Dictionary:
	return {
		points_to_win = points_to_win_field.value,
	}

func set_config_values(values: Dictionary) -> void:
	points_to_win_field.value = values['points_to_win']

func _on_OptionSwitcher_item_selected(_value, _index) -> void:
	emit_signal("changed")
