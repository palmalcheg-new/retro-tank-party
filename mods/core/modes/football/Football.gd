extends "res://src/components/weapons/BaseBullet.gd"

var speed := 700
var frames_countdown := 5

func _physics_process(delta: float) -> void:
	position += vector * speed * delta
	if frames_countdown > 0:
		frames_countdown -= 1
	# @todo check that football is in bounds

func _on_Bullet_body_entered(body: PhysicsBody2D) -> void:
	# If it collided with the environment.
	if body.get_collision_layer_bit(0):
		# @todo How to synchronize this across clients?
		vector = Vector2.ZERO
	# If it collided with a tank.
	elif body.get_collision_layer_bit(1):
		# Prevent hitting self.
		if frames_countdown > 0 and body == tank:
			return
		
		# @todo How to ensure that only one tank holds the football?
		
		var previous_weapon_type = body.weapon_type
		# Can't preload() because that would cause a cyclic dependency.
		body.set_weapon_type(load("res://mods/core/weapons/football.tres"))
		body.weapon.previous_weapon_type = previous_weapon_type
		
		queue_free()

func _on_LifetimeTimer_timeout() -> void:
	vector = Vector2.ZERO
