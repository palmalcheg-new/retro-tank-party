extends "res://src/components/modes/BaseConfig.gd"

onready var timelimit_field = $Timelimit
onready var teams_label = $TeamsLabel
onready var teams_field = $Teams
onready var weapon_timeout_field = $WeaponTimeout

func _ready() -> void:
	for i in range(1, 11):
		timelimit_field.add_item("OPTION_%s_MINUTE" % i, i)
	timelimit_field.set_value(5, false)

	teams_field.add_item("OPTION_NO", false)
	teams_field.add_item("OPTION_YES", true)
	teams_field.set_value(false, false)

	if OnlineMatch.get_active_player_count() < 3:
		teams_label.visible = false
		teams_field.visible = false

	weapon_timeout_field.add_item("OPTION_NEVER", 0)
	for i in range(10, 70, 10):
		weapon_timeout_field.add_item("OPTION_%s_SECOND" % i, int(i * 30))
	weapon_timeout_field.set_value(int(20 * 30), false)

func set_disabled(_disabled: bool) -> void:
	disabled = _disabled
	timelimit_field.disabled = disabled
	teams_field.disabled = disabled
	weapon_timeout_field.disabled = disabled

func get_config_values() -> Dictionary:
	return {
		timelimit = timelimit_field.value,
		teams = teams_field.value,
		weapon_timeout = weapon_timeout_field.value,
	}

func set_config_values(values: Dictionary) -> void:
	timelimit_field.value = values['timelimit']
	teams_field.value = values['teams']
	weapon_timeout_field.value = values['weapon_timeout']

func _on_OptionSwitcher_item_selected(_value, _index) -> void:
	emit_signal("changed")
