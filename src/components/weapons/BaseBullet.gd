extends Area2D

var Explosion = preload("res://src/objects/Explosion.tscn")

onready var lifetime_timer = $LifetimeTimer

var player_id: int
var player_index: int
var vector := Vector2()

var damage = 10

func setup_bullet(_player_id: int, _player_index: int, _position: Vector2, _rotation: float) -> void:
	player_id = _player_id
	player_index = _player_index
	position = _position
	rotation = _rotation
	vector = Vector2(1, 0).rotated(rotation)
	lifetime_timer.start()

func explode(type: String):
	var explosion = Explosion.instance()
	get_parent().add_child(explosion)
	explosion.setup(global_position, 0.5, type)

func _on_Bullet_body_entered(body: PhysicsBody2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, player_id)
		explode("fire")
	else:
		explode("smoke")

func _on_LifetimeTimer_timeout() -> void:
	pass # Replace with function body.
