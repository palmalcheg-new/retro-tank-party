extends Area2D

var Explosion = preload("res://Explosion.tscn")

var target : Node2D = null
var vector := Vector2()

var speed = 700
var damage = 10
var target_seek_speed = 10

func _ready():
	pass

func setup(_position : Vector2, _rotation : float, _target : Node2D) -> void:
	position = _position
	rotation = _rotation
	target = _target
	vector = Vector2(1, 0).rotated(rotation)
	$LifetimeTimer.start()

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var target_vector = (target.global_position - global_position).normalized()
		vector = vector.linear_interpolate(target_vector, target_seek_speed * delta).normalized()
		rotation = vector.angle()
	
	position += vector * speed * delta

func explode(type : String = "smoke"):
	var explosion = Explosion.instance()
	get_parent().add_child(explosion)
	
	explosion.setup(global_position, 0.5, type)
	
	queue_free()

func _on_Bullet_body_entered(body: PhysicsBody2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		explode("fire")
	else:
		explode("smoke")

func _on_LifetimeTimer_timeout() -> void:
	explode("smoke")
