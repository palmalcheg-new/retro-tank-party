extends CPUParticles2D

func _ready() -> void:
	one_shot = true

func _on_Timer_timeout() -> void:
	queue_free()
