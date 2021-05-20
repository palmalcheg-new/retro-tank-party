extends Area2D

onready var pass_timer = $PassTimer

var vector: Vector2
var speed := 700
var frames_countdown := 0

# The tank holding the football or null.
var held

var match_manager
var map_rect: Rect2
var in_bounds := true

func setup_football(_match_manager, _map_rect) -> void:
	match_manager = _match_manager
	map_rect = _map_rect

func pass_football(_position: Vector2, _rotation: float) -> void:
	in_bounds = true
	frames_countdown = 5
	global_position = _position
	global_rotation = _rotation
	vector = Vector2.RIGHT.rotated(rotation)
	mark_as_held(null)

func mark_as_held(_held) -> void:
	held = _held
	if held:
		vector = Vector2.ZERO
		visible = false
		set_deferred("monitoring", false)
		pass_timer.stop()
	else:
		visible = true
		set_deferred("monitoring", true)
		pass_timer.start()

func _physics_process(delta: float) -> void:
	position += vector * speed * delta
	
	if get_tree().is_network_server():
		if in_bounds:
			in_bounds = map_rect.has_point(global_position)
			if not in_bounds:
				match_manager.rpc("start_new_round", "OUT OF BOUNDS!", -1)
	
	if frames_countdown > 0:
		frames_countdown -= 1
	

func _on_Football_body_entered(body: PhysicsBody2D) -> void:
	if held:
		return
	
	# If it collided with things that collide with bullets (2 = bullet).
	if body.get_collision_mask_bit(2):
		# @todo How to synchronize this across clients?
		vector = Vector2.ZERO
	# If it collided with a tank.
	elif get_tree().is_network_server() and body.get_collision_layer_bit(1):
		# Prevent hitting self.
		if frames_countdown > 0:
			return
		
		match_manager.rpc("grab_football", body.get_path())

func _on_PassTimer_timeout() -> void:
	vector = Vector2.ZERO
