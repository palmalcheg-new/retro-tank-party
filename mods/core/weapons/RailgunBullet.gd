extends "res://src/components/weapons/BaseBullet.gd"

onready var ray_cast: SGRayCast2D = $RayCast2D
onready var collision_shape: SGCollisionShape2D = $CollisionShape2D
onready var line: Line2D = $Line2D

var speed = 6116693
var growing := true
var bounces := 0
var first := true

func _ready():
	line.set_as_toplevel(true)
	line.global_position = Vector2(0, 0)
	lifetime_timer.wait_ticks = 8

func _network_spawn(data: Dictionary) -> void:
	._network_spawn(data)
	growing = true
	bounces = 0
	first = true
	line.default_color = Globals.art.get_tank_color(player_index)
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
	state['first'] = first
	state['_points'] = line.points
	
	var exceptions := []
	for node in ray_cast.get_exceptions():
		if not node.is_inside_tree():
			ray_cast.remove_exception(node)
			continue
		var node_path = str(node.get_path())
		exceptions.append(node_path)
	state['exceptions'] = exceptions
	
	return state

func _load_state(state: Dictionary) -> void:
	growing = state['growing']
	bounces = state['bounces']
	first = state['first']
	line.points = state['_points']
	
	ray_cast.clear_exceptions()
	for node_path in state['exceptions']:
		var node = get_node_or_null(node_path)
		if node:
			ray_cast.add_exception(node)
	
	._load_state(state)

func _network_process(delta: float, input: Dictionary) -> void:
	# Note: We don't call the parent _network_process() on purpose.
	
	if first:
		# In the first frame, we check collision at our original position.
		check_collision()
		first = false
	
	if growing:
		ray_cast.update_raycast_collision()
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			# bit 2 = bullets
			if collider.get_collision_mask_bit(2):
				set_global_fixed_position(ray_cast.get_collision_point())
			
				var collision_normal = ray_cast.get_collision_normal()
				if !(collision_normal.x == 0 and collision_normal.y == 0):
					vector = vector.bounce(collision_normal).normalized()
					fixed_rotation = vector.angle()
				
					bounces += 1
					
					ray_cast.clear_exceptions()
					ray_cast.add_exception(collider)
		else:
			fixed_position.iadd(vector.mul(speed))
		
		sync_to_physics_engine()
		check_collision()
		
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

