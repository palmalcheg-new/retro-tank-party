extends "res://src/components/weapons/BaseBullet.gd"

onready var ray_cast: SGRayCast2D = $RayCast2D
onready var collision_shape: SGCollisionShape2D = $CollisionShape2D
onready var line: Line2D = $Line2D

var speed = 6116693
var growing := true
var bounces := 0

const LASER_COLORS := {
	1: Color("419fdd"),
	2: Color("2ecc71"),
	3: Color("e74c3c"),
	4: Color("5f5d55"),
}

func _ready():
	line.set_as_toplevel(true)
	line.global_position = Vector2(0, 0)
	lifetime_timer.wait_ticks = 8

func _network_spawn(data: Dictionary) -> void:
	._network_spawn(data)
	growing = true
	bounces = 0
	line.default_color = LASER_COLORS[player_index]
	line.add_point(fixed_position.to_float())

func _network_despawn() -> void:
	._network_despawn()
	line.clear_points()
	ray_cast.clear_exceptions()

func can_hit(body: SGCollisionObject2D) -> bool:
	# Only allow to hit ourselves after the first bounce.
	return bounces > 0 or body != tank

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['growing'] = growing
	state['bounces'] = bounces
	state['_points'] = line.points
	
	var exceptions := []
	for node in ray_cast.get_exceptions():
		if not node.is_inside_tree():
			continue
		var node_path = str(node.get_path())
		exceptions.append(node_path)
	state['exceptions'] = exceptions
	
	return state

func _load_state(state: Dictionary) -> void:
	growing = state['growing']
	bounces = state['bounces']
	line.points = state['_points']
	
	ray_cast.clear_exceptions()
	for node_path in state['exceptions']:
		var node = get_node(node_path)
		if node:
			ray_cast.add_exception(node)
	
	._load_state(state)

func _network_process(delta: float, input: Dictionary) -> void:
	# Note: We don't call the parent _network_process() on purpose.
	if growing:
		check_collision()
		
		var increment = vector.mul(speed)
		ray_cast.update_raycast_collision()
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			# bit 2 = bullets
			if collider.get_collision_mask_bit(2):
				set_global_fixed_position(ray_cast.get_collision_point())
			
				var collision_normal = ray_cast.get_collision_normal()
				#print ("[%s] collision normal: (%s, %s)" % [SyncManager.current_tick, collision_normal.x, collision_normal.y])
				if !(collision_normal.x == 0 and collision_normal.y == 0):
					vector = vector.bounce(collision_normal).normalized()
					#print ("[%s] vector: (%s, %s)" % [SyncManager.current_tick, vector.x, vector.y])
					fixed_rotation = vector.angle()
					#print ("[%s] angle: %s" % [SyncManager.current_tick, fixed_rotation])
				
				bounces += 1
			
			ray_cast.clear_exceptions()
			ray_cast.add_exception(collider)
		else:
			fixed_position.iadd(increment)
		
		sync_to_physics_engine()
		
		line.add_point(fixed_position.to_float())
		
		if bounces >= 5:
			growing = false
			lifetime_timer.stop()
	else:
		line.remove_point(0)
		if line.get_point_count() == 0:
			SyncManager.despawn(self)

func _on_LifetimeTimer_timeout() -> void:
	growing = false

