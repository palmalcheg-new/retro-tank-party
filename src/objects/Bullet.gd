extends "res://src/components/weapons/BaseBullet.gd"

onready var bullet_sprite = $BulletPivot/Sprite

var speed = 700

const BULLET_COLORS = {
	1: Rect2(570, 584, 16, 28),
	2: Rect2(407, 308, 16, 28),
	3: Rect2(391, 308, 16, 28),
	4: Rect2(560, 348, 16, 28),
}

func setup_bullet(_player_id: int, _player_index: int, _position: Vector2, _rotation: float) -> void:
	.setup_bullet(_player_id, _player_index, _position, _rotation)
	bullet_sprite.region_rect = BULLET_COLORS[player_index]

func explode(type: String) -> void:
	.explode(type)
	queue_free()

func _process(delta: float) -> void:
	position += vector * speed * delta

func _on_LifetimeTimer_timeout() -> void:
	explode("smoke")
