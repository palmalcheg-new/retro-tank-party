extends KinematicBody2D

const BaseWeaponType = preload("res://mods/core/weapons/base.tres")
const Explosion = preload("res://src/objects/Explosion.tscn")

export (bool) var player_controlled = false
export (String) var input_prefix := "player1_"

signal player_dead (killer_id)

onready var body_sprite := $BodySprite
onready var turret_sprite := $TurretPivot/TurretSprite
onready var turret_pivot := $TurretPivot
onready var bullet_start_position := $TurretPivot/BulletStartPosition

onready var player_info_node := $PlayerInfo
onready var player_info_offset: Vector2 = player_info_node.position

onready var shoot_cooldown_timer := $ShootCooldownTimer
onready var animation_player := $AnimationPlayer
onready var shoot_sound := $ShootSound
onready var engine_sound := $EngineSound

var turn_speed := 5
var speed := 400
var velocity: Vector2

var health := 100
var dead := false

var shooting := false
var can_shoot := true
var shoot_rumble := 0.025

var mouse_control := true

var camera: Camera2D = null

var weapon_type: WeaponType
var weapon

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
var player_index

func _ready():
	player_info_node.set_as_toplevel(true)
	player_info_node.position = global_position + player_info_offset
	
	var sprite_material = body_sprite.material.duplicate()
	body_sprite.material = sprite_material
	turret_sprite.material = sprite_material
	
	set_weapon_type(BaseWeaponType)
	
	# If testing tank on its own, make player controlled
	if get_tree().current_scene == self:
		player_controlled = true
	
	if player_controlled:
		Globals.my_player_position = global_position

func setup_tank(player) -> void:
	set_network_master(player.peer_id)
	player_info_node.set_player_name(player.name)
	player_index = player.index
	
	body_sprite.region_rect = TANK_COLORS[player_index]['body_sprite_region']
	turret_sprite.region_rect = TANK_COLORS[player_index]['turret_sprite_region']
	
	if player.team != -1:
		player_info_node.set_team(player.team)

func set_weapon_type(_weapon_type: WeaponType) -> void:
	if weapon_type != _weapon_type:
		weapon_type = _weapon_type
		
		if weapon:
			weapon.detach_weapon()
		
		weapon = weapon_type.weapon_script.new()
		weapon.setup_weapon(self, weapon_type)
		weapon.attach_weapon()

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
		
		Globals.my_player_position = global_position
		
		if input_vector.x >= 0.1 or input_vector.x <= -0.1:
			engine_sound.engine_state = engine_sound.EngineState.DRIVING
		else:
			engine_sound.engine_state = engine_sound.EngineState.IDLE
		
		if mouse_control:
			turret_pivot.look_at(get_global_mouse_position())
		else:
			if Input.is_action_pressed(input_prefix + "aim_up") or Input.is_action_pressed(input_prefix + "aim_down") or Input.is_action_pressed(input_prefix + "aim_left") or Input.is_action_pressed(input_prefix + "aim_right"):
				var joy_vector = Vector2()
				joy_vector.x = Input.get_action_strength(input_prefix + "aim_right") - Input.get_action_strength(input_prefix + "aim_left")
				joy_vector.y = Input.get_action_strength(input_prefix + "aim_down") - Input.get_action_strength(input_prefix + "aim_up")
				turret_pivot.global_rotation = joy_vector.angle()
			else:
				turret_pivot.rotation = 0
		
		# Make info follow the tank
		player_info_node.position = global_position + player_info_offset
		
		if shooting:
			can_shoot = false
			shoot_cooldown_timer.start()
			shoot()
			Globals.rumble.add_weak_rumble(shoot_rumble)
		
		if camera:
			camera.global_position = global_position
		
		rpc("update_remote_player", rotation, position, turret_pivot.rotation, shooting, weapon_type.resource_path)
		
		shooting = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_control = true
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		mouse_control = false
	if event.is_action_pressed(input_prefix + "shoot") and can_shoot:
		shooting = true

puppet func update_remote_player(player_rotation: float, player_position: Vector2, turret_rotation: float, shooting: bool, _weapon_type_path: String) -> void:
	rotation = player_rotation
	position = player_position
	turret_pivot.rotation = turret_rotation
	player_info_node.position = global_position + player_info_offset
	if weapon_type.resource_path != _weapon_type_path:
		set_weapon_type(load(_weapon_type_path))
	if shooting:
		shoot()

func shoot():
	if not get_parent():
		return
	
	shoot_sound.play()
	weapon.fire_weapon()
	
func _on_ShootCooldownTimer_timeout() -> void:
	can_shoot = true

func take_damage(damage: int, attacker_id: int = -1) -> void:
	if player_controlled:
		if GameSettings.use_screenshake and camera:
			# Between 0.25 and 0.5 seems good
			camera.add_trauma(0.5)
		
		Globals.rumble.add_rumble(0.25)
	
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

remotesync func update_health(_health) -> void:
	health = _health
	player_info_node.update_health(health)

remotesync func die(killer_id: int = -1) -> void:
	if not dead:
		dead = true
		
		var explosion = Explosion.instance()
		get_parent().add_child(explosion)
		explosion.setup(global_position, 1.5, "fire")
		
		queue_free()
		
		emit_signal("player_dead", killer_id)
