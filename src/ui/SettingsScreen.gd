extends "res://src/ui/Screen.gd"

onready var music_slider := $Panel/VBoxContainer/GridContainer/MusicSlider
onready var sound_slider := $Panel/VBoxContainer/GridContainer/SoundSlider
onready var tank_engine_sounds_field = $Panel/VBoxContainer/GridContainer/TankEngineSoundsOptions
onready var screenshake_field := $Panel/VBoxContainer/GridContainer/ScreenshakeOptions
onready var network_relay_field:= $Panel/VBoxContainer/GridContainer/NetworkRelayOptions

var _is_ready := false

func _ready() -> void:
	music_slider.value = GameSettings.music_volume
	sound_slider.value = GameSettings.sound_volume
	
	tank_engine_sounds_field.add_item("Enabled", true)
	tank_engine_sounds_field.add_item("Disabled", false)
	tank_engine_sounds_field.value = GameSettings.tank_engine_sounds
	
	screenshake_field.add_item("Enabled", true)
	screenshake_field.add_item("Disabled", false)
	screenshake_field.value = GameSettings.use_screenshake
	
	network_relay_field.add_item("Auto", OnlineMatch.NetworkRelay.AUTO)
	network_relay_field.add_item("Forced", OnlineMatch.NetworkRelay.FORCED)
	network_relay_field.add_item("Disabled", OnlineMatch.NetworkRelay.DISABLED)
	network_relay_field.value = GameSettings.use_network_relay
	
	_is_ready = true

func _show_screen(info: Dictionary = {}) -> void:
	music_slider.focus.grab_without_sound()
	ui_layer.show_back_button()

func _hide_screen() -> void:
	GameSettings.save_settings()

func _on_MusicSlider_value_changed(value: float) -> void:
	if _is_ready:
		Sounds.play("Select")
	GameSettings.music_volume = value

func _on_SoundSlider_value_changed(value: float) -> void:
	if _is_ready:
		Sounds.play("Select")
	GameSettings.sound_volume = value

func _on_TankEngineSoundsOptions_item_selected(value, index) -> void:
	GameSettings.tank_engine_sounds = value

func _on_ScreenshakeOptions_item_selected(value, _index) -> void:
	GameSettings.use_screenshake = value

func _on_NetworkRelayOptions_item_selected(value, _index) -> void:
	GameSettings.use_network_relay = value

func _on_DoneButton_pressed() -> void:
	Sounds.play("Select")
	ui_layer.go_back()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed('ui_accept'):
		get_tree().set_input_as_handled()
		_on_DoneButton_pressed()
