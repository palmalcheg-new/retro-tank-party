extends Control

signal changed ()

var disabled := false setget set_disabled

func set_disabled(_disabled: bool) -> void:
	disabled = _disabled
	_set_disabled(_disabled)

#
# For child classes to override:
#

func _set_disabled(_disabled: bool) -> void:
	pass

func get_config_values() -> Dictionary:
	return {}

func set_config_values(values: Dictionary) -> void:
	pass
