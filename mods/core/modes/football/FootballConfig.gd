extends "res://src/components/modes/BaseConfig.gd"

onready var timelimit_field = $Timelimit

func _ready() -> void:
	for i in range(1, 11):
		timelimit_field.add_item("OPTION_%s_MINUTE" % i, i)
	timelimit_field.set_value(5, false)

func set_disabled(_disabled: bool) -> void:
	disabled = _disabled
	timelimit_field.disabled = disabled

func get_config_values() -> Dictionary:
	return {
		timelimit = timelimit_field.value,
		teams = true,
	}

func set_config_values(values: Dictionary) -> void:
	timelimit_field.value = values['timelimit']

func _on_OptionSwitcher_item_selected(_value, _index) -> void:
	emit_signal("changed")
