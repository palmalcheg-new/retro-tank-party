extends "res://objects/powerups/Powerup.gd"

func _on_Powerup_body_entered(body: PhysicsBody2D) -> void:
	if body.has_method("set_bullet_type"):
		body.set_bullet_type(Constants.BulletType.SPREAD)
	queue_free()