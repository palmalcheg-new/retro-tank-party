extends "res://src/ui/Screen.gd"

var PlayerStatus = preload("res://src/ui/PlayerStatus.tscn")

onready var status_container := $Panel/StatusContainer

func _show_screen(info: Dictionary = {}) -> void:
	clear_players()
	
	var players_score: Dictionary = info.get("players_score", {})
	
	for player in OnlineMatch.players.values():
		add_player(player.username, players_score.get(player.peer_id, 0), player.peer_id == 1)

func clear_players() -> void:
	for child in status_container.get_children():
		status_container.remove_child(child)
		child.queue_free()

func add_player(username: String, score: int, is_host: bool) -> void:
	var status = PlayerStatus.instance()
	status_container.add_child(status)
	status.initialize(username, str(score))
	status.host = is_host

