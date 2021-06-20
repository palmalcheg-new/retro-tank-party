extends "res://src/ui/Screen.gd"

var ScoreCounter = preload("res://src/components/modes/ScoreCounter.gd")
var PlayerStatus = preload("res://src/ui/PlayerStatus.tscn")

onready var status_container := $Panel/StatusContainer

func _show_screen(info: Dictionary = {}) -> void:
	clear_players()
	
	var score = ScoreCounter.new(info.get("score", {}))
	
	for id in score.entities:
		var entity = score.entities[id]
		add_player(entity.name, entity.score)

func clear_players() -> void:
	for child in status_container.get_children():
		status_container.remove_child(child)
		child.queue_free()

func add_player(username: String, score: int) -> void:
	var status = PlayerStatus.instance()
	status_container.add_child(status)
	status.initialize(username, str(score))

