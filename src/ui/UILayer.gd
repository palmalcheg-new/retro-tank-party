extends CanvasLayer
class_name UILayer

onready var screens = $Screens
onready var cover = $Overlay/Cover
onready var message_label = $Overlay/Message
onready var back_button = $Overlay/BackButton
onready var alert = $Overlay/Alert

signal change_screen (name, screen, info)
signal back_button ()
signal alert_completed (result)

var current_screen: Control = null setget _set_readonly_variable
var current_screen_name: String = '' setget _set_readonly_variable, get_current_screen_name

var _is_ready := false

func _set_readonly_variable(_value) -> void:
	pass

func _ready() -> void:
	for screen in screens.get_children():
		_setup_screen(screen)

	_is_ready = true

func _save_state() -> Dictionary:
	return {
		_message_text = message_label.text,
		_message_visible = message_label.visible,
	}

func _load_state(state: Dictionary) -> void:
	message_label.text = state['_message_text']
	message_label.visible = state['_message_visible']

func add_screen(screen) -> void:
	screens.add_child(screen)
	_setup_screen(screen)

func _setup_screen(screen) -> void:
	screen.visible = false
	if screen.has_method('_setup_screen'):
		screen._setup_screen(self)

func get_screens():
	return screens.get_children()

func get_screen(name: String):
	return screens.get_node_or_null(name)

func get_current_screen_name() -> String:
	if current_screen:
		return current_screen.name
	return ''

remote func show_screen(name: String, info: Dictionary = {}) -> void:
	var screen = screens.get_node(name)
	if not screen:
		return

	hide_screen()
	screen.visible = true
	if screen.has_method("_show_screen"):
		screen.callv("_show_screen", [info])
	current_screen = screen

	if _is_ready:
		emit_signal("change_screen", name, screen, info)

func hide_screen() -> void:
	if current_screen and current_screen.has_method('_hide_screen'):
		current_screen._hide_screen()

	for screen in screens.get_children():
		screen.visible = false
	current_screen = null

func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true

func hide_message() -> void:
	message_label.visible = false

func show_cover() -> void:
	cover.visible = true

func hide_cover() -> void:
	cover.visible = false

func show_back_button() -> void:
	back_button.visible = true

func hide_back_button() -> void:
	back_button.visible = false

func show_alert(title: String, content: String, ok_text: String = 'BUTTON_OK', cancel_text: String = 'BUTTON_CANCEL') -> void:
	alert.setup(title, content, ok_text, cancel_text)
	alert.visible = true
	show_cover()
	show_back_button()

func hide_alert(result: bool = false) -> void:
	alert.visible = false
	hide_cover()
	emit_signal("alert_completed", result)

func _on_Alert_completed(result) -> void:
	hide_alert(result)

func hide_all() -> void:
	hide_screen()
	hide_cover()
	hide_message()
	hide_back_button()

func go_back() -> void:
	if alert.visible:
		hide_alert()
	else:
		emit_signal("back_button")

func _on_BackButton_pressed() -> void:
	go_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action('ui_cancel') and back_button.visible and event.is_pressed():
		Sounds.play("Back")
		get_tree().set_input_as_handled()
		go_back()

