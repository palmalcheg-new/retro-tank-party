extends "res://src/components/abilities/BaseAbility.gd"

const Tank = preload("res://src/objects/Tank.gd")
const ShadowTank = preload("res://mods/core/abilities/ShadowTank.tscn")

onready var timer = $Timer

const BOOST_SPEED := 3495251

var last_movement_direction := 0
var spawn_rate := 1
var spawn_counter := 0

func attach_ability() -> void:
	last_movement_direction = 0
	spawn_counter = 0
	tank.hooks.subscribe("shoot", self, "_hook_tank_shoot", -100)
	tank.hooks.subscribe("calculate_movement_vector", self, "_hook_tank_calculate_movement_vector", 10)

func detach_ability() -> void:
	tank.speed = Tank.DEFAULT_SPEED
	tank.hooks.unsubscribe("shoot", self, "_hook_tank_shoot")
	tank.hooks.unsubscribe("calculate_movement_vector", self, "_hook_tank_calculate_movement_vector")

func spawn() -> void:
	# We start the name with 0 so that it gets put in the tree earlier than
	# any of the tank nodes.
	SyncManager.spawn("0ShadowTank", tank.get_parent(), ShadowTank, {
		tank = tank,
	})

func _save_state() -> Dictionary:
	return {
		last_movement_direction = last_movement_direction,
		spawn_counter = spawn_counter,
	}

func _load_state(state: Dictionary) -> void:
	last_movement_direction = state['last_movement_direction']
	spawn_counter = state['spawn_counter']

func _network_process(delta: float, input: Dictionary) -> void:
	if spawn_counter <= 0:
		spawn_counter = spawn_rate
		spawn()
	
	spawn_counter -= 1

func use_ability() -> void:
	tank.speed = BOOST_SPEED
	timer.start()

func _hook_tank_shoot(event: Tank.TankEvent) -> void:
	event.stop_propagation()

func _hook_tank_calculate_movement_vector(event: Tank.CalculateMovementVectorEvent) -> void:
	if last_movement_direction == 0:
		last_movement_direction = -SGFixed.ONE if event.movement_vector.x < 0 else SGFixed.ONE
	
	event.movement_vector.x = last_movement_direction

func _on_Timer_timeout() -> void:
	tank.speed = tank.DEFAULT_SPEED
	mark_finished()
