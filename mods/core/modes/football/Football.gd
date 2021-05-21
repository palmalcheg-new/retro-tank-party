extends Area2D

onready var pass_timer = $PassTimer
onready var ray_cast = $RayCast2D

var vector: Vector2
var speed := 700
var sliding_over_obstruction := false
var frames_countdown := 0

# The tank holding the football or null.
var held

var match_manager
var bounds_rect: Rect2
var in_bounds := true

func setup_football(_match_manager, _bounds_rect) -> void:
	match_manager = _match_manager
	bounds_rect = _bounds_rect

func pass_football(_position: Vector2, _vector: Vector2) -> void:
	in_bounds = true
	frames_countdown = 5
	global_position = _position
	global_rotation = _vector.angle()
	vector = _vector
	pass_timer.start()
	sliding_over_obstruction = false
	mark_as_held(null)

func mark_as_held(_held) -> void:
	held = _held
	if held:
		vector = Vector2.ZERO
		visible = false
		set_deferred("monitoring", false)
		pass_timer.stop()
		sliding_over_obstruction = false
	else:
		visible = true
		set_deferred("monitoring", true)

func _physics_process(delta: float) -> void:
	if frames_countdown > 0:
		frames_countdown -= 1
	
	if vector == Vector2.ZERO:
		return
	
	# Stop sliding over obstruction if we're now clear of it.
	if sliding_over_obstruction and not check_on_obstruction():
		vector = Vector2.ZERO
		sliding_over_obstruction = false
		return
	
	var increment = delta * speed
	ray_cast.cast_to = Vector2(increment * 4.0, 0)
	ray_cast.force_raycast_update()
	# If it collided with things that collide with bullets (2 = bullet).
	if ray_cast.is_colliding() and ray_cast.get_collider().get_collision_mask_bit(2):
		var old_position = global_position
		# Move football to stop short of the obstruction.
		global_position = ray_cast.get_collision_point() - (vector * 16)
		
		if check_on_obstruction():
			# If the ball is still on top of some obstruction, then keep sliding.
			global_position = old_position
			sliding_over_obstruction = true
		else:
			# Otherwise, stop here.
			vector = Vector2.ZERO
	
	position += vector * increment
	
	if get_tree().is_network_server():
		if in_bounds:
			in_bounds = bounds_rect.has_point(global_position)
			if not in_bounds:
				match_manager.rpc("start_new_round", "OUT OF BOUNDS!", -1)

func check_on_obstruction() -> bool:
	for body in get_overlapping_bodies():
		if body.get_collision_layer_bit(0):
			return true
	return false

func _on_Football_body_entered(body: PhysicsBody2D) -> void:
	if not get_tree().is_network_server():
		return
	# Prevent multiple tanks grabbing the football.
	if held:
		return
	# Only collide with tanks.
	if not body.get_collision_layer_bit(1):
		return
	# Prevent hitting self.
	if frames_countdown > 0:
		return
	
	match_manager.rpc("grab_football", body.get_path())

func _on_PassTimer_timeout() -> void:
	if not check_on_obstruction():
		vector = Vector2.ZERO
	else:
		sliding_over_obstruction = true
