extends Node
class_name ControlFocusComponent

var _parent: Control
var _is_parent_ready := false
var _play_focus_sound := true
var _has_mouse_focus := false

func _ready() -> void:
	_parent = get_parent()
	
	yield(_parent, "ready")
	_is_parent_ready = true
	
	_parent.connect("mouse_entered", self, "_on_mouse_entered")
	_parent.connect("mouse_exited", self, "_on_mouse_exited")
	_parent.connect("focus_entered", self, "_on_focus_entered")

func grab_without_sound() -> void:
	_play_focus_sound = false
	_parent.grab_focus()
	_play_focus_sound = true

func _is_parent_disabled() -> bool:
	var disabled = _parent.get('disabled')
	if disabled == null:
		disabled = false
	return disabled

func _on_mouse_entered() -> void:
	if not _is_parent_disabled():
		_has_mouse_focus = true
		Sounds.play("Focus")

func _on_mouse_exited() -> void:
	if not _is_parent_disabled():
		_has_mouse_focus = false

func _on_focus_entered() -> void:
	if _play_focus_sound and not _has_mouse_focus:
		Sounds.play("Focus")

