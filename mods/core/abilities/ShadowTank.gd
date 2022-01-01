extends "res://src/objects/tank/BaseTank.gd"

onready var timer := $Timer

func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
	var tank = data['tank']
	return {
		player_index = tank.player_index,
		fixed_transform = tank.fixed_transform.copy(),
		_turret_rotation = tank.turret_pivot.fixed_rotation,
	}

func _network_spawn(data: Dictionary) -> void:
	set_tank_color(data['player_index'])
	fixed_transform = data['fixed_transform']
	turret_pivot.fixed_rotation = data['_turret_rotation']
	collision_shape.disabled = true
	timer.start()

func _on_Timer_timeout() -> void:
	SyncManager.despawn(self)
