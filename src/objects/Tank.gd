extends "res://src/objects/tank/BaseTank.gd"

const BaseWeaponType = preload("res://mods/core/weapons/base.tres")
const Explosion = preload("res://src/objects/Explosion.tscn")
const EventDispatcher = preload("res://src/utils/EventDispatcher.gd")

export (bool) var player_controlled = false

signal player_dead (killer_id)
signal shoot ()
signal hurt (damage, attacker_id, attack_vector)
signal weapon_type_changed (weapon_type)
signal ability_type_changed (ability_type)
signal ability_recharged (ability)

onready var player_info_node := $PlayerInfo
onready var player_info_offset: Vector2 = player_info_node.position

onready var shoot_cooldown_timer := $ShootCooldownTimer
onready var animation_player := $AnimationPlayer
onready var shoot_sound := $ShootSound
onready var engine_sound := $EngineSound

const DEFAULT_TURN_SPEED := 5
const DEFAULT_SPEED := 400

var turn_speed := DEFAULT_TURN_SPEED
var speed := DEFAULT_SPEED
var velocity: Vector2
var desired_rotation: float

var health := 100
var dead := false
var invincible := false

var shooting := false
var can_shoot := true
var shoot_rumble := 0.025
var using_ability := false

var mouse_control := true
var forced_input_vector: Vector2
var use_forced_input_vector := false

var hooks := EventDispatcher.new()

var game
var camera: Camera2D = null

var weapon_type: WeaponType
var weapon
var ability_type: AbilityType
var ability
var last_ability

var player_index

class TankEvent extends EventDispatcher.Event:
	var tank
	
	func _init(_tank) -> void:
		tank = _tank

class PickupWeaponEvent extends TankEvent:
	var weapon_type: WeaponType
	
	func _init(_tank, _weapon_type: WeaponType).(_tank) -> void:
		weapon_type = _weapon_type

class PickupAbilityEvent extends TankEvent:
	var ability_type: AbilityType
	
	func _init(_tank, _ability_type: AbilityType).(_tank) -> void:
		ability_type = _ability_type

class TakeDamageEvent extends TankEvent:
	var damage: int
	var attacker_id: int
	var attack_vector: Vector2
	
	func _init(_tank, _damage: int, _attacker_id: int, _attack_vector: Vector2).(_tank) -> void:
		damage = _damage
		attacker_id = _attacker_id
		attack_vector = _attack_vector

class RestoreHealthEvent extends TankEvent:
	var health: int
	
	func _init(_tank, _health: int).(_tank) -> void:
		health = _health

class DieEvent extends TankEvent:
	var killer_id: int
	
	func _init(_tank, _killer_id: int).(_tank) -> void:
		killer_id = _killer_id

func _ready():
	hooks.subscribe("pickup_ability", self, "_hook_default_pickup_ability", 0)
	hooks.subscribe("pickup_weapon", self, "_hook_default_pickup_weapon", 0)
	hooks.subscribe("shoot", self, "_hook_default_shoot", 0)
	hooks.subscribe("use_ability", self, "_hook_default_use_ability", 0)
	hooks.subscribe("take_damage", self, "_hook_default_take_damage", 0)
	hooks.subscribe("restore_health", self, "_hook_default_restore_health", 0)
	hooks.subscribe("die", self, "_hook_default_die", 0)
	
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

func setup_tank(_game, player) -> void:
	game = _game
	
	set_network_master(player.peer_id)
	player_info_node.set_player_name(player.name)
	player_index = player.index
	
	set_tank_color(player_index)
	
	if player.team != -1:
		player_info_node.set_team(player.team)

func pickup_weapon(_weapon_type: WeaponType) -> void:
	hooks.dispatch_event("pickup_weapon", PickupWeaponEvent.new(self, _weapon_type))

func _hook_default_pickup_weapon(event: PickupWeaponEvent) -> void:
	set_weapon_type(event.weapon_type)

func set_weapon_type(_weapon_type: WeaponType) -> void:
	if _weapon_type == null:
		_weapon_type = BaseWeaponType
	
	if weapon_type != _weapon_type:
		weapon_type = _weapon_type
		
		if weapon:
			weapon.detach_weapon()
		
		weapon = weapon_type.weapon_script.new()
		weapon.setup_weapon(self, weapon_type)
		weapon.attach_weapon()
		
		if game and player_controlled:
			if weapon_type.resource_path == "res://mods/core/weapons/base.tres":
				game.hud.clear_weapon_label()
			else:
				game.hud.set_weapon_label(weapon_type.name)
		
		emit_signal("weapon_type_changed", weapon_type)

func pickup_ability(_ability_type: AbilityType) -> void:
	hooks.dispatch_event("pickup_ability", PickupAbilityEvent.new(self, _ability_type))

func _hook_default_pickup_ability(event: PickupAbilityEvent) -> void:
	set_ability_type(event.ability_type)

func set_ability_type(_ability_type: AbilityType) -> void:
	# If the last ability is still in effect, and we just picked up the same
	# ability, then we reinstate that ability.
	if last_ability and is_instance_valid(last_ability) and is_a_parent_of(last_ability) and last_ability.ability_type == _ability_type:
		var tmp = ability
		ability_type = last_ability.ability_type
		ability = last_ability
		last_ability = tmp
	
	if ability_type == _ability_type and _ability_type != null:
		if ability and player_controlled:
			ability.recharge_ability()
			_update_ability_label()
			emit_signal("ability_recharged", ability)
	else:
		if ability:
			ability.mark_finished()
		
		ability_type = _ability_type
		if ability_type != null:
			ability = ability_type.ability_scene.instance()
			ability.connect("finished", self, "_on_ability_finished", [ability])
			add_child(ability)
			ability.setup_ability(self, ability_type)
			ability.attach_ability()
		else:
			ability = null
		
		_update_ability_label()
		emit_signal("ability_type_changed", ability_type)

func _update_ability_label() -> void:
	if game and player_controlled:
		if ability_type:
			game.hud.set_ability_label(ability_type.name, ability.charges)
		else:
			game.hud.clear_ability_label()

func _on_ability_finished(old_ability) -> void:
	old_ability.disconnect("finished", self, "_on_ability_finished")
	
	old_ability.detach_ability()
	remove_child(old_ability)
	old_ability.queue_free()
	
	# If this is the current ability, then clear it out.
	if old_ability == ability:
		ability = null
		ability_type = null
		_update_ability_label()
	# If this is the last ability, then clear it out.
	elif old_ability == last_ability:
		last_ability = null

func set_forced_input_vector(input: Vector2) -> void:
	forced_input_vector = input
	use_forced_input_vector = true

func clear_forced_input_vector() -> void:
	forced_input_vector = Vector2.ZERO
	use_forced_input_vector = false

func _get_input_vector() -> Vector2:
	if use_forced_input_vector:
		return forced_input_vector
	
	var input: Vector2
	
	if GameSettings.control_scheme == GameSettings.ControlScheme.RETRO:
		if Input.is_action_pressed("player1_turn_left"):
			input.y -= min(Input.get_action_strength("player1_turn_left") + 0.5, 1.0)
		if Input.is_action_pressed("player1_turn_right"):
			input.y = min(Input.get_action_strength("player1_turn_right") + 0.5, 1.0)
		if Input.is_action_pressed("player1_backward"):
			input.x -= min(Input.get_action_strength("player1_backward") + 0.5, 1.0)
		if Input.is_action_pressed("player1_forward"):
			input.x += min(Input.get_action_strength("player1_forward") + 0.5, 1.0)
	else:
		var current_vector = Vector2.RIGHT.rotated(rotation)
		var desired_vector = Vector2(
			Input.get_action_strength("player1_turn_right") - Input.get_action_strength("player1_turn_left"),
			Input.get_action_strength("player1_backward") - Input.get_action_strength("player1_forward")).clamped(1.0)
		if desired_vector == Vector2.ZERO:
			return input
		if desired_vector.length() > 0.85:
			desired_vector = desired_vector.normalized()
		
		# If going backwards is a shorter rotation, move backwards.
		if abs(current_vector.angle_to(desired_vector)) > PI / 2.0:
			# Flip the vector for the angle calculations.
			current_vector = current_vector.rotated(PI)
			
			# Set us moving backwards ...
			input.x = -desired_vector.length()
		else:
			# ... or forwards
			input.x = desired_vector.length()
		
		# Normalize the angle to the desired vector
		var angle_to = current_vector.angle_to(desired_vector)
		if abs(angle_to) > PI / 2.0:
			angle_to = TAU - angle_to
		
		# Rotate in the direction closest to the desired angle. Give a little
		# leeway so that we aren't bouncing between left and right.
		var angle_to_degrees = rad2deg(angle_to)
		if angle_to_degrees < -2.0:
			input.y = -1.0
		elif angle_to_degrees > 2.0:
			input.y = 1.0
		else:
			input.y = 0
		
		# Store the desired rotation, so we can snap to it.
		desired_rotation = desired_vector.angle()
	
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
		
		if GameSettings.control_scheme == GameSettings.ControlScheme.MODERN:
			# If our rotation is really close to the desired rotation, just
			# snap to it.
			if rad2deg(abs(desired_rotation - rotation)) < 3:
				rotation = desired_rotation
		
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
			if Input.is_action_pressed("player1_aim_up") or Input.is_action_pressed("player1_aim_down") or Input.is_action_pressed("player1_aim_left") or Input.is_action_pressed("player1_aim_right"):
				var joy_vector = Vector2()
				joy_vector.x = Input.get_action_strength("player1_aim_right") - Input.get_action_strength("player1_aim_left")
				joy_vector.y = Input.get_action_strength("player1_aim_down") - Input.get_action_strength("player1_aim_up")
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
		
		if using_ability:
			use_ability()
		
		if camera:
			camera.global_position = global_position
		
		rpc("update_remote_player", rotation, position, turret_pivot.rotation, visible, shooting, weapon_type.resource_path, using_ability, ability_type.resource_path if ability_type else null)
		
		shooting = false
		using_ability = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_control = true
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		mouse_control = false
	if event.is_action_pressed("player1_shoot") and can_shoot:
		shooting = true
	if event.is_action_pressed("player1_use_ability"):
		using_ability = true

puppet func update_remote_player(player_rotation: float, player_position: Vector2, turret_rotation: float, _visible: bool, _shooting: bool, _weapon_type_path: String, _using_ability: bool, _ability_type_path) -> void:
	rotation = player_rotation
	position = player_position
	turret_pivot.rotation = turret_rotation
	visible = _visible
	player_info_node.visible = _visible
	player_info_node.position = global_position + player_info_offset
	if weapon_type.resource_path != _weapon_type_path:
		set_weapon_type(load(_weapon_type_path))
	if _shooting:
		shoot()
	if _ability_type_path:
		if ability_type == null or ability_type.resource_path != _ability_type_path:
			set_ability_type(load(_ability_type_path))
	else:
		set_ability_type(null)
	if _using_ability:
		use_ability()

func shoot() -> void:
	hooks.dispatch_event("shoot", TankEvent.new(self))

func _hook_default_shoot(event: TankEvent) -> void:
	if not get_parent():
		return
	
	emit_signal("shoot")
	shoot_sound.play()
	weapon.fire_weapon()

func use_ability() -> void:
	hooks.dispatch_event("use_ability", TankEvent.new(self))

func _hook_default_use_ability(event: TankEvent):
	if not get_parent():
		return
	
	if ability:
		# If the last ability is still in effect, then we immediately stop it.
		if last_ability and is_instance_valid(last_ability) and is_a_parent_of(last_ability):
			_on_ability_finished(last_ability)
			
		ability.use_ability()
		if ability.charges <= 0:
			last_ability = ability
			set_ability_type(null)
		else:
			_update_ability_label()
	
func _on_ShootCooldownTimer_timeout() -> void:
	can_shoot = true

func take_damage(damage: int, attacker_id: int = -1, attack_vector: Vector2 = Vector2.ZERO) -> void:
	hooks.dispatch_event("take_damage", TakeDamageEvent.new(self, damage, attacker_id, attack_vector))

func _hook_default_take_damage(event: TakeDamageEvent) -> void:
	if player_controlled:
		if GameSettings.use_screenshake and camera:
			# Between 0.25 and 0.5 seems good
			camera.add_trauma(0.5)
		
		Globals.rumble.add_rumble(0.25)
	
	animation_player.play("Flash")
	
	emit_signal("hurt", event.damage, event.attacker_id, event.attack_vector)
	
	if is_network_master() and not invincible:
		health -= event.damage
		if health <= 0:
			rpc("die", event.attacker_id)
		else:
			rpc("update_health", health)

func restore_health(_health: int) -> void:
	hooks.dispatch_event("restore_health", RestoreHealthEvent.new(self, _health))

func _hook_default_restore_health(event: RestoreHealthEvent) -> void:
	if is_network_master():
		health += event.health
		if health > 100:
			health = 100
		rpc("update_health", health)

remotesync func update_health(_health) -> void:
	health = clamp(_health, 0, 100)
	player_info_node.update_health(health)

remotesync func die(killer_id: int = -1) -> void:
	hooks.dispatch_event("die", DieEvent.new(self, killer_id))

func _hook_default_die(event: DieEvent) -> void:
	if not dead:
		dead = true
		
		var explosion = Explosion.instance()
		get_parent().add_child(explosion)
		explosion.setup(global_position, 1.5, "fire")
		
		queue_free()
		
		emit_signal("player_dead", event.killer_id)
