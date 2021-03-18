extends "res://src/main/Screen.gd"

onready var music_slider := $Panel/VBoxContainer/GridContainer/MusicSlider
onready var sound_slider := $Panel/VBoxContainer/GridContainer/SoundSlider
onready var screenshake_field := $Panel/VBoxContainer/GridContainer/ScreenshakeOptions
onready var network_relay_field:= $Panel/VBoxContainer/GridContainer/NetworkRelayOptions

func _ready() -> void:
	screenshake_field.add_item("Enabled", true)
	screenshake_field.add_item("Disabled", false)
	screenshake_field.value = GameSettings.use_screenshake
	
	network_relay_field.add_item("Auto", OnlineMatch.NetworkRelay.AUTO)
	network_relay_field.add_item("Forced", OnlineMatch.NetworkRelay.FORCED)
	network_relay_field.add_item("Disabled", OnlineMatch.NetworkRelay.DISABLED)
	network_relay_field.value = GameSettings.use_network_relay

func _show_screen(info: Dictionary = {}) -> void:
	music_slider.grab_focus()

func _hide_screen() -> void:
	GameSettings.save_settings()

func _on_ScreenshakeOptions_item_selected(value, _index) -> void:
	GameSettings.use_screenshake = value

func _on_NetworkRelayOptions_item_selected(value, _index) -> void:
	GameSettings.use_network_relay = value

func _on_DoneButton_pressed() -> void:
	ui_layer.go_back()
