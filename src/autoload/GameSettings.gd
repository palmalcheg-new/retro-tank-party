extends Node

var sound_volume_db := 0.0 setget set_sound_volume_db
var music_volume_db := 0.0 setget set_music_volume_db
var use_network_relay := 0 setget set_use_network_relay
var use_screenshake := true

const SETTINGS_KEYS = [
	'sound_volume_db',
	'music_volume_db',
	'use_network_relay',
	'use_screenshake',
]

const SETTINGS_FILENAME = 'user://settings.json'

func set_sound_volume_db(_sound_volume_db: float) -> void:
	sound_volume_db = _sound_volume_db
	
	var bus_index = AudioServer.get_bus_index("Sound")
	if sound_volume_db <= -40.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, sound_volume_db)

func set_music_volume_db(_music_volume_db: float) -> void:
	music_volume_db = _music_volume_db
	
	var bus_index = AudioServer.get_bus_index("Music")
	if music_volume_db <= -40.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, music_volume_db)

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
