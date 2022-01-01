extends SGArea2D

var Explosion = preload("res://src/objects/Explosion.tscn")

onready var lifetime_timer = $LifetimeTimer

var tank
var player_id: int
var player_index: int
var vector := SGFixed.vector2(0, 0)

var damage := 10

func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
	var _tank = data['tank']
	var global_fixed_transform: SGFixedTransform2D = _tank.bullet_start_position.get_global_fixed_transform()
	return {
		tank = _tank.get_path(),
		player_id = _tank.get_network_master(),
		player_index = _tank.player_index,
		fixed_position = global_fixed_transform.origin,
		fixed_rotation = global_fixed_transform.get_rotation(),
		damage = data['weapon_type'].damage,
	}

func _network_spawn(data: Dictionary) -> void:
	tank = get_node(data['tank'])
	player_id = data['player_id']
	player_index = data['player_index']
	fixed_position = data['fixed_position']
	fixed_rotation = data['fixed_rotation']
	vector = fixed_transform.x.copy()
	damage = data['damage']
	lifetime_timer.start()
	sync_to_physics_engine()

func _network_despawn() -> void:
	lifetime_timer.stop()

func _network_process(_delta: float, _input: Dictionary) -> void:
	check_collision()

func _save_state() -> Dictionary:
	var state = {
		vector = vector.copy(),
	}
	Utils.save_node_transform_state(self, state)
	return state

func _load_state(state: Dictionary) -> void:
	Utils.load_node_transform_state(self, state)
	vector = state['vector'].copy()
	sync_to_physics_engine()

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	Utils.interpolate_node_transform_state(self, old_state, new_state, weight)

func explode(type: String):
	if is_queued_for_deletion() or not is_inside_tree():
		return
	
	SyncManager.spawn("Explosion", get_parent(), Explosion, {
		fixed_position = fixed_position.copy(),
		scale = SGFixed.HALF,
		type = type,
	})

func can_hit(body: SGCollisionObject2D) -> bool:
	return body != tank

func check_collision() -> void:
	for body in get_overlapping_bodies():
		_on_bullet_collision(body)

func _on_bullet_collision(body: SGCollisionObject2D) -> void:
	if not can_hit(body):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage, player_id, vector.normalized())
		explode("fire")
	else:
		explode("smoke")

func _on_LifetimeTimer_timeout() -> void:
	# Overriden by child classes (namely "res://src/objects/Bullet.gd")
	pass
