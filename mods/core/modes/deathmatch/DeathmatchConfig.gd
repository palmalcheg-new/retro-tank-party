extends "res://src/components/modes/BaseConfig.gd"

onready var timelimit_field = $Timelimit
onready var teams_label = $TeamsLabel
onready var teams_field = $Teams

func _ready() -> void:
	for i in range(1, 11):
		timelimit_field.add_item("%s min" % i, i)
	timelimit_field.set_value(5, false)
	
	teams_field.add_item("No", false)
	teams_field.add_item("Yes", true)
	teams_field.set_value(false, false)
	
	#if OnlineMatch.players.size() < 3:
	#	teams_label.visible = false
	#	teams_field.visible = false

func set_disabled(_disabled: bool) -> void:
	disabled = _disabled
	timelimit_field.disabled = disabled
	teams_field.disabled = disabled

func get_config_values() -> Dictionary:
	return {
		timelimit = timelimit_field.value,
		teams = teams_field.value,
	}

func set_config_values(values: Dictionary) -> void:
	timelimit_field.value = values['timelimit']
	teams_field.value = values['teams']

func _on_OptionSwitcher_item_selected(_value, _index) -> void:
	emit_signal("changed")
