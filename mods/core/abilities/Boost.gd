extends "res://src/components/abilities/BaseAbility.gd"

const ShadowTankSpawner = preload("res://mods/core/abilities/ShadowTankSpawner.tscn")

var timer: Timer
var shadow_tank_spawner: Node2D

func attach_ability() -> void:
	timer = Timer.new()
	timer.name = 'BoostTimer'
	timer.wait_time = 0.25
	timer.one_shot = true
	timer.connect("timeout", self, "_on_timer_timeout")
	tank.add_child(timer)
	
	shadow_tank_spawner = ShadowTankSpawner.instance()
	shadow_tank_spawner.setup_shadow_tank_spawner(tank)
	tank.add_child(shadow_tank_spawner)

func detach_ability() -> void:
	tank.remove_child(timer)
	tank.remove_child(shadow_tank_spawner)

func use_ability() -> void:
	if charges > 0:
		charges -= 1
		tank.speed = 1600
		if Input.is_action_pressed("player1_backward"):
			tank.set_forced_input_vector(Vector2(-1.0, 0.0))
		else:
			tank.set_forced_input_vector(Vector2(1.0, 0.0))
		timer.start()
		shadow_tank_spawner.start()

func _on_timer_timeout() -> void:
	tank.speed = tank.DEFAULT_SPEED
	tank.clear_forced_input_vector()
	shadow_tank_spawner.stop()
	if charges == 0:
		tank.set_ability_type(null)
