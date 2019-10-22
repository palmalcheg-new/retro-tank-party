extends Control

var PeerStatus = preload("res://ui/PeerStatus.tscn");

signal ready_pressed ()

func initialize(players, match_id = ''):
	for child in $Panel/StatusContainer.get_children():
		child.queue_free()
	$Panel/ReadyButton.disabled = true
	
	if match_id:
		$Panel/MatchIDContainer.visible = true
		$Panel/MatchIDContainer/MatchID.text = match_id
	else:
		$Panel/MatchIDContainer.visible = false
	
	for session_id in players:
		add_player(session_id, players[session_id]['username'])

func hide_match_id() -> void:
	$Panel/MatchIDContainer.visible = false

func add_player(session_id, username):
	if not $Panel/StatusContainer.has_node(session_id):
		var status = PeerStatus.instance()
		status.initialize(username)
		status.name = session_id
		$Panel/StatusContainer.add_child(status)

func remove_player(session_id):
	var status = $Panel/StatusContainer.get_node(session_id)
	if status:
		status.queue_free()

func set_status(session_id, status):
	var status_node = $Panel/StatusContainer.get_node(session_id)
	if status_node:
		status_node.set_status(status)

func get_status(session_id) -> String:
	var status_node = $Panel/StatusContainer.get_node(session_id)
	if status_node:
		return status_node.get_status()
	return ''

func reset_status(status):
	for child in $Panel/StatusContainer.get_children():
		child.set_status(status)

func set_ready_button_enabled(enabled : bool = true):
	$Panel/ReadyButton.disabled = !enabled

func _on_ReadyButton_pressed() -> void:
	emit_signal("ready_pressed")

func _on_MatchCopyButton_pressed() -> void:
	OS.clipboard = $Panel/MatchIDContainer/MatchID.text
