extends SGArea2D

onready var pass_timer = $PassTimer
onready var ray_cast = $RayCast2D

const SIXTEEN = 1048576

var vector: SGFixedVector2 = SGFixed.vector2(0, 0)
var speed := 1529173
var sliding_over_obstruction := false
var frames_countdown := 0

# The tank holding the football or null.
var held

var bounds_rect: SGFixedRect2
var in_bounds := true

signal out_of_bounds ()
signal grabbed (tank)

func setup_football(_bounds_rect) -> void:
	bounds_rect = _bounds_rect

func pass_football(_position: SGFixedVector2, _vector: SGFixedVector2) -> void:
	in_bounds = true
	frames_countdown = 5
	set_global_fixed_position(_position)
	vector = _vector
	if vector.x == 0 and vector.y == 0:
		fixed_rotation = 0
	else:
		set_global_fixed_rotation(_vector.angle())
	pass_timer.start()
	sliding_over_obstruction = false
	mark_as_held(null)
	sync_to_physics_engine()

func _save_state() -> Dictionary:
	return {
		in_bounds = in_bounds,
		frames_countdown = frames_countdown,
		fixed_transform = fixed_transform.copy(),
		vector = vector.copy(),
		sliding_over_obstruction = sliding_over_obstruction,
		held = held.get_path() if held else null,
		visible = visible,
	}

func _load_state(state: Dictionary) -> void:
	in_bounds = state['in_bounds']
	frames_countdown = state['frames_countdown']
	fixed_transform = state['fixed_transform'].copy()
	vector = state['vector'].copy()
	sliding_over_obstruction = state['sliding_over_obstruction']
	held = get_node(state['held']) if state['held'] else null
	visible = state['visible']
	sync_to_physics_engine()

func mark_as_held(_held) -> void:
	held = _held
	if held:
		vector = SGFixed.vector2(0, 0)
		visible = false
		pass_timer.stop()
		sliding_over_obstruction = false
	else:
		visible = true

func _network_process(delta: float, input: Dictionary) -> void:
	if frames_countdown > 0:
		frames_countdown -= 1
	
	for body in get_overlapping_bodies():
		if _on_Football_body_entered(body):
			break
	
	if held and is_instance_valid(held):
		set_global_fixed_position(held.get_global_fixed_position())
		sync_to_physics_engine()
		return
	
	if vector.x == 0 and vector.y == 0:
		return
	
	# Stop sliding over obstruction if we're now clear of it.
	if sliding_over_obstruction and not check_on_obstruction():
		vector = SGFixed.vector2(0, 0)
		sliding_over_obstruction = false
		return
	
	ray_cast.cast_to = SGFixed.vector2(speed, 0)
	ray_cast.update_raycast_collision()
	# If it collided with things that collide with bullets (2 = bullet).
	if ray_cast.is_colliding() and ray_cast.get_collider().get_collision_mask_bit(2):
		var old_fixed_position = fixed_position.copy()
		# Move football to stop short of the obstruction.
		set_global_fixed_position(ray_cast.get_collision_point().sub(vector.mul(SIXTEEN)))
		sync_to_physics_engine()
		
		if check_on_obstruction():
			# If the ball is still on top of some obstruction, then keep sliding.
			fixed_position = old_fixed_position
			sliding_over_obstruction = true
		else:
			# Otherwise, stop here.
			vector = SGFixed.vector2(0, 0)
	
	fixed_position.iadd(vector.mul(speed))
	sync_to_physics_engine()
	
	if in_bounds:
		in_bounds = bounds_rect.has_point(get_global_fixed_position())
		if not in_bounds:
			emit_signal("out_of_bounds")

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	position = lerp(old_state['fixed_transform'].get_origin().to_float(), new_state['fixed_transform'].get_origin().to_float(), weight)

func check_on_obstruction() -> bool:
	for body in get_overlapping_bodies():
		if body.get_collision_layer_bit(0):
			return true
	return false

func _on_Football_body_entered(body: SGCollisionObject2D) -> bool:
	# Prevent multiple tanks grabbing the football.
	if held:
		return true
	# Only collide with tanks.
	if not body.get_collision_layer_bit(1):
		return false
	# Prevent hitting self.
	if frames_countdown > 0:
		return false
	
	emit_signal("grabbed", body)
	return true

func _on_PassTimer_timeout() -> void:
	if not check_on_obstruction():
		vector = SGFixed.vector2(0, 0)
	else:
		sliding_over_obstruction = true
