extends Node2D

func get_tracer_target():
	var target = null
	for raycast in get_children():
		raycast.force_raycast_update()
		if raycast.is_colliding():
			target = raycast.get_collider()
			break
	return target
