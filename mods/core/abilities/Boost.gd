extends "res://src/components/abilities/BaseAbility.gd"

const ShadowTank = preload("res://mods/core/abilities/ShadowTank.tscn")

onready var timer = $Timer

var boosting := false
var spawn_rate := 2
var spawn_counter := 0

func spawn() -> void:
	var tank_parent: Node2D = tank.get_parent()
	var shadow_tank = ShadowTank.instance()
	tank_parent.add_child(shadow_tank)
	tank_parent.move_child(shadow_tank, 0)
	shadow_tank.setup_shadow_tank(tank)

func _physics_process(delta: float) -> void:
	if boosting:
		if spawn_counter <= 0:
			spawn_counter = spawn_rate
			spawn()
		
		spawn_counter -= 1

func use_ability() -> void:
	if charges > 0 and not boosting:
		charges -= 1
		tank.speed = 1600
		if Input.is_action_pressed("player1_backward"):
			tank.set_forced_input_vector(Vector2(-1.0, 0.0))
		else:
			tank.set_forced_input_vector(Vector2(1.0, 0.0))
		timer.start()
		boosting = true

func mark_finished() -> void:
	if boosting:
		charges = 0
	else:
		.mark_finished()

func _on_Timer_timeout() -> void:
	tank.speed = tank.DEFAULT_SPEED
	tank.clear_forced_input_vector()
	boosting = false
	if charges == 0:
		emit_signal("finished")
