extends MyButton

onready var original_modulate = modulate

export (float) var transparency := 0.75

func _ready() -> void:
	_show_transparent(false)

func _show_transparent(hover: bool) -> void:
	if hover:
		modulate = original_modulate
	else:
		modulate.a = transparency

func _on_mouse_entered() -> void:
	._on_mouse_entered()
	modulate = original_modulate


func _on_mouse_exited() -> void:
	._on_mouse_exited()
	modulate.a = transparency
