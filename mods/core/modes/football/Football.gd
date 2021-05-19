extends Area2D

onready var pass_timer = $PassTimer

var vector: Vector2
var speed := 700
var frames_countdown := 0

# The tank holding the football or null.
var held

var match_manager

func setup_football(_match_manager) -> void:
	match_manager = _match_manager

func pass_football(_position: Vector2, _rotation: float) -> void:
	frames_countdown = 5
	global_position = _position
	global_rotation = _rotation
	vector = Vector2.RIGHT.rotated(rotation)
	mark_as_held(null)

func mark_as_held(_held) -> void:
	held = _held
	if held:
		visible = false
		monitoring = false
		pass_timer.stop()
	else:
		visible = true
		monitoring = true
		pass_timer.start()

func _physics_process(delta: float) -> void:
	position += vector * speed * delta
	if frames_countdown > 0:
		frames_countdown -= 1
	# @todo check that football is in bounds

func _on_Football_body_entered(body: PhysicsBody2D) -> void:
	if held:
		return
	
	# If it collided with the environment.
	if body.get_collision_layer_bit(0):
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
