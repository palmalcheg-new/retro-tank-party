extends Area2D

onready var label := $Visual/OuterRect/InnerRect/Label
onready var outer_rect := $Visual/OuterRect
onready var collision_shape := $CollisionShape2D
onready var sound := $Sound

export (String) var letter := "P" setget set_letter
export (Color) var color := Color('#00ff00') setget set_color

var _pickup

func _ready():
	$AnimationPlayer.play("shine")

func set_letter(_letter: String) -> void:
	if letter != _letter:
		letter = _letter
		if label == null:
			yield(self, "ready")
		label.text = _letter

func set_color(_color: Color) -> void:
	if label == null:
		yield(self, "ready")
	color = _color
	outer_rect.color = color
	label.add_color_override("font_color", color)

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
