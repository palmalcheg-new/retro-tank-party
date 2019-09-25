extends Area2D

var Explosion = preload("res://Explosion.tscn")

var vector := Vector2()

var speed = 700
var damage = 10

func _ready():
	pass

func setup(_position : Vector2, _rotation : float) -> void:
	position = _position
	rotation = _rotation
	vector = Vector2(1, 0).rotated(rotation)
	$LifetimeTimer.start()

func _process(delta: float) -> void:
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
