extends Area2D

func _ready():
	$AnimationPlayer.play("shine")

func _on_Powerup_body_entered(body: PhysicsBody2D) -> void:
	queue_free()
