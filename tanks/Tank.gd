extends KinematicBody2D

export (bool) var player_controlled = false

var turn_speed : int = 5
var speed : int = 100
var velocity := Vector2()

var info_offset

func _ready():
	info_offset = $Info.position
	$Info.set_as_toplevel(true)
	$Info.position = global_position + info_offset

func _physics_process(delta: float) -> void:
	if player_controlled:
		if Input.is_action_pressed("player_turn_left"):
			rotation += -(turn_speed * delta)
		if Input.is_action_pressed("player_turn_right"):
			rotation += (turn_speed * delta)
		
		velocity = Vector2()
		if Input.is_action_pressed("player_forward"):
			velocity = Vector2(1, 0).rotated(rotation) * speed
		if Input.is_action_pressed("player_backward"):
			velocity = Vector2(1, 0).rotated(rotation) * -speed
		move_and_slide(velocity)
		
		$TurretHub.look_at(get_global_mouse_position())
		
		# Make info follow the tank
		$Info.position = global_position + info_offset
		
		rpc("update_remote_player", rotation, position, $TurretHub.rotation)

puppet func update_remote_player(player_rotation, player_position, turret_rotation) -> void:
	rotation = player_rotation
	position = player_position
	$TurretHub.rotation = turret_rotation
	$Info.position = global_position + info_offset

func set_player_name(_name : String) -> void:
	$Info/PlayerName.text = _name
	