extends Node

onready var tween = $Tween

var current_song
var initial_volume_dbs := {}

func _ready() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			initial_volume_dbs[child.name] = child.volume_db

func play(song_name: String) -> void:
	var next_song = get_node(song_name)
	if !next_song or next_song.playing:
		return
	
	if current_song:
		next_song.volume_db = -40.0
		tween.interpolate_property(current_song, "volume_db", current_song.volume_db, -40.0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.interpolate_property(next_song, "volume_db", -40.0, initial_volume_dbs.get(next_song.name, 0.0), 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
	
	next_song.play()
	
	current_song = next_song

func _on_Tween_tween_completed(object: Object, key: NodePath) -> void:
	if object != current_song:
		object.stop()

