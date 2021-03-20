extends Control

onready var label := $Label
onready var timer := $Timer

signal countdown_finished ()

var end_time := 0

func _ready() -> void:
	label.visible = false

func start_countdown(seconds: int) -> void:
	if seconds <= 0:
		return
	
	end_time = OS.get_system_time_secs() + seconds
	_update_label()
	label.visible = true
	timer.start()

func _update_label():
	var seconds_remaining: int = end_time - OS.get_system_time_secs()
	rpc("_update_remote_label", seconds_remaining)

remotesync func _update_remote_label(seconds_remaining: int) -> void:
	if seconds_remaining < 0:
		label.visible = false
		timer.stop()
		if is_network_master():
			emit_signal("countdown_finished")
	else:
		label.visible = true
	
	var minutes = seconds_remaining / 60
	var seconds = seconds_remaining % 60

	label.text = str(minutes) + ":" + str(seconds).pad_zeros(2)

func _on_Timer_timeout() -> void:
	_update_label()
