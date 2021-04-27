extends Control

onready var _forward_button = $VBoxContainer/ForwardButton
onready var _back_button = $VBoxContainer/BackButton
onready var _label = $VBoxContainer/Label
onready var _forward_texture = _forward_button.texture_normal
onready var _back_texture = _back_button.texture_normal

export (Color) var modulate_normal = Color(0.6, 0.6, 0.6, 1.0)
export (Color) var modulate_disabled = Color(0.8, 0.8, 0.8, 0.7)
export (Color) var modulate_pressed = Color(1.0, 1.0, 1.0, 1.0)

class Option:
	var label: String
	var value
	var color
	
	func _init(_label: String, _value = null, _color = null):
		label = _label
		value = _value
		color = _color

var _options := []
var selected := 0 setget set_selected
var disabled := false setget set_disabled
var value setget set_value, get_value

var focus: ControlFocusComponent

onready var _label_default_color = _label.get_color("font_color")
onready var _label_normal_style_box = _label.get_stylebox("normal")
var _label_selected_style_box = preload("res://assets/ui/grey_button5_stylebox.tres")

signal item_selected (value, index)

func _ready() -> void:
	focus = ControlFocusComponent.new()
	add_child(focus)
	
	_show_buttons(false)

func _show_buttons(show: bool) -> void:
	if show:
		_forward_button.texture_normal = _forward_texture
		_back_button.texture_normal = _back_texture
	else:
		_forward_button.texture_normal = null
		_back_button.texture_normal = null

func set_selected(_selected, emit_signal: bool = true) -> bool:
	if _selected >= 0 and _selected < _options.size():
		selected = _selected
		_update_display()
		if emit_signal:
			emit_signal("item_selected", _options[selected].value, selected)
	
	return selected == _selected

func set_disabled(_disabled) -> void:
	disabled = _disabled
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	_reset_button_colors()

func _update_display() -> void:
	if selected >= 0 and selected < _options.size():
		var option = _options[selected]
		_label.text = option.label
		_label.add_color_override("font_color", option.color if option.color != null else _label_default_color)
		_reset_button_colors()

func _reset_button_colors() -> void:
	_back_button.modulate = modulate_disabled if disabled or selected == 0 else modulate_normal
	_forward_button.modulate = modulate_disabled if disabled or selected == _options.size() - 1 else modulate_normal

func set_value(_value, emit_signal: bool = true) -> void:
	for index in range(_options.size()):
		var option = _options[index]
		if option.value == _value:
			set_selected(index, emit_signal)
			return

func get_value():
	if _options.size() > 0:
		return _options[selected].value

func add_item(label: String, value = null, color = null) -> void:
	if value == null:
		value = label
	var option = Option.new(label, value, color)
	_options.push_back(option)
	_update_display()

func clear_items() -> void:
	_options.clear()
	selected = 0
	_label.text = ''
	_reset_button_colors()

func get_item_count() -> int:
	return _options.size()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		if set_selected(selected - 1):
			Sounds.play("Select")
			_back_button.modulate = modulate_pressed
		accept_event()
	elif event.is_action_pressed("ui_right"):
		if set_selected(selected + 1):
			Sounds.play("Select")
			_forward_button.modulate = modulate_pressed
		accept_event()
	elif event.is_action_released("ui_left") or event.is_action_released("ui_right"):
		_reset_button_colors()
		accept_event()

func _on_OptionSwitcher_mouse_entered() -> void:
	if not has_focus():
		_show_buttons(true)

func _on_OptionSwitcher_mouse_exited() -> void:
	if not has_focus():
		_show_buttons(false)

func _on_OptionSwitcher_focus_entered() -> void:
	_show_buttons(true)
	_label.add_stylebox_override("normal", _label_selected_style_box)

func _on_OptionSwitcher_focus_exited() -> void:
	_show_buttons(false)
	_label.add_stylebox_override("normal", _label_normal_style_box)

func _on_BackButton_button_down() -> void:
	if not disabled and selected > 0:
		_back_button.modulate = modulate_pressed

func _on_BackButton_button_up() -> void:
	if not disabled and set_selected(selected - 1):
		Sounds.play("Select")
		_reset_button_colors()

func _on_ForwardButton_button_down() -> void:
	if not disabled and selected < _options.size():
		_forward_button.modulate = modulate_pressed

func _on_ForwardButton_button_up() -> void:
	if not disabled and set_selected(selected + 1):
		Sounds.play("Select")
		_reset_button_colors()
