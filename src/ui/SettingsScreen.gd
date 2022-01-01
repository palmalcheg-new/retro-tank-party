extends "res://src/ui/Screen.gd"

onready var scroll_container := $Panel/VBoxContainer/ScrollContainer
onready var field_container := $Panel/VBoxContainer/ScrollContainer/GridContainer
onready var music_slider := $Panel/VBoxContainer/ScrollContainer/GridContainer/MusicSlider
onready var sound_slider := $Panel/VBoxContainer/ScrollContainer/GridContainer/SoundSlider
onready var tank_engine_sounds_field = $Panel/VBoxContainer/ScrollContainer/GridContainer/TankEngineSoundsOptions
onready var full_screen_field = $Panel/VBoxContainer/ScrollContainer/GridContainer/FullScreenOptions
onready var screenshake_field := $Panel/VBoxContainer/ScrollContainer/GridContainer/ScreenshakeOptions
onready var network_relay_label := $Panel/VBoxContainer/ScrollContainer/GridContainer/NetworkRelayLabel
onready var network_relay_field := $Panel/VBoxContainer/ScrollContainer/GridContainer/NetworkRelayOptions
onready var detailed_logging_label := $Panel/VBoxContainer/ScrollContainer/GridContainer/DetailedLoggingLabel
onready var detailed_logging_field := $Panel/VBoxContainer/ScrollContainer/GridContainer/DetailedLoggingOptions
onready var control_scheme_field := $Panel/VBoxContainer/ScrollContainer/GridContainer/ControlScheme
onready var gamepad_device_field = $Panel/VBoxContainer/ScrollContainer/GridContainer/GamepadDeviceOptions

var _is_ready := false

func _ready() -> void:
	music_slider.value = GameSettings.music_volume
	sound_slider.value = GameSettings.sound_volume
	
	tank_engine_sounds_field.add_item("Disabled", false)
	tank_engine_sounds_field.add_item("Enabled", true)
	tank_engine_sounds_field.set_value(GameSettings.tank_engine_sounds, false)
	
	full_screen_field.add_item("Disabled", false)
	full_screen_field.add_item("Enabled", true)
	full_screen_field.set_value(GameSettings.use_full_screen, false)
	
	screenshake_field.add_item("Disabled", false)
	screenshake_field.add_item("Enabled", true)
	screenshake_field.set_value(GameSettings.use_screenshake, false)
	
	control_scheme_field.add_item("Modern", GameSettings.ControlScheme.MODERN)
	control_scheme_field.add_item("Retro", GameSettings.ControlScheme.RETRO)
	control_scheme_field.set_value(GameSettings.control_scheme, false)
	
	network_relay_field.add_item("Disabled", GameSettings.NetworkRelay.DISABLED)
	network_relay_field.add_item("Auto", GameSettings.NetworkRelay.AUTO)
	network_relay_field.add_item("Forced", GameSettings.NetworkRelay.FORCED)
	#network_relay_field.add_item("Fallback (Auto)", GameSettings.NetworkRelay.FALLBACK)
	#network_relay_field.add_item("Fallback (Forced)", GameSettings.NetworkRelay.FORCED_FALLBACK)
	network_relay_field.set_value(GameSettings.use_network_relay, false)
	
	if OS.can_use_threads():
		detailed_logging_field.add_item("Disabled", false)
		detailed_logging_field.add_item("Enabled", true)
		detailed_logging_field.set_value(GameSettings.use_detailed_logging, false)
	else:
		# Detailed logs only work if we have threads, so hide option otherwise.
		detailed_logging_label.visible = false
		detailed_logging_field.visible = false
	
	_update_gamepad_options()
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")
	
	_setup_field_neighbors()
	
	_is_ready = true

func _setup_field_neighbors() -> void:
	var previous_neighbor = null;
	for child in field_container.get_children():
		if not child.visible:
			continue
		if previous_neighbor:
			previous_neighbor.focus_neighbour_bottom = child.get_path()
			previous_neighbor.focus_next = child.get_path()
			child.focus_neighbour_top = previous_neighbor.get_path()
			child.focus_previous = previous_neighbor.get_path()
		previous_neighbor = child

func _show_screen(info: Dictionary = {}) -> void:
	network_relay_label.visible = not SyncManager.started
	network_relay_field.visible = not SyncManager.started
	
	if OS.can_use_threads():
		detailed_logging_label.visible = not SyncManager.started
		detailed_logging_field.visible = not SyncManager.started
	
	scroll_container.scroll_vertical = 0
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

func _on_FullScreenOptions_item_selected(value, index) -> void:
	GameSettings.use_full_screen = value

func _on_ScreenshakeOptions_item_selected(value, _index) -> void:
	GameSettings.use_screenshake = value

func _on_NetworkRelayOptions_item_selected(value, _index) -> void:
	GameSettings.use_network_relay = value

func _on_DetailedLoggingOptions_item_selected(value, index) -> void:
	GameSettings.use_detailed_logging = value

func _on_ControlScheme_item_selected(value, _index) -> void:
	GameSettings.control_scheme = value

func _on_GamepadDeviceOptions_item_selected(value, _index) -> void:
	GameSettings.joy_id = value

func _update_gamepad_options() -> void:
	gamepad_device_field.clear_items()
	for joy_id in Input.get_connected_joypads():
		gamepad_device_field.add_item("%s: %s" % [joy_id + 1, Input.get_joy_name(joy_id)], joy_id)
	if gamepad_device_field.get_item_count() == 0:
		gamepad_device_field.add_item("1: Default", 0)
	gamepad_device_field.set_value(GameSettings.joy_id, false)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	_update_gamepad_options()

func _on_DoneButton_pressed() -> void:
	Sounds.play("Select")
	ui_layer.go_back()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed('ui_accept'):
		get_tree().set_input_as_handled()
		_on_DoneButton_pressed()
