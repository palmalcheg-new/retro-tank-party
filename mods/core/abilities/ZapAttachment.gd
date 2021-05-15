extends Node2D

var tank

func setup_attachment(_tank) -> void:
	tank = _tank

remotesync func set_tank_visibility(enabled: bool) -> void:
	tank.collision_shape.set_deferred("enabled", enabled)
	tank.visible = enabled
