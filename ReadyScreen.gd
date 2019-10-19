extends Control

var PeerStatus = preload("res://PeerStatus.tscn");

signal ready_pressed ()

func _ready():
	for child in $Panel/StatusContainer.get_children():
		child.queue_free()
	$Panel/ReadyButton.disabled = true

func initialize(players, match_id = ''):
	if match_id:
		$Panel/MatchIDContainer.visible = true
		$Panel/MatchIDContainer/MatchID.text = match_id
	else:
		$Panel/MatchIDContainer.visible = false
	
	for session_id in players:
		add_player(session_id, players[session_id]['username'])

func add_player(session_id, username):
	if not $Panel/StatusContainer.has_node(str(session_id)):
		var status = PeerStatus.instance()
		status.initialize(username)
		status.name = str(session_id)
		$Panel/StatusContainer.add_child(status)

func set_status(session_id, status):
	var status_node = $Panel/StatusContainer.get_node(str(session_id))
	if status_node:
		status_node.set_status(status)

func set_ready_button_enabled(enabled : bool = true):
	$Panel/ReadyButton.disabled = !enabled

func _on_ReadyButton_pressed() -> void:
	emit_signal("ready_pressed")

func _on_MatchCopyButton_pressed() -> void:
	OS.clipboard = $Panel/MatchIDContainer/MatchID.text
