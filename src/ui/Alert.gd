extends PanelContainer

onready var title_label := $VBoxContainer/TitleLabel
onready var content_label := $VBoxContainer/ContentLabel
onready var ok_button := $VBoxContainer/HBoxContainer/OkButton
onready var cancel_button := $VBoxContainer/HBoxContainer/CancelButton

signal completed (result)

func setup(title: String, content: String, ok_text: String = 'Ok', cancel_text: String = 'Cancel') -> void:
	title_label.text = title
	content_label.text = content
	ok_button.text = ok_text
	ok_button.focus.grab_without_sound()
	if cancel_text != '':
		cancel_button.text = cancel_text
		cancel_button.visible = true
	else:
		cancel_button.visible = false

func _on_OkButton_pressed() -> void:
	emit_signal("completed", true)

func _on_CancelButton_pressed() -> void:
	emit_signal("completed", false)
