extends MyButton

onready var selected_sprite := $SelectedSprite

func _on_MenuButton_focus_entered() -> void:
	selected_sprite.visible = true

func _on_MenuButton_focus_exited() -> void:
	selected_sprite.visible = false

func _on_MenuButton_mouse_entered() -> void:
	grab_focus()
