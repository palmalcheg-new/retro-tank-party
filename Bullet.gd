extends Area2D

var vector := Vector2()

var speed = 300
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

func explode():
	queue_free()

func _on_Bullet_body_entered(body: PhysicsBody2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		explode()

func _on_LifetimeTimer_timeout() -> void:
	explode()
