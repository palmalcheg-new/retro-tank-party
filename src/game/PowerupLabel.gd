extends Label

onready var blink_timer = $BlinkTimer
onready var default_modulate_a = modulate.a

var blinking := false setget set_blinking

func set_blinking(_blinking: bool) -> void:
	if blink_timer == null:
		yield(self, "ready")
	if blinking != _blinking:
		blinking = _blinking
		if blinking:
			blink_timer.start()
		else:
			blink_timer.stop()
			modulate.a = default_modulate_a

func _on_BlinkTimer_timeout() -> void:
	# We blinking with modulate, because we still want it to take up space.
	modulate.a = default_modulate_a if modulate.a == 0.0 else 0.0
