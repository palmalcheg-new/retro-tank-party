extends Node2D

var Player1 = preload("res://tanks/Player1.tscn")
var Player2 = preload("res://tanks/Player2.tscn")
var Player3 = preload("res://tanks/Player3.tscn")
var Player4 = preload("res://tanks/Player4.tscn")
var TankScenes = {}

var nakama_client: NakamaClient
var nakama_session: NakamaSession

var players = {}
var players_ready = {}
var players_loaded = {}

var game_started = false
var i_am_dead = false

var practice_mode = false

func _ready():
	TankScenes['Player1'] = Player1
	TankScenes['Player2'] = Player2
	TankScenes['Player3'] = Player3
	TankScenes['Player4'] = Player4
	
	nakama_client = Nakama.create_client(
		Build.NAKAMA_SERVER_KEY,
		Build.NAKAMA_HOST,
		Build.NAKAMA_PORT,
		'https' if Build.NAKAMA_USE_SSL else 'http')
	
	#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
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

func _input(event):
	#if event.is_action_pressed("ui_cancel"):
	#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#if event.is_action_pressed("player_shoot"):
	#	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	pass

func _unhandled_input(event: InputEvent) -> void:
	# Trigger debugging action!
	#if event.is_action_pressed("player_debug"):
	#	# Close all our peers to force a reconnect (to make sure it works).
	#	for session_id in $Multiplayer.webrtc_peers:
	#		var webrtc_peer = $Multiplayer.webrtc_peers[session_id]
	#		webrtc_peer.close()
	pass

func _on_UILayer_change_screen(name, screen) -> void:
	if name == 'MatchScreen':
		if not nakama_session or nakama_session.is_expired():
			# If we were previously connected, then show a message.
			if nakama_session:
				$HUD.show_message("Login session has expired")
			$UILayer.show_screen("ConnectionScreen")
	
	if name == 'TitleScreen':
		$HUD.hide_exit_button()
	else:
		$HUD.show_exit_button()

func _on_TitleScreen_battle() -> void:
	$UILayer.show_screen("MatchScreen")

func _on_TitleScreen_practice() -> void:
	practice_mode = true
	$UILayer.hide_screen()
	
	# We just need a dummy multiplayer.
	var webrtc_multiplayer = WebRTCMultiplayer.new()
	webrtc_multiplayer.initialize(1)
	get_tree().set_network_peer(webrtc_multiplayer)
	
	start_new_game()

func _on_ConnectionScreen_login(email, password) -> void:
	$UILayer.hide_screen()
	$HUD.show_message("Logging in...")
	
	nakama_session = yield(nakama_client.authenticate_email_async(email, password), "completed")
	
	if nakama_session.is_exception():
		$HUD.show_message("Login failed!")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$HUD.hide_all()
		$UILayer.show_screen("MatchScreen")

func _on_ConnectionScreen_create_account(username, email, password) -> void:
	$UILayer.hide_screen()
	$HUD.show_message("Creating account...")

	nakama_session = yield(nakama_client.authenticate_email_async(email, password, username, true), "completed")
	
	if nakama_session.is_exception():
		var msg = nakama_session.get_exception().message
		# Nakama treats registration as logging in, so this is what we get if the
		# the email is already is use but the password is wrong.
		if msg == 'Invalid credentials.':
			msg = 'E-mail already in use.'
		elif msg == '':
			msg = "Unable to create account"
		$HUD.show_message(msg)
		$UILayer.show_screen("ConnectionScreen")
	else:
		$HUD.hide_all()
		$UILayer.show_screen("MatchScreen")

func _on_MatchScreen_create_match() -> void:
	if nakama_session.is_expired():
		$HUD.show_message("Login session has expired")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$Multiplayer.create_match(nakama_client, nakama_session)
		$HUD.hide_message()

func _on_MatchScreen_join_match(match_id) -> void:
	if not match_id:
		$HUD.show_message("Need to paste Match ID to join")
		return
	
	if nakama_session.is_expired():
		$HUD.show_message("Login session has expired")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$Multiplayer.join_match(nakama_client, nakama_session, match_id)
		$HUD.hide_message()

func _on_MatchScreen_find_match(min_players: int):
	if nakama_session.is_expired():
		$HUD.show_message("Login session has expired")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$UILayer.hide_screen()
		$HUD.show_message("Looking for match...")
		$HUD.show_exit_button()
		
		var data = {
			min_count = min_players,
			string_properties = {
				game = "retro_tank_party",
			},
			query = "+properties.game:retro_tank_party",
		}
		$Multiplayer.start_matchmaking(nakama_client, nakama_session, data)

func _on_match_error(message):
	$UILayer.show_screen("MatchScreen")
	$HUD.show_message(message)

func _on_match_disconnected():
	_on_match_error("Disconnected from server")

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
	$UILayer/ReadyScreen.add_player(player.session_id, player.username)

func _on_player_left(player):
	$HUD.show_message(player.username + " has left")
	
	$UILayer/ReadyScreen.remove_player(player.session_id)
	
	if game_started:
		var tank = $Players.get_node(str(player.peer_id))
		if tank:
			tank.die()
		else:
			# This will be called by tank.die() if the tank still exists. But if not,
			# as a fallback, we just call the event handler directly.
			_on_player_dead(player.peer_id)

func _on_player_status_changed(player, status):
	if status == $Multiplayer.PlayerStatus.CONNECTED:
		# Don't go backwards from 'READY!'
		if $UILayer/ReadyScreen.get_status(player.session_id) != 'READY!':
			$UILayer/ReadyScreen.set_status(player.session_id, 'Connected.')
		
		if get_tree().is_network_server():
			# Tell this new player about all the other players that are already ready.
			for session_id in players_ready:
				rpc_id(player.peer_id, "player_ready", session_id)
	elif status == $Multiplayer.PlayerStatus.CONNECTING:
		$UILayer/ReadyScreen.set_status(player.session_id, 'Connecting...')

func _on_match_ready(players):
	$UILayer/ReadyScreen.set_ready_button_enabled(true)

func _on_match_not_ready():
	$UILayer/ReadyScreen.set_ready_button_enabled(false)

func _on_ReadyScreen_ready_pressed() -> void:
	rpc("player_ready", $Multiplayer.get_my_session_id())

remotesync func player_ready(session_id):
	$UILayer/ReadyScreen.set_status(session_id, "READY!")
	
	if get_tree().is_network_server() and not players_ready.has(session_id):
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
	
	if $UILayer.current_screen_name == 'ConnectionScreen' or $UILayer.current_screen_name == 'MatchScreen':
		$UILayer.show_screen("TitleScreen")
	elif practice_mode:
		practice_mode = false
		$UILayer.show_screen("TitleScreen")
	else:
		$UILayer.show_screen("MatchScreen")

func start_new_game() -> void:
	if practice_mode:
		players = { 1: "Practice" }
	else:
		players = $Multiplayer.get_player_names_by_peer_id()
	
	var player_info = {}
	
	var i = 1
	for peer_id in players:
		player_info[peer_id] = {
			'tank': "Player" + str(i),
			'username': players[peer_id],
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
	$WatchCamera.current = false
	for child in $Players.get_children():
		$Players.remove_child(child)
		child.queue_free()
	$Map/DropCrateSpawnArea1.clear()
	$Map/DropCrateSpawnArea2.clear()

remotesync func preconfigure_game(player_info : Dictionary) -> void:
	if game_started:
		clear_game_state()
	
	var my_id = get_tree().get_network_unique_id()
	
	for peer_id in player_info:
		var other_player = TankScenes[player_info[peer_id]['tank']].instance()
		other_player.set_name(str(peer_id))
		other_player.set_network_master(peer_id)
		other_player.set_player_name(player_info[peer_id]['username'])
		other_player.position = player_info[peer_id]['position']
		other_player.rotation = player_info[peer_id]['rotation']
		other_player.connect("dead", self, "_on_player_dead")
		$Players.add_child(other_player)
	
	var my_player = $Players.get_node(str(my_id))
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
	
	clear_game_state()
