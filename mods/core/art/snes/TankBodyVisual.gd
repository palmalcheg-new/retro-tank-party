extends Node2D

const Tank = preload("res://src/objects/Tank.gd")

onready var animation_player = $AnimationPlayer

func attach_visual(info: Dictionary) -> void:
	var tank = get_parent()
	var hooks = tank.get('hooks')
	if hooks:
		hooks.subscribe("calculate_movement_vector", self, "_hook_tank_calculate_movement_vector", 10)

func detach_visual() -> void:
	var tank = get_parent()
	var hooks = tank.get('hooks')
	if hooks:
		hooks.unsubscribe("calculate_movement_vector", self, "_hook_tank_calculate_movement_vector")

func _hook_tank_calculate_movement_vector(event: Tank.CalculateMovementVectorEvent) -> void:
	if event.movement_vector.x != 0 or event.movement_vector.y != 0:
		if event.movement_vector.x > 0:
			animation_player.play("drive")
		else:
			animation_player.play_backwards("drive")
	else:
		animation_player.stop()
