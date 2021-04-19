extends Area2D

var Explosion = preload("res://src/objects/Explosion.tscn")

onready var lifetime_timer = $LifetimeTimer

var tank
var player_id: int
var player_index: int
var vector := Vector2()

var damage := 10

func setup_bullet(_tank, weapon_type) -> void:
	tank = _tank
	player_id = tank.get_network_master()
	player_index = tank.player_index
	position = tank.bullet_start_position.global_position
	rotation = tank.turret_pivot.global_rotation
	vector = Vector2.RIGHT.rotated(rotation)
	damage = weapon_type.damage
	lifetime_timer.start()

func explode(type: String):
	var explosion = Explosion.instance()
	get_parent().add_child(explosion)
	explosion.setup(global_position, 0.5, type)

func can_hit(body: PhysicsBody2D) -> bool:
	return body != tank

func _on_Bullet_body_entered(body: PhysicsBody2D) -> void:
	if not can_hit(body):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage, player_id)
		explode("fire")
	else:
		explode("smoke")

func _on_LifetimeTimer_timeout() -> void:
	pass # Replace with function body.
