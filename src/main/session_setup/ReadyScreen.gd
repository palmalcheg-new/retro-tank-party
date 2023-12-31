extends "res://src/ui/Screen.gd"

var PlayerStatus = preload("res://src/ui/PlayerStatus.tscn")

onready var ready_button := $Panel/ReadyButton
onready var match_id_container := $Panel/MatchIDContainer
onready var match_id_label := $Panel/MatchIDContainer/MatchID
onready var status_container := $Panel/StatusContainer

signal ready_pressed ()

func _ready() -> void:
	clear_players()

	OnlineMatch.connect("player_joined", self, "_on_OnlineMatch_player_joined")
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	OnlineMatch.connect("player_status_changed", self, "_on_OnlineMatch_player_status_changed")
	OnlineMatch.connect("match_ready", self, "_on_OnlineMatch_match_ready")
	OnlineMatch.connect("match_not_ready", self, "_on_OnlineMatch_match_not_ready")
	SyncManager.connect("peer_pinged_back", self, "_on_SyncManager_peer_pinged_back")

func _show_screen(info: Dictionary = {}) -> void:
	var players: Dictionary = info.get("players", {})
	var match_id: String = info.get("match_id", '')
	var clear: bool = info.get("clear", false)

	if players.size() > 0 or clear:
		clear_players()

	for session_id in players:
		var player = players[session_id]
		add_player(session_id, player.username, player.peer_id == 1, player.spectator)

	if match_id:
		match_id_container.visible = true
		match_id_label.text = match_id
	else:
		match_id_container.visible = false

	# If we reach the ready screen, we are connected via OnlineMatch, and
	# we can check if we're spectating.
	SyncManager.spectating = OnlineMatch.spectating

	ready_button.focus.grab_without_sound()

func clear_players() -> void:
	for child in status_container.get_children():
		status_container.remove_child(child)
		child.queue_free()
	ready_button.disabled = true

func hide_match_id() -> void:
	match_id_container.visible = false

func add_player(session_id: String, username: String, is_host: bool = false, is_spectator: bool = false) -> void:
	if not status_container.has_node(session_id):
		var status = PlayerStatus.instance()
		status_container.add_child(status)
		status.initialize(username, "Connecting...")
		status.name = session_id
		status.host = is_host
		status.spectator = is_spectator

func remove_player(session_id: String) -> void:
	var status = status_container.get_node(session_id)
	if status:
		status.queue_free()

func set_status(session_id: String, status: String) -> void:
	var status_node = status_container.get_node(session_id)
	if status_node:
		status_node.set_status(status)

func get_status(session_id: String) -> String:
	var status_node = status_container.get_node(session_id)
	if status_node:
		return status_node.status
	return ''

func reset_status(status: String) -> void:
	for child in status_container.get_children():
		child.set_status(status)

func set_spectator(session_id: String, is_spectator: bool) -> void:
	var status_node = status_container.get_node(session_id)
	if status_node:
		status_node.set_spectator(is_spectator)

func set_ready_button_enabled(enabled: bool = true) -> void:
	ready_button.disabled = !enabled
	if enabled:
		ready_button.focus.grab_without_sound()

func _on_ReadyButton_pressed() -> void:
	emit_signal("ready_pressed")

func _on_MatchCopyButton_pressed() -> void:
	OS.clipboard = match_id_label.text

#####
# OnlineMatch callbacks:
#####

func _on_OnlineMatch_player_joined(player) -> void:
	add_player(player.session_id, player.username, player.peer_id == 1, player.spectator)

func _on_OnlineMatch_player_left(player) -> void:
	remove_player(player.session_id)

func _on_OnlineMatch_player_status_changed(player, status) -> void:
	if status == OnlineMatch.PlayerStatus.CONNECTED:
		# Don't go backwards from 'READY!'
		if get_status(player.session_id) != 'READY!':
			set_status(player.session_id, 'PLAYER_STATUS_CONNECTED')
		if player.peer_id != SyncManager.network_adaptor.get_network_unique_id():
			SyncManager.add_peer(player.peer_id, {spectator = player.spectator})
	elif status == OnlineMatch.PlayerStatus.CONNECTING:
		set_status(player.session_id, 'PLAYER_STATUS_CONNECTING')

func _on_OnlineMatch_match_ready(_players: Dictionary) -> void:
	set_ready_button_enabled(true)

	# Automatically click ready button during debugging.
	if Globals.arguments.has('join'):
		yield(get_tree().create_timer(0.5), 'timeout')
		_on_ReadyButton_pressed()

func _on_OnlineMatch_match_not_ready() -> void:
	set_ready_button_enabled(false)

#####
# SyncManager callbacks
#####

func _on_SyncManager_peer_pinged_back(peer: SyncManager.Peer) -> void:
	var player := OnlineMatch.get_player_by_peer_id(peer.peer_id)
	if not player:
		return

	var status_node = status_container.get_node(player.session_id)
	if status_node:
		status_node.set_ping_time(peer.rtt)
