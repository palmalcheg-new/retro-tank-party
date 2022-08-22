extends "res://src/components/modes/BaseConfig.gd"

onready var points_to_win_field = $PointsToWin
onready var teams_label = $TeamsLabel
onready var teams_field = $Teams

func _ready() -> void:
	for i in range(1, 10):
		points_to_win_field.add_item(str(i), i)
	points_to_win_field.value = 5

	teams_field.add_item("OPTION_NO", false)
	teams_field.add_item("OPTION_YES", true)
	teams_field.set_value(false, false)

	if OnlineMatch.get_active_player_count() < 3:
		teams_label.visible = false
		teams_field.visible = false

func _set_disabled(_disabled: bool) -> void:
	disabled = _disabled
	points_to_win_field.disabled = disabled
	teams_field.disabled = disabled

func get_config_values() -> Dictionary:
	return {
		points_to_win = points_to_win_field.value,
		teams = teams_field.value,
	}

func set_config_values(values: Dictionary) -> void:
	points_to_win_field.value = values['points_to_win']
	teams_field.value = values['teams']

func _on_OptionSwitcher_item_selected(_value, _index) -> void:
	emit_signal("changed")
