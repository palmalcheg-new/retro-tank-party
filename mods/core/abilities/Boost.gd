extends "res://src/components/abilities/BaseAbility.gd"

const Tank = preload("res://src/objects/Tank.gd")
const ShadowTank = preload("res://mods/core/abilities/ShadowTank.tscn")

onready var timer = $Timer

var last_movement_direction := 1.0
var boosting := false
var spawn_rate := 2
var spawn_counter := 0

func attach_ability() -> void:
	tank.hooks.subscribe("shoot", self, "_hook_tank_shoot", -100)
	tank.hooks.subscribe("get_input_vector", self, "_hook_tank_get_input_vector", 10)

func detach_ability() -> void:
	tank.hooks.unsubscribe("shoot", self, "_hook_tank_shoot")
	tank.hooks.unsubscribe("get_input_vector", self, "_hook_tank_get_input_vector")

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
		timer.start()
		boosting = true

func _hook_tank_shoot(event: Tank.TankEvent) -> void:
	if boosting:
		event.stop_propagation()

func _hook_tank_get_input_vector(event: Tank.InputVectorEvent) -> void:
	if boosting:
		event.input_vector.x = last_movement_direction
	elif event.input_vector.x != 0:
		last_movement_direction = -1.0 if event.input_vector.x < 0 else 1.0

func mark_finished() -> void:
	if boosting:
		charges = 0
	else:
		.mark_finished()

func _on_Timer_timeout() -> void:
	tank.speed = tank.DEFAULT_SPEED
	boosting = false
	if charges == 0:
		emit_signal("finished")
