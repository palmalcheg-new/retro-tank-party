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

func _on_pressed() -> void:
	Sounds.play("Select" if button_type == OK else "Back")

