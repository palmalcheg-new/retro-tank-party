extends KinematicBody2D

var Bullet = preload("res://src/objects/Bullet.tscn")
var Explosion = preload("res://src/objects/Explosion.tscn")

export (bool) var player_controlled = false
export (String) var input_prefix := "player1_"

signal player_dead (killer_id)

onready var body_sprite := $BodySprite
onready var turret_sprite := $TurretPivot/TurretSprite
onready var turret_pivot := $TurretPivot

onready var animation_player := $AnimationPlayer
onready var shoot_sound := $ShootSound
onready var engine_sound := $EngineSound

var turn_speed := 5
var speed := 400
var velocity: Vector2

var info_offset: Vector2
var health_bar_max: int

var health := 100
var dead := false

var shooting := false
var can_shoot := true

var mouse_control := true

var camera: Camera2D = null

var bullet_type: int = Constants.BulletType.NORMAL

const TANK_COLORS = {
	1: {
		body_sprite_region = Rect2( 434, 0, 84, 83 ),
		turret_sprite_region = Rect2( 722, 199, 24, 60 ),
	},
	2: {
		body_sprite_region = Rect2( 436, 308, 84, 80 ),
		turret_sprite_region = Rect2( 744, 684, 24, 60 ),
	},
	3: {
		body_sprite_region = Rect2( 520, 268, 76, 80 ),
		turret_sprite_region = Rect2( 724, 452, 24, 60 ),
	},
	4: {
		body_sprite_region = Rect2( 436, 692, 84, 80 ),
		turret_sprite_region = Rect2( 724, 512, 24, 60 ),
	},
}
var player_index: int setget set_player_index

func _ready():
	info_offset = $Info.position
	$Info.set_as_toplevel(true)
	$Info.position = global_position + info_offset
	
	health_bar_max = $Info/Health.rect_size.x
	
	var sprite_material = body_sprite.material.duplicate()
	body_sprite.material = sprite_material
	turret_sprite.material = sprite_material
	
	# If testing tank on its own, make player controlled
	if get_tree().current_scene == self:
		player_controlled = true
	
	if player_controlled:
		Globals.my_player_position = global_position

func set_player_index(_player_index: int) -> void:
	player_index = _player_index
	body_sprite.region_rect = TANK_COLORS[player_index]['body_sprite_region']
	turret_sprite.region_rect = TANK_COLORS[player_index]['turret_sprite_region']

func _get_input_vector() -> Vector2:
	var input: Vector2
	
	if Input.is_action_pressed(input_prefix + "turn_left"):
		input.y -= min(Input.get_action_strength(input_prefix + "turn_left") + 0.5, 1.0)
	if Input.is_action_pressed(input_prefix + "turn_right"):
		input.y = min(Input.get_action_strength(input_prefix + "turn_right") + 0.5, 1.0)
	if Input.is_action_pressed(input_prefix + "backward"):
		input.x -= min(Input.get_action_strength(input_prefix + "backward") + 0.5, 1.0)
	if Input.is_action_pressed(input_prefix + "forward"):
		input.x += min(Input.get_action_strength(input_prefix + "forward") + 0.5, 1.0)
	
	return input

func _physics_process(delta: float) -> void:
	if player_controlled:
		var input_vector = _get_input_vector()
		
		engine_sound.turning = false
		if input_vector.y < 0:
			engine_sound.turning = true
		if input_vector.y > 0:
			engine_sound.turning = true
		
		rotation += input_vector.y * turn_speed * delta
		
		velocity = Vector2()
		velocity.x = input_vector.x
		velocity = velocity.rotated(rotation) * speed
		move_and_slide(velocity)
		
		if player_controlled:
			Globals.my_player_position = global_position
		
		if input_vector.x >= 0.1 or input_vector.x <= -0.1:
			engine_sound.engine_state = engine_sound.EngineState.DRIVING
		else:
			engine_sound.engine_state = engine_sound.EngineState.IDLE
		
		if mouse_control:
			$TurretPivot.look_at(get_global_mouse_position())
		else:
			if Input.is_action_pressed(input_prefix + "aim_up") or Input.is_action_pressed(input_prefix + "aim_down") or Input.is_action_pressed(input_prefix + "aim_left") or Input.is_action_pressed(input_prefix + "aim_right"):
				var joy_vector = Vector2()
				joy_vector.x = Input.get_action_strength(input_prefix + "aim_right") - Input.get_action_strength(input_prefix + "aim_left")
				joy_vector.y = Input.get_action_strength(input_prefix + "aim_down") - Input.get_action_strength(input_prefix + "aim_up")
				$TurretPivot.global_rotation = joy_vector.angle()
			else:
				$TurretPivot.rotation = 0
		
		# Make info follow the tank
		$Info.position = global_position + info_offset
		
		if shooting:
			can_shoot = false
			$ShootCooldownTimer.start()
			shoot()
		
		if camera:
			camera.global_position = global_position
		
		rpc("update_remote_player", rotation, position, $TurretPivot.rotation, shooting, bullet_type)
		
		shooting = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_control = true
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		mouse_control = false
	if event.is_action_pressed(input_prefix + "shoot") and can_shoot:
		shooting = true

puppet func update_remote_player(player_rotation: float, player_position: Vector2, turret_rotation: float, shooting: bool, _bullet_type: int) -> void:
	rotation = player_rotation
	position = player_position
	$TurretPivot.rotation = turret_rotation
	$Info.position = global_position + info_offset
	bullet_type = _bullet_type
	if shooting:
		shoot()

func shoot():
	if not get_parent():
		return
	
	shoot_sound.play()
	
	match bullet_type:
		Constants.BulletType.NORMAL:
			_create_bullet()
		
		Constants.BulletType.SPREAD:
			var original_rotation = $TurretPivot.rotation
			$TurretPivot.rotate(deg2rad(-5))
			for i in range(3):
				_create_bullet()
				$TurretPivot.rotate(deg2rad(5))
			$TurretPivot.rotation = original_rotation
		
		Constants.BulletType.TARGET:
			var target = null
			for raycast in $TurretPivot/BulletStartPosition.get_children():
				raycast.force_raycast_update()
				if raycast.is_colliding():
					target = raycast.get_collider()
					break
			_create_bullet(target)

func _create_bullet(target = null):
	var bullet = Bullet.instance()
	get_parent().add_child(bullet)
	bullet.setup(get_network_master(), player_index, $TurretPivot/BulletStartPosition.global_position, $TurretPivot.global_rotation, target)

func set_player_name(_name: String) -> void:
	$Info/PlayerName.text = _name
	
func _on_ShootCooldownTimer_timeout() -> void:
	can_shoot = true

func take_damage(damage: int, attacker_id: int = -1) -> void:
	if player_controlled and camera:
		if GameSettings.use_screenshake:
			# Between 0.25 and 0.5 seems good
			camera.add_trauma(0.5)
	
	animation_player.play("Flash")
	if is_network_master():
		health -= damage
		if health <= 0:
			rpc("die", attacker_id)
		else:
			rpc("update_health", health)

func restore_health(_health: int) -> void:
	if is_network_master():
		health += _health
		if health > 100:
			health = 100
		rpc("update_health", health)

func set_bullet_type(_bullet_type: int) -> void:
	bullet_type = _bullet_type

remotesync func update_health(_health) -> void:
	$Info/Health.rect_size.x = (float(_health) / 100) * health_bar_max

remotesync func die(killer_id: int = -1) -> void:
	if not dead:
		dead = true
		
		var explosion = Explosion.instance()
		get_parent().add_child(explosion)
		explosion.setup(global_position, 1.5, "fire")
		
		queue_free()
		
		emit_signal("player_dead", killer_id)
