extends GridContainer

onready var timelimit_field = $Timelimit

func _ready() -> void:
	for i in range(1, 11):
		timelimit_field.add_item("%s min" % i, i)
	timelimit_field.value = 5

func get_config_values() -> Dictionary:
	return {
		timelimit = timelimit_field.value,
	}
