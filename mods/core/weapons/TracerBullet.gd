extends "res://src/objects/Bullet.gd"

var target: Node2D = null

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var target_vector = (target.global_position - global_position).normalized()
		vector = vector.linear_interpolate(target_vector, target_seek_speed * delta).normalized()
		rotation = vector.angle()
	# @todo are we hit by the "multilevel" call thing?
	._process(delta)
