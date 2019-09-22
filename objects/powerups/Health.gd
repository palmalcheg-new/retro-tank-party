extends Area2D

var health = 20

func _ready():
	$AnimationPlayer.play("shine")

func _on_Health_body_entered(body: PhysicsBody2D) -> void:
	if body.has_method("restore_health"):
		body.rpc("restore_health", health)
	queue_free()
