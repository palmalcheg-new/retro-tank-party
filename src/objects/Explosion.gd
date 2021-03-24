extends AnimatedSprite

onready var sounds = $Sounds

var animation_finished := false
var sound_finished := false

func setup(_position: Vector2, _scale: float, _anim: String) -> void:
	position = _position
	scale = Vector2(_scale, _scale)
	play(_anim)
	
	yield(get_tree().create_timer(randf() * 0.150), "timeout")
	
	if _anim == 'smoke':
		sounds.play('Miss')
	else:
		if _scale > 1.0:
			sounds.play('Big')
		else:
			sounds.play('Hit')

func _on_Explosion_animation_finished() -> void:
	visible = false
	animation_finished = true
	if sound_finished:
		queue_free()

func _on_Sounds_finished() -> void:
	sound_finished = true
	if animation_finished:
		queue_free()
