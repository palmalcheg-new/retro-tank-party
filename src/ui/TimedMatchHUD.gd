extends Control

onready var countdown_timer := $CountdownTimer
onready var instant_death_label := $InstantDeathLabel
onready var score := $ScoreHUD

func set_instant_death_text(text: String) -> void:
	instant_death_label.text = text

remotesync func show_instant_death_label() -> void:
	instant_death_label.visible = true
