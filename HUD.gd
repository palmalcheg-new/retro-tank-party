extends CanvasLayer

signal start

func _ready():
	pass

remotesync func show_message(text):
	$Message.text = text
	$Message.visible = true

func hide_message():
	$Message.visible = false

func show_start_button(label = "Start"):
	$StartButton.text = label
	$StartButton.visible = true

func hide_start_button():
	$StartButton.visible = false

func hide_all():
	$Message.visible = false
	$StartButton.visible = false

func _on_StartButton_pressed() -> void:
	emit_signal("start")
