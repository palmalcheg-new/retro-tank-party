extends Area2D

var Explosion = preload("res://src/objects/Explosion.tscn")

onready var bullet_sprite = $BulletPivot/Sprite

var player_id: int
var player_index: int
var target: Node2D = null
var vector := Vector2()

var speed = 700
var damage = 10
var target_seek_speed = 10

const BULLET_COLORS = {
	1: Rect2(570, 584, 16, 28),
	2: Rect2(407, 308, 16, 28),
	3: Rect2(391, 308, 16, 28),
	4: Rect2(560, 348, 16, 28),
}

func _ready():
	pass

func setup(_player_id: int, _player_index: int, _position: Vector2, _rotation: float, _target: Node2D) -> void:
	player_id = _player_id
	player_index = _player_index
	bullet_sprite.region_rect = BULLET_COLORS[player_index]
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
		body.take_damage(damage, player_id)
		explode("fire")
	else:
		explode("smoke")

func _on_LifetimeTimer_timeout() -> void:
	explode("smoke")
