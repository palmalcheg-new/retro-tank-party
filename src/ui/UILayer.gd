extends CanvasLayer
class_name UILayer

onready var screens = $Screens
onready var cover = $Overlay/Cover
onready var message_label = $Overlay/Message
onready var back_button = $Overlay/BackButton

signal change_screen (name, screen)
signal back_button ()

var current_screen: Control = null setget _set_readonly_variable
var current_screen_name: String = '' setget _set_readonly_variable, get_current_screen_name

var _is_ready := false

func _set_readonly_variable(_value) -> void:
	pass

func _ready() -> void:
	for screen in screens.get_children():
		if screen.has_method('_setup_screen'):
			screen._setup_screen(self)
	
	_is_ready = true

func get_screens():
	return screens.get_children()

func get_current_screen_name() -> String:
	if current_screen:
		return current_screen.name
	return ''

remotesync func show_screen(name: String, info: Dictionary = {}) -> void:
	var screen = screens.get_node(name)
	if not screen:
		return
	
	hide_screen()
	screen.visible = true
	if screen.has_method("_show_screen"):
		screen.callv("_show_screen", [info])
	current_screen = screen
	
	if _is_ready:
		emit_signal("change_screen", name, screen)

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

func hide_all() -> void:
	hide_screen()
	hide_cover()
	hide_message()
	hide_back_button()

func go_back() -> void:
	emit_signal("back_button")

func _on_BackButton_pressed() -> void:
	go_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action('ui_cancel') and back_button.visible and event.is_pressed():
		get_tree().set_input_as_handled()
		go_back()