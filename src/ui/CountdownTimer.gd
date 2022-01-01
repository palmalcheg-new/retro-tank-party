extends Control

onready var label := $Label
onready var timer := $Timer

signal countdown_finished ()

var seconds_remaining := 0

func _ready() -> void:
	label.visible = false

func _save_state() -> Dictionary:
	return {
		seconds_remaining = seconds_remaining,
	}

func _load_state(state: Dictionary) -> void:
	seconds_remaining = state['seconds_remaining']

func start_countdown(seconds: int) -> void:
	if seconds <= 0:
		return
	
	seconds_remaining = seconds
	_update_countdown()
	label.visible = true
	timer.start()

func _update_countdown():
	if seconds_remaining < 0:
		label.visible = false
		timer.stop()
		emit_signal("countdown_finished")
	else:
		label.visible = true
	
	var minutes = seconds_remaining / 60
	var seconds = seconds_remaining % 60

	label.text = str(minutes) + ":" + str(seconds).pad_zeros(2)

func _on_Timer_timeout() -> void:
	seconds_remaining -= 1
	_update_countdown()
