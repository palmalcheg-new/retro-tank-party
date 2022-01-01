extends SGFixedNode2D

func setup_tracer_detector(tank) -> void:
	for raycast in get_children():
		raycast.add_exception(tank)

func get_tracer_target():
	var target = null
	for raycast in get_children():
		raycast.update_raycast_collision()
		if raycast.is_colliding():
			target = raycast.get_collider()
			break
	return target
