extends HSlider
class_name MySlider

var focus: ControlFocusComponent

func _ready() -> void:
	focus = ControlFocusComponent.new()
	add_child(focus)
