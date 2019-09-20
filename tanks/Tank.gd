extends KinematicBody2D

export (bool) var player_controlled = false
export (PackedScene) var Bullet = preload("res://Bullet.tscn")

var turn_speed : int = 5
var speed : int = 400
var velocity := Vector2()

var info_offset : Vector2
var health_bar_max : int

var health := 100
var can_shoot := true

func _ready():
	info_offset = $Info.position
	$Info.set_as_toplevel(true)
	$Info.position = global_position + info_offset
	
	health_bar_max = $Info/Health.rect_size.x
	
	# If testing tank on its own, make player controlled
	if get_tree().current_scene == self:
		player_controlled = true

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
		
		$TurretPivot.look_at(get_global_mouse_position())
		
		# Make info follow the tank
		$Info.position = global_position + info_offset
		
		rpc("update_remote_player", rotation, position, $TurretPivot.rotation)
		
		if Input.is_action_just_pressed("player_shoot") and can_shoot:
			can_shoot = false
			$ShootCooldownTimer.start()
			
			rpc("shoot")

puppet func update_remote_player(player_rotation, player_position, turret_rotation) -> void:
	rotation = player_rotation
	position = player_position
	$TurretPivot.rotation = turret_rotation
	$Info.position = global_position + info_offset

remotesync func shoot():
	var parent = get_parent()
	if not parent:
		return
	
	var bullet = Bullet.instance()
	parent.add_child(bullet)
	
	bullet.setup($TurretPivot/BulletStartPosition.global_position, $TurretPivot.global_rotation)

func set_player_name(_name : String) -> void:
	$Info/PlayerName.text = _name
	
func _on_ShootCooldownTimer_timeout() -> void:
	can_shoot = true

master func take_damage(damage : int) -> void:
	health -= damage
	if health <= 0:
		rpc("die")
	else:
		rpc("update_health", health)

remotesync func update_health(_health) -> void:
	$Info/Health.rect_size.x = (float(_health) / 100) * health_bar_max

remotesync func die() -> void:
	queue_free()
