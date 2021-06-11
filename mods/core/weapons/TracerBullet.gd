extends "res://src/objects/Bullet.gd"

var target_seek_speed := 10

var target: Node2D = null

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var target_vector = (target.global_position - global_position).normalized()
		vector = vector.linear_interpolate(target_vector, target_seek_speed * delta).normalized()
		rotation = vector.angle()

