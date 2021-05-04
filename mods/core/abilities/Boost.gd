extends "res://src/components/abilities/BaseAbility.gd"

var timer: Timer

func attach_ability() -> void:
	timer = Timer.new()
	timer.name = 'BoostTimer'
	timer.wait_time = 0.25
	timer.one_shot = true
	timer.connect("timeout", self, "_on_timer_timeout")
	tank.add_child(timer)

func detach_ability() -> void:
	tank.remove_child(timer)

func use_ability() -> void:
	if charges > 0:
		charges -= 1
		tank.speed = 1600
		if Input.is_action_pressed("player1_backward"):
			tank.set_forced_input_vector(Vector2(-1.0, 0.0))
		else:
			tank.set_forced_input_vector(Vector2(1.0, 0.0))
		timer.start()

func _on_timer_timeout() -> void:
	tank.speed = tank.DEFAULT_SPEED
	tank.clear_forced_input_vector()
	if charges == 0:
		tank.set_ability_type(null)
