extends Node

enum ControlScheme {
	MODERN,
	RETRO,
}

enum NetworkRelay {
	AUTO = OnlineMatch.NetworkRelay.AUTO,
	FORCED = OnlineMatch.NetworkRelay.FORCED,
	DISABLED = OnlineMatch.NetworkRelay.DISABLED,
	FALLBACK,
	FORCED_FALLBACK,
}

var art_style := "res://mods/core/art/classic.tres" setget set_art_style
var sound_volume := 1.0 setget set_sound_volume
var music_volume := 1.0 setget set_music_volume
var tank_engine_sounds := true setget set_tank_engine_sounds
var use_full_screen := false setget set_use_full_screen
var use_screenshake := true
var use_network_relay := 0 setget set_use_network_relay
var use_detailed_logging := false
var control_scheme: int = ControlScheme.MODERN
var joy_id := 0 setget set_joy_id
var joy_name := "" setget set_joy_name
var language := "" setget set_language

const SETTINGS_KEYS = [
	'art_style',
	'music_volume',
	'sound_volume',
	'tank_engine_sounds',
	'use_full_screen',
	'language',
	'use_screenshake',
	'use_network_relay',
	'use_detailed_logging',
	'control_scheme',
	'joy_name',
]

const SETTINGS_FILENAME = 'user://settings.json'

func _ready() -> void:
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")
	joy_name = Input.get_joy_name(joy_id)
	load_settings()

	if language == '':
		# Set language to default for players that upgrade from older versions.
		set_language('default')
	elif language == 'default':
		# Determine the default language and enable it.
		update_language()

func set_art_style(_art_style: String) -> void:
	art_style = _art_style
	Globals.art.load_art_style(art_style)

func set_music_volume(_music_volume: float) -> void:
	music_volume = _music_volume

	var bus_index = AudioServer.get_bus_index("Music (User)")
	if music_volume < 0.05:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear2db(music_volume))

func set_sound_volume(_sound_volume: float) -> void:
	sound_volume = _sound_volume

	var bus_index = AudioServer.get_bus_index("Sound (User)")
	if sound_volume < 0.05:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear2db(sound_volume))

func set_tank_engine_sounds(_tank_engine_sounds: bool) -> void:
	tank_engine_sounds = _tank_engine_sounds
	var bus_index = AudioServer.get_bus_index("Tank Engine")
	AudioServer.set_bus_mute(bus_index, !_tank_engine_sounds)

func set_use_full_screen(_use_full_screen: bool) -> void:
	use_full_screen = _use_full_screen
	OS.window_fullscreen = use_full_screen

func set_use_network_relay(_use_network_relay: int) -> void:
	use_network_relay = _use_network_relay
	match use_network_relay:
		NetworkRelay.AUTO, NetworkRelay.FORCED, NetworkRelay.DISABLED:
			OnlineMatch.use_network_relay = use_network_relay
		NetworkRelay.FALLBACK:
			OnlineMatch.use_network_relay = OnlineMatch.NetworkRelay.AUTO
		NetworkRelay.FORCED_FALLBACK:
			OnlineMatch.use_network_relay = OnlineMatch.NetworkRelay.FORCED

func set_joy_id(_joy_id: int) -> void:
	if joy_id != _joy_id:
		joy_id = _joy_id

		# Remap all the events
		for action in InputMap.get_actions():
			for event in InputMap.get_action_list(action):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					event.device = joy_id

		joy_name = Input.get_joy_name(joy_id)

func set_joy_name(_joy_name: String) -> void:
	if joy_name != _joy_name:
		for joy_id in Input.get_connected_joypads():
			if Input.get_joy_name(joy_id) == _joy_name:
				set_joy_id(joy_id)
				return

		# If no matching joystick is found, then set the device id to 0.
		set_joy_id(0)

func set_language(_lang_code: String) -> void:
	if language != _lang_code:
		language = _lang_code
		update_language()

func update_language() -> void:
	var locale = language
	print ("Settings language: ", language)
	if language == 'default':
		if SteamManager.use_steam:
			var steam_language = SteamManager.Steam.getCurrentGameLanguage()
			print ("Steam language: ", steam_language)
			match steam_language:
				"english":
					locale = "en"
				"spanish", "latam":
					locale = "es"
				_:
					locale = OS.get_locale_language()
		else:
			locale = OS.get_locale_language()

	print ("Current locale: ", TranslationServer.get_locale())
	print ("New locale: ", locale)
	if TranslationServer.get_locale() != locale:
		TranslationServer.set_locale(locale)
		print ("Language updated")
		get_node("/root").propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		# Switch to whatever the newly connected joystick is.
		set_joy_id(device)
	elif joy_id == device:
		# Our current gamepad has just been disconnected, so switch back to 0.
		set_joy_id(0)

func load_settings() -> void:
	var file = File.new()
	if file.file_exists(SETTINGS_FILENAME):
		file.open(SETTINGS_FILENAME, File.READ)
		var result := JSON.parse(file.get_as_text())
		if result.result is Dictionary:
			# For existing players, we want to default the control scheme to
			# retro, and only default to modern for new players.
			if not result.result.has("control_scheme"):
				result.result['control_scheme'] = ControlScheme.RETRO

			for k in result.result:
				if k in SETTINGS_KEYS:
					set(k, result.result[k])
		file.close()

func save_settings() -> void:
	var settings := {}
	for k in SETTINGS_KEYS:
		settings[k] = get(k)

	var file = File.new()
	file.open(SETTINGS_FILENAME, File.WRITE)
	file.store_line(JSON.print(settings))
	file.close()
