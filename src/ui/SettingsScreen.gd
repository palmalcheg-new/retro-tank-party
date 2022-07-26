extends "res://src/ui/Screen.gd"

onready var scroll_container := $Panel/VBoxContainer/ScrollContainer
onready var field_container := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer
onready var music_slider := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/MusicSlider
onready var sound_slider := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/SoundSlider
onready var tank_engine_sounds_field = $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/TankEngineSoundsOptions
onready var full_screen_field = $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/FullScreenOptions
onready var language_field = $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/LanguageOptions
onready var screenshake_field := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/ScreenshakeOptions
onready var art_style_label := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/ArtStyleLabel
onready var art_style_field := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/ArtStyleOptions
onready var network_relay_label := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/NetworkRelayLabel
onready var network_relay_field := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/NetworkRelayOptions
onready var detailed_logging_label := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/DetailedLoggingLabel
onready var detailed_logging_field := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/DetailedLoggingOptions
onready var control_scheme_field := $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/ControlScheme
onready var gamepad_device_field = $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer/GamepadDeviceOptions

var _is_ready := false

func _ready() -> void:
	music_slider.value = GameSettings.music_volume
	sound_slider.value = GameSettings.sound_volume

	tank_engine_sounds_field.add_item("OPTION_DISABLED", false)
	tank_engine_sounds_field.add_item("OPTION_ENABLED", true)
	tank_engine_sounds_field.set_value(GameSettings.tank_engine_sounds, false)

	full_screen_field.add_item("OPTION_DISABLED", false)
	full_screen_field.add_item("OPTION_ENABLED", true)
	full_screen_field.set_value(GameSettings.use_full_screen, false)

	language_field.add_item("LANGUAGE_OPTION_DEFAULT", "default")
	language_field.add_item("English", "en")
	language_field.add_item("Español", "es")
	language_field.add_item("Deutsch", "de")
	language_field.add_item("Polski", "pl")
	language_field.add_item("Українська", "uk")
	language_field.add_item("Русский", "ru")
	language_field.add_item("日本語", "ja")
	language_field.add_item("简体中文", "zh_CN")
	language_field.add_item("繁體中文", "zh_TW")
	language_field.set_value(GameSettings.language, false)

	screenshake_field.add_item("OPTION_DISABLED", false)
	screenshake_field.add_item("OPTION_ENABLED", true)
	screenshake_field.set_value(GameSettings.use_screenshake, false)

	var art_styles = Modding.find_resources("art")
	for art_style_path in art_styles:
		var art_style = load(art_style_path)
		art_style_field.add_item(art_style.name, art_style_path)
	art_style_field.set_value(GameSettings.art_style, false)

	control_scheme_field.add_item("CONTROL_SCHEME_OPTION_MODERN", GameSettings.ControlScheme.MODERN)
	control_scheme_field.add_item("CONTROL_SCHEME_OPTION_RETRO", GameSettings.ControlScheme.RETRO)
	control_scheme_field.set_value(GameSettings.control_scheme, false)

	network_relay_field.add_item("NETWORK_RELAY_OPTION_DISABLED", GameSettings.NetworkRelay.DISABLED)
	network_relay_field.add_item("NETWORK_RELAY_OPTION_AUTO", GameSettings.NetworkRelay.AUTO)
	network_relay_field.add_item("NETWORK_RELAY_OPTION_FORCED", GameSettings.NetworkRelay.FORCED)
	#network_relay_field.add_item("NETWORK_RELAY_OPTION_FALLBACK_AUTO", GameSettings.NetworkRelay.FALLBACK)
	network_relay_field.add_item("NETWORK_RELAY_OPTION_FALLBACK_FORCED", GameSettings.NetworkRelay.FORCED_FALLBACK)
	network_relay_field.set_value(GameSettings.use_network_relay, false)

	if OS.can_use_threads():
		detailed_logging_field.add_item("OPTION_DISABLED", false)
		detailed_logging_field.add_item("OPTION_ENABLED", true)
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
	art_style_label.visible = not SyncManager.started
	art_style_field.visible = not SyncManager.started

	network_relay_label.visible = not SyncManager.started
	network_relay_field.visible = not SyncManager.started

	if OS.can_use_threads():
		detailed_logging_label.visible = not SyncManager.started
		detailed_logging_field.visible = not SyncManager.started

	scroll_container.scroll_vertical = 0
	language_field.focus.grab_without_sound()
	ui_layer.show_back_button()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_gamepad_options()

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

func _on_LanguageOptions_item_selected(value, index) -> void:
	GameSettings.language = value

func _on_ScreenshakeOptions_item_selected(value, _index) -> void:
	GameSettings.use_screenshake = value

func _on_ArtStyleOptions_item_selected(value, index) -> void:
	GameSettings.art_style = value

func _on_NetworkRelayOptions_item_selected(value, _index) -> void:
	GameSettings.use_network_relay = value

func _on_DetailedLoggingOptions_item_selected(value, index) -> void:
	GameSettings.use_detailed_logging = value

func _on_ControlScheme_item_selected(value, _index) -> void:
	GameSettings.control_scheme = value

func _on_GamepadDeviceOptions_item_selected(value, _index) -> void:
	GameSettings.joy_id = value

func _update_gamepad_options() -> void:
	if gamepad_device_field == null:
		return
	gamepad_device_field.clear_items()
	for joy_id in Input.get_connected_joypads():
		gamepad_device_field.add_item("%s: %s" % [joy_id + 1, Input.get_joy_name(joy_id)], joy_id)
	if gamepad_device_field.get_item_count() == 0:
		gamepad_device_field.add_item("%s: %s" % [1, tr("GAMEPAD_DEVICE_OPTION_DEFAULT")], 0)
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


