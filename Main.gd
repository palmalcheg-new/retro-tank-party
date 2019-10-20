extends Node2D

var Player1 = preload("res://tanks/Player1.tscn")
var Player2 = preload("res://tanks/Player2.tscn")
var Player3 = preload("res://tanks/Player3.tscn")
var Player4 = preload("res://tanks/Player4.tscn")
var TankScenes = {}

enum MatchState {
	LOBBY = 0,
	MATCHING = 1,
	CONNECTING = 2,
	READY = 4,
}
var match_state : int = MatchState.LOBBY

var player_name : String
var players = {}
var players_ready = {}
var players_loaded = {}

var my_player

var game_started = false
var i_am_dead = false

var test_mode = false

func _ready():
	TankScenes['Player1'] = Player1
	TankScenes['Player2'] = Player2
	TankScenes['Player3'] = Player3
	TankScenes['Player4'] = Player4
	
	var use_production_nakama = false
	if use_production_nakama:
		$NakamaClient.host = 'NAKAMA_HOST'
		$NakamaClient.port = 'NAKAMA_PORT'
		$NakamaClient.server_key = 'NAKAMA_SERVER_KEY'
		$NakamaClient.use_ssl = true
		$NakamaClient.ssl_validate = true
	
	#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	#if "--test-mode" in OS.get_cmdline_args():
	#	test_mode = true
	#	_on_ConnectionScreen_serve('Tester', 12233)
	#	$HUD.hide_all()
	#	start_new_game()
	#	return
	
	$Multiplayer.connect("error", self, "_on_match_error")
	$Multiplayer.connect("disconnected", self, "_on_match_disconnected")
	$Multiplayer.connect("match_created", self, "_on_match_created")
	$Multiplayer.connect("match_joined", self, "_on_match_joined")
	$Multiplayer.connect("matchmaker_matched", self, "_on_matchmaker_matched")
	$Multiplayer.connect("player_joined", self, "_on_player_joined")
	$Multiplayer.connect("player_left", self, "_on_player_left")
	$Multiplayer.connect("player_status_changed", self, "_on_player_status_changed")
	$Multiplayer.connect("match_ready", self, "_on_match_ready")
	$Multiplayer.connect("match_not_ready", self, "_on_match_not_ready")

func _on_TitleScreen_battle() -> void:
	$UILayer.show_screen("ConnectionScreen")

func _input(event):
	#if event.is_action_pressed("ui_cancel"):
	#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#if event.is_action_pressed("player_shoot"):
	#	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	pass

func _on_ConnectionScreen_login(email, password) -> void:
	$NakamaClient.authenticate_email(email, password)
	$UILayer.hide_screen()
	$HUD.show_message("Logging in...")
	
	yield($NakamaClient, "authenticate_email_completed")
	
	if $NakamaClient.last_response['http_code'] != 200:
		$HUD.show_message("Login failed!")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$HUD.hide_all()
		$UILayer.show_screen("MatchScreen")

func _on_ConnectionScreen_create_account(username, email, password) -> void:
	$NakamaClient.authenticate_email(email, password, true, username)
	
	$UILayer.hide_screen()
	$HUD.show_message("Creating account...")
	
	yield($NakamaClient, "authenticate_email_completed")
	
	if $NakamaClient.last_response['http_code'] != 200:
		var msg: String
		if $NakamaClient.last_response['data'].has('error'):
			msg = $NakamaClient.last_response['data']['error']
			# Nakama treats registration as logging in, so this is what we get if the
			# the email is already is use but the password is wrong.
			if msg == 'Invalid credentials.':
				msg = 'E-mail already in use.'
		else:
			msg = "Unable to create account"
		$HUD.show_message(msg)
		$UILayer.show_screen("ConnectionScreen")
	else:
		$HUD.hide_all()
		$UILayer.show_screen("MatchScreen")

func _on_MatchScreen_create_match() -> void:
	if $NakamaClient.is_session_expired():
		$HUD.show_message("Login session has expired")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$Multiplayer.create_match($NakamaClient)
		$HUD.hide_message()

func _on_MatchScreen_join_match(match_id) -> void:
	if not match_id:
		$HUD.show_message("Need to paste Match ID to join")
		return
	
	if $NakamaClient.is_session_expired():
		$HUD.show_message("Login session has expired")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$Multiplayer.join_match($NakamaClient, match_id)
		$HUD.hide_message()

func _on_MatchScreen_find_match(min_players: int):
	if $NakamaClient.is_session_expired():
		$HUD.show_message("Login session has expired")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$UILayer.hide_screen()
		$HUD.show_message("Looking for match...")
		$HUD.show_exit_button()
		$Multiplayer.start_matchmaking($NakamaClient, min_players)

func _on_match_error(message):
	$UILayer.show_screen("MatchScreen")
	$HUD.show_message(message)
	$HUD.hide_exit_button()

func _on_match_disconnected(data):
	if not data['was_clean_close']:
		var msg = "Disconnected from server"
		if data['reason']:
			msg += " with reason: " + data['reason']
		if data['code']:
			msg += " (" + str(data['code']) + ")"
		
		_on_match_error(msg)

func _on_match_created(match_id):
	$UILayer.show_screen("ReadyScreen", [{}, match_id])
	$HUD.show_exit_button()

func _on_match_joined(match_id):
	$UILayer.show_screen("ReadyScreen", [{}, match_id])
	$HUD.show_exit_button()

func _on_matchmaker_matched(players):
	$HUD.hide_all()
	$UILayer.show_screen("ReadyScreen", [players])
	$HUD.show_exit_button()

func _on_player_joined(player):
	$UILayer/ReadyScreen.add_player(player['session_id'], player['username'])

func _on_player_left(player):
	$HUD.show_message(player['username'] + " has left")
	
	$UILayer/ReadyScreen.remove_player(player['session_id'])
	
	if game_started:
		var tank = $Players.get_node(str(player['peer_id']))
		if tank:
			tank.die()
		else:
			# This will be called by tank.die() if the tank still exists. But if not,
			# as a fallback, we just call the event handler directly.
			_on_player_dead(player['peer_id'])

func _on_player_status_changed(player, status):
	$UILayer/ReadyScreen.set_status(player['session_id'], 'Connected.')

func _on_match_ready(players):
	$UILayer/ReadyScreen.set_ready_button_enabled(true)

func _on_match_not_ready():
	$UILayer/ReadyScreen.set_ready_button_enabled(false)

func _on_ReadyScreen_ready_pressed() -> void:
	rpc("player_ready", $Multiplayer.get_my_session_id())

remotesync func player_ready(session_id):
	$UILayer/ReadyScreen.set_status(session_id, "READY!")
	
	if get_tree().is_network_server():
		players_ready[session_id] = true
		if players_ready.size() == $Multiplayer.players.size():
			if $Multiplayer.match_state != $Multiplayer.MatchState.PLAYING:
				$Multiplayer.start_playing()
			start_new_game()

func _on_HUD_start() -> void:
	if game_started:
		restart_game()
	else:
		start_new_game()

func _on_HUD_exit() -> void:
	stop_game()
	$HUD.hide_all()
	$UILayer.show_screen("MatchScreen")

func start_new_game() -> void:
	players = $Multiplayer.get_player_names_by_peer_id()
	
	var player_info = {}
	
	var i = 1
	for peer_id in players:
		player_info[peer_id] = {
			'tank': "Player" + str(i),
			'position': $Map/PlayerStartPositions.get_node("Player" + str(i)).global_position,
			'rotation': $Map/PlayerStartPositions.get_node("Player" + str(i)).global_rotation,
		}
		i += 1
		
	rpc("preconfigure_game", player_info)
	
	$Map/DropCrateSpawnArea1.start()
	$Map/DropCrateSpawnArea2.start()

func stop_game() -> void:
	$Multiplayer.leave()
	clear_game_state()
	players_loaded.clear()

func restart_game() -> void:
	stop_game()
	start_new_game()

func _create_camera() -> Camera2D:	
	var camera = Camera2D.new()
	camera.current = true
	
	camera.limit_top = 0
	camera.limit_left = 0
	
	var tilemap_rect = $Map/TileMap.get_used_rect()
	camera.limit_right = tilemap_rect.size.x * $Map/TileMap.cell_size.x
	camera.limit_bottom = tilemap_rect.size.y * $Map/TileMap.cell_size.y
	
	return camera

func clear_game_state() -> void:
	game_started = false
	i_am_dead = false
	my_player = null
	$WatchCamera.current = false
	for child in $Players.get_children():
		$Players.remove_child(child)
		child.queue_free()
	$Map/DropCrateSpawnArea1.clear()
	$Map/DropCrateSpawnArea2.clear()

remotesync func preconfigure_game(player_info : Dictionary) -> void:
	if game_started:
		clear_game_state()
	
	var players = $Multiplayer.get_player_names_by_peer_id()
	var my_id = get_tree().get_network_unique_id()
	
	for peer_id in players:
		var other_player = TankScenes[player_info[peer_id]['tank']].instance()
		other_player.set_name(str(peer_id))
		other_player.set_network_master(peer_id)
		other_player.set_player_name(players[peer_id])
		other_player.position = player_info[peer_id]['position']
		other_player.rotation = player_info[peer_id]['rotation']
		other_player.connect("dead", self, "_on_player_dead")
		$Players.add_child(other_player)
	
	my_player = $Players.get_node(str(my_id))
	my_player.player_controlled = true
	my_player.add_child(_create_camera())
	
	rpc_id(1, "done_preconfigure_game", my_id)

remotesync func done_preconfigure_game(peer_id) -> void:
	assert(get_tree().is_network_server())
	assert(peer_id in players)
	assert(not players_loaded.has(peer_id))
	
	players_loaded[peer_id] = players[peer_id]
	
	if players_loaded.size() == players.size():
		rpc("post_configure_game")

remotesync func post_configure_game():
	game_started = true
	$UILayer.hide_screen()
	$HUD.hide_all()
	$HUD.show_exit_button()

func _on_player_dead(peer_id : int) -> void:
	var my_id = get_tree().get_network_unique_id()
	
	if peer_id == my_id:
		# Switch to "watch" mode
		$WatchCamera.current = true
		i_am_dead = true
		$HUD.show_message("You lose!")
	
	if get_tree().is_network_server():
		if players_loaded.has(peer_id):
			players_loaded.erase(peer_id)
		if players_loaded.size() == 1:
			# Show the winner name.
			var remaining_players = players_loaded.values()
			var winner = remaining_players[0]
			rpc("show_winner", winner)
			
			# Reset the ready/loaded checks
			players_ready.clear()
			players_loaded.clear()

remotesync func show_winner(name):
	$HUD.show_message(name + " is the winner!")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	$UILayer/ReadyScreen.hide_match_id()
	$UILayer/ReadyScreen.reset_status("Waiting...")
	$UILayer.show_screen("ReadyScreen")
