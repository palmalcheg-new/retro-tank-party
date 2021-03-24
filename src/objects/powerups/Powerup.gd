extends Area2D

onready var collision_shape := $CollisionShape2D
onready var sound := $Sound

func _ready():
	$AnimationPlayer.play("shine")

func _on_Powerup_body_entered(body: PhysicsBody2D) -> void:
	visible = false
	collision_shape.set_deferred("disabled", true)
	sound.play()

func _on_Sound_finished() -> void:
	queue_free()
