extends Button
class_name MyButton

enum ButtonType {
	OK,
	CANCEL,
}
export (ButtonType) var button_type := ButtonType.OK

var focus: ControlFocusComponent

func _ready() -> void:
	focus = ControlFocusComponent.new()
	add_child(focus)
	
	self.connect("pressed", self, "_on_pressed")

#func grab_focus_without_sound() -> void:
#	_play_focus_sound = false
#	grab_focus()
#	_play_focus_sound = true
#
#func _on_mouse_entered() -> void:
#	Sounds.play("Focus")
#
#func _on_mouse_exited() -> void:
#	pass
#
#func _on_focus_entered() -> void:
#	if _play_focus_sound:
#		Sounds.play("Focus")

func _on_pressed() -> void:
	Sounds.play("Select" if button_type == OK else "Back")

