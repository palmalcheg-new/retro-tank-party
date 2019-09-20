extends AnimatedSprite

func _ready():
	pass

func setup(_position : Vector2, _scale : float, _anim : String) -> void:
	position = _position
	scale = Vector2(_scale, _scale)
	play(_anim)

func _on_Explosion_animation_finished() -> void:
	queue_free()
