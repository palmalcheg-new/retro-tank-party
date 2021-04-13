extends "res://src/modes/BaseConfig.gd"

onready var timelimit_field = $Timelimit

func _ready() -> void:
	for i in range(1, 11):
		timelimit_field.add_item("%s min" % i, i)
	timelimit_field.value = 5

func set_disabled(_disabled: bool) -> void:
	disabled = _disabled
	timelimit_field.disabled = disabled

func get_config_values() -> Dictionary:
	return {
		timelimit = timelimit_field.value,
	}

func set_config_values(values: Dictionary) -> void:
	timelimit_field.value = values['timelimit']

func _on_Timelimit_item_selected(_value, _index) -> void:
	emit_signal("changed")
