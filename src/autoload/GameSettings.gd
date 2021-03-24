extends Node

var sound_volume := 1.0 setget set_sound_volume
var music_volume := 1.0 setget set_music_volume
var tank_engine_sounds := true setget set_tank_engine_sounds
var use_screenshake := true
var use_network_relay := 0 setget set_use_network_relay

const SETTINGS_KEYS = [
	'music_volume',
	'sound_volume',
	'tank_engine_sounds',
	'use_screenshake',
	'use_network_relay',
]

const SETTINGS_FILENAME = 'user://settings.json'

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

func set_use_network_relay(_use_network_relay: int) -> void:
	use_network_relay = _use_network_relay
	OnlineMatch.use_network_relay = _use_network_relay

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var file = File.new()
	if file.file_exists(SETTINGS_FILENAME):
		file.open(SETTINGS_FILENAME, File.READ)
		var result := JSON.parse(file.get_as_text())
		if result.result is Dictionary:
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
