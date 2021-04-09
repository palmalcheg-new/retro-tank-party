extends Node

var player_joy_id := 0

var rumble := 0.0
var rumble_decay := 0.8
var rumble_variation := 0.2
var rumble_duration := 0.15

func _physics_process(delta: float) -> void:
	if rumble > 0.0:
		rumble = max(rumble - rumble_decay * delta, 0)
		if rumble > 0.0:
			_do_rumble()

func _do_rumble() -> void:
	var strong_magnitude = min(1.0, rumble + (randf() * rumble_variation))
	var weak_magnitude = min(1.0, rumble + (randf() * rumble_variation))
	Input.start_joy_vibration(player_joy_id, weak_magnitude, strong_magnitude, rumble_duration)

func add_rumble(amount: float) -> void:
	rumble = min(1.0, rumble + amount)
	_do_rumble()
