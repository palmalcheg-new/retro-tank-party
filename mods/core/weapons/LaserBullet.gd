extends "res://src/components/weapons/BaseBullet.gd"

onready var ray_cast := $RayCast2D
onready var line := $Line2D

var speed = 2800
var growing := true

#const LASER_COLORS := {
#	1: Color("419fdd"),
#	2: Color("2ecc71"),
#	3: Color("e74c3c"),
#	4: Color("5f5d55"),
#}

func _ready():
	line.set_as_toplevel(true)
	line.global_position = Vector2(0, 0)

func setup_bullet(_player_id: int, _player_index: int, _position: Vector2, _rotation: float) -> void:
	.setup_bullet(_player_id, _player_index, _position, _rotation)
	#line.default_color = LASER_COLORS[_player_index]
	line.add_point(global_position)

func _physics_process(delta: float) -> void:
	if growing:
		var increment = vector * delta * speed
		ray_cast.cast_to = Vector2(increment.length(), 0)
		ray_cast.force_raycast_update()
		if ray_cast.is_colliding():
			global_position = ray_cast.get_collision_point()
			
			var collider = ray_cast.get_collider()
			# bit 2 = bullets
			if collider.get_collision_mask_bit(2):
				var collision_normal = ray_cast.get_collision_normal()
				if collision_normal != Vector2.ZERO:
					vector = vector.bounce(collision_normal).normalized()
					rotation = vector.angle()
			
			ray_cast.clear_exceptions()
			ray_cast.add_exception(collider)
		else:
			global_position += increment
		
		line.add_point(global_position)
	else:
		line.remove_point(0)
		if line.points.size() == 0:
			queue_free()

func _on_LifetimeTimer_timeout() -> void:
	growing = false

