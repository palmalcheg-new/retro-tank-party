extends Area2D

onready var label := $Visual/OuterRect/InnerRect/Label
onready var collision_shape := $CollisionShape2D
onready var sound := $Sound

export (String) var letter := "P" setget set_letter

var _pickup

func _ready():
	$AnimationPlayer.play("shine")

func set_letter(_letter: String) -> void:
	if letter != _letter:
		letter = _letter
		if label == null:
			yield(self, "ready")
		label.text = _letter

func setup_pickup(pickup) -> void:
	_pickup = pickup
	set_letter(pickup.letter)

func _on_Powerup_body_entered(body: PhysicsBody2D) -> void:
	if _pickup:
		_pickup.pickup(body)
	
	visible = false
	collision_shape.set_deferred("disabled", true)
	sound.play()

func _on_Sound_finished() -> void:
	queue_free()
