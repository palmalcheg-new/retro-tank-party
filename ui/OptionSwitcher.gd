extends Control

onready var _forward_button = $VBoxContainer/ForwardButton
onready var _back_button = $VBoxContainer/BackButton
onready var _label = $VBoxContainer/Label
onready var _forward_texture = _forward_button.texture_normal
onready var _back_texture = _back_button.texture_normal

export (Color) var modulate_normal = Color(1.0, 1.0, 1.0, 1.0)
export (Color) var modulate_disabled = Color(0.5, 0.5, 0.5, 0.7)
export (Color) var modulate_pressed = Color(0.8, 0.8, 1.0, 1.0)

class Option:
	var label: String
	var value
	
	func _init(_label: String, _value = null):
		label = _label
		value = _value

var _options := []
var selected := 0 setget set_selected
var value setget set_value, get_value

onready var _label_normal_style_box = _label.get_stylebox("normal")
var _label_selected_style_box = preload("res://ui/option_switcher_label_stylebox.tres")

signal item_selected (value, index)

func _ready() -> void:
	_show_buttons(false)

func _show_buttons(show: bool) -> void:
	if show:
		_forward_button.texture_normal = _forward_texture
		_back_button.texture_normal = _back_texture
	else:
		_forward_button.texture_normal = null
		_back_button.texture_normal = null

func set_selected(_selected) -> bool:
	if _selected >= 0 and _selected < _options.size():
		selected = _selected
		_update_display()
		emit_signal("item_selected", _options[selected].value, selected)
	
	return selected == _selected

func _update_display() -> void:
	if selected >= 0 and selected < _options.size():
		_label.text = _options[selected].label
		_reset_button_colors()

func _reset_button_colors() -> void:
	_back_button.modulate = modulate_disabled if selected == 0 else modulate_normal
	_forward_button.modulate = modulate_disabled if selected == _options.size() - 1 else modulate_normal

func set_value(_value) -> void:
	for index in range(_options.size()):
		var option = _options[index]
		if option.value == _value:
			set_selected(index)
			return

func get_value():
	if _options.size() > 0:
		return _options[selected].value

func add_item(label: String, value = null) -> void:
	if value == null:
		value = label
	var option = Option.new(label, value)
	_options.push_back(option)
	_update_display()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		if set_selected(selected - 1):
			_back_button.modulate = modulate_pressed
		accept_event()
	elif event.is_action_pressed("ui_right"):
		if set_selected(selected + 1):
			_forward_button.modulate = modulate_pressed
		accept_event()
	elif event.is_action_released("ui_left") or event.is_action_released("ui_right"):
		_reset_button_colors()
		accept_event()

func _on_OptionSwitcher_mouse_entered() -> void:
	_show_buttons(true)

func _on_OptionSwitcher_mouse_exited() -> void:
	_show_buttons(false)

func _on_OptionSwitcher_focus_entered() -> void:
	_show_buttons(true)
	_label.add_stylebox_override("normal", _label_selected_style_box)

func _on_OptionSwitcher_focus_exited() -> void:
	_show_buttons(false)
	_label.add_stylebox_override("normal", _label_normal_style_box)

func _on_ForwardButton_pressed() -> void:
	set_selected(selected + 1)

func _on_BackButton_pressed() -> void:
	set_selected(selected - 1)
