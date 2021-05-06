extends Node2D

const ShadowTank = preload("res://mods/core/abilities/ShadowTank.tscn")

var tank
var spawning := false

func setup_shadow_tank_spawner(_tank) -> void:
	tank = _tank

func start() -> void:
	spawning = true

func stop() -> void:
	spawning = false

func spawn() -> void:
	var tank_parent: Node2D = tank.get_parent()
	var shadow_tank = ShadowTank.instance()
	tank_parent.add_child(shadow_tank)
	tank_parent.move_child(shadow_tank, 0)
	shadow_tank.setup_shadow_tank(tank)

func _physics_process(delta: float) -> void:
	if spawning:
		spawn()
