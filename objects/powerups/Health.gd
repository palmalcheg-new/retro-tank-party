extends "res://objects/powerups/Powerup.gd"

var health = 20

func _on_Powerup_body_entered(body: PhysicsBody2D) -> void:
	if body.has_method("restore_health"):
		body.restore_health(health)
	queue_free()
