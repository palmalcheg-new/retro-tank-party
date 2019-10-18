extends Node2D

var Player1 = preload("res://tanks/Player1.tscn")
var Player2 = preload("res://tanks/Player2.tscn")
var Player3 = preload("res://tanks/Player3.tscn")
var Player4 = preload("res://tanks/Player4.tscn")
var TankScenes = {}

# Nakama variables:
var realtime_client
var matchmaker_ticket
var match_data

# WebRTC variables:
var webrtc_multiplayer : WebRTCMultiplayer = WebRTCMultiplayer.new()
var webrtc_peers = {}
var webrtc_session_to_peer_map = {}
var peers_ready = {}

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
	
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _on_TitleScreen_battle() -> void:
	$UILayer.show_screen("ConnectionScreen")

func _input(event):
	#if event.is_action_pressed("ui_cancel"):
	#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#if event.is_action_pressed("player_shoot"):
	#	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	pass

func _process(delta: float) -> void:
	if realtime_client:
		realtime_client.poll()
	if webrtc_peers:
		for p in webrtc_peers.values():
			p.poll()
	
	# Wait for all peers to be ready.
	if match_state == MatchState.CONNECTING:
		var all_connected = true
		
		# First, check that we have peers for every player we were matched with.
		for session_id in webrtc_session_to_peer_map.keys():
			if session_id == match_data['self']['session_id']:
				continue
			if not webrtc_peers.has(session_id):
				all_connected = false
			else:
				# Then, check if each existing peer is connected.
				var webrtc_peer = webrtc_peers[session_id]
				if webrtc_peer.get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED:
					var peer_id = webrtc_session_to_peer_map[session_id]
					$UILayer/ReadyScreen.set_status(peer_id, "Connected.")
				else:
					all_connected = false	
		
		if all_connected:
			# All our peers are good, so we can assume RPC will work now.
			match_state = MatchState.READY;
			
			# Wait for a moment.
			#yield(get_tree().create_timer(1), 'timeout')
			
			$UILayer/ReadyScreen.set_ready_button_enabled(true)

func _on_ReadyScreen_ready_pressed() -> void:
	rpc("peer_ready", get_tree().get_network_unique_id())

remotesync func peer_ready(peer_id):
	$UILayer/ReadyScreen.set_status(peer_id, "READY!")
	
	if get_tree().is_network_server():
		peers_ready[peer_id] = true
		if peers_ready.size() == players.size():
			start_new_game()

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
		print ($NakamaClient.last_response)
		$HUD.show_message("Account with username/password already exists!")
		$UILayer.show_screen("ConnectionScreen")
	else:
		$HUD.hide_all()
		$UILayer.show_screen("MatchScreen")

func _on_MatchScreen_find_match(min_players: int):
	$UILayer.hide_screen()
	$HUD.show_message("Looking for match...")
	
	if realtime_client == null:
		realtime_client = $NakamaClient.create_realtime_client(true)
		realtime_client.connect("match_data", self, "_on_nakama_match_data")
		realtime_client.connect("match_presence", self, "_on_nakama_match_presence")
		realtime_client.connect("matchmaker_matched", self, "_on_nakama_matchmaker_matched")
		yield(realtime_client, "connected")
	
	var result = realtime_client.send({
		matchmaker_add = {
			min_count = min_players,
			max_count = 4,
			# @todo We need to update query to be game specific! 
			# At some point, we'll have multiple games on the same Nakama server.
			query = '*',
		}
	}, self, "_on_nakama_match_add")

func _on_nakama_matchmak_add(data):
	if data.has('matchmaker_ticket'):
		matchmaker_ticket = data['matchmaker_ticket']['ticket']

func _on_nakama_matchmaker_matched(data):
	print ("Matchmaker matched:")
	print (data)
	
	if data.has('users') && data.has('token') && data.has('self'):
		# Use the list of users to assign peer ids.
		var session_ids = [];
		for u in data['users']:
			session_ids.append(u['presence']['session_id'])
		session_ids.sort()
		var peer_id = 1
		for s in session_ids:
			webrtc_session_to_peer_map[s] = peer_id
			peer_id += 1
		
		# Build the list of players.
		for u in data['users']:
			peer_id = webrtc_session_to_peer_map[u['presence']['session_id']]
			players[peer_id] = u['presence']['username']
		
		# Initialize multiplayer using our peer id
		webrtc_multiplayer.initialize(webrtc_session_to_peer_map[data['self']['presence']['session_id']])
		get_tree().set_network_peer(webrtc_multiplayer)
		
		# Join the match.
		realtime_client.send({
			match_join = {
				token = data['token'],
			}
		}, self, '_on_nakama_match_join');
	else:
		$HUD.show_message("Match maker error")
		$UILayer.show_screen("MatchScreen")

func _on_nakama_match_join(data):
	if data.has('match'):
		print ("Match join:")
		print (data['match'])
		
		$HUD.show_message("Connecting to peers...")
		$UILayer.show_screen("ReadyScreen", [players])
		$UILayer/ReadyScreen.set_status(get_tree().get_network_unique_id(), "Connected.")
		
		match_data = data['match']
		for u in match_data['presences']:
			if u['session_id'] == match_data['self']['session_id']:
					continue
			_webrtc_connect_peer(u)
		
		# Put in CONNECTING mode so we'll see the webrtc_multiplayer on the scene tree
		# once all the peers are ready.
		match_state = MatchState.CONNECTING
	else:
		$HUD.show_message("Unable to join match")

func _webrtc_connect_peer(u : Dictionary):
	print ("Connecting peer: " + u['session_id'])
	var webrtc_peer := WebRTCPeerConnection.new()
	webrtc_peer.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	webrtc_peer.connect("session_description_created", self, "_on_webrtc_peer_session_description_created", [u['session_id']])
	webrtc_peer.connect("ice_candidate_created", self, "_on_webrtc_peer_ice_candidate_created", [u['session_id']])
	
	webrtc_peers[u['session_id']] = webrtc_peer
	
	webrtc_multiplayer.add_peer(webrtc_peer, webrtc_session_to_peer_map[u['session_id']])
	
	if match_data['self']['session_id'].casecmp_to(u['session_id']) < 0:
		print ("Create offer")
		var result = webrtc_peer.create_offer()
		if result != OK:
			print ("Unable to create offer")

func _on_nakama_match_presence(data):
	print("match_presence:")
	print (data)
	
	if data.has('joins'):
		for u in data['joins']:
			if u['session_id'] == match_data['self']['session_id']:
				continue
			_webrtc_connect_peer(u)

func _on_webrtc_peer_session_description_created(type : String, sdp : String, session_id : String):
	print ("session_description_created:")
	print (type)
	print (sdp)
	
	var webrtc_peer = webrtc_peers[session_id]
	webrtc_peer.set_local_description(type, sdp)
	# @todo Send this data to peers to let them call .set_remote_description
	realtime_client.send({
		match_data_send = {
			match_id = match_data['match_id'],
			op_code = 1,
			data = JSON.print({
				method = "set_remote_description",
				target = session_id,
				type = type,
				sdp = sdp,
			}),
		},
	})

func _on_webrtc_peer_ice_candidate_created(media : String, index : int, name : String, session_id : String):
	print ("ice_candidate_created:")
	print (media)
	print (index)
	print (name)
	# @todo Send this data to peers to let them call .add_ice_candidate
	
	realtime_client.send({
		match_data_send = {
			match_id = match_data['match_id'],
			op_code = 1,
			data = JSON.print({
				method = "add_ice_candidate",
				target = session_id,
				media = media,
				index = index,
				name = name,
			}),
		},
	})

func _on_nakama_match_data(data):
	print("match_data:")
	print(data)
	
	if data['op_code'] == 1:
		var json_result = JSON.parse(data['data'])
		if json_result.error == OK:
			var content = json_result.result
			if content['target'] == match_data['self']['session_id']:
				var webrtc_peer = webrtc_peers[data['presence']['session_id']]
				match content['method']:
					'set_remote_description':
						webrtc_peer.set_remote_description(content['type'], content['sdp'])
					
					'add_ice_candidate':
						webrtc_peer.add_ice_candidate(content['media'], content['index'], content['name'])

func _on_player_connected(peer_id : int) -> void:
	# This signal is emitted even on clients when they connect,
	# with peer_id = 1 for the server.
	print ("_on_player_connected")
	
	#if not game_started:
	#	rpc_id(peer_id, "register_player", player_name)
	#else:
	#	$HUD.rpc_id(peer_id, "Game already in progress. Sorry!")

func _on_player_disconnected(peer_id : int) -> void:
	print ("_on_player_disconnected");
	
	if players.has(peer_id):
		players.erase(peer_id)
	if players_ready.has(peer_id):
		players_ready.erase(peer_id)
	
	#if get_tree().is_network_server() and not game_started:
	#	if players.size() == 0:
	#		$HUD.show_message("Waiting for players...")
	#		$HUD.hide_start_button()
	#	elif players.size() > 0:
	#		$HUD.show_message(str(players.size() + 1) + "/4 players connected")
	#		$HUD.show_start_button()

func _on_connected() -> void:
	$HUD.show_message("Waiting for game to start...")

func _on_connection_failed() -> void:
	$HUD.show_message("Failed to connect...")
	$UILayer.show_screen("ConnectionScreen")

func _on_server_disconnected() -> void:
	$HUD.show_message("Disconnected from server!")

#remote func register_player(_name) -> void:
#	var id = get_tree().get_rpc_sender_id()
#	players[id] = _name
#	
#	if get_tree().is_network_server():
#		if players.size() > 0:
#			$HUD.show_message(str(players.size() + 1) + "/4 players connected")
#			$HUD.show_start_button()

func _on_HUD_start() -> void:
	if game_started:
		restart_game()
	else:
		start_new_game()

func start_new_game() -> void:
	var player_info = {}
	
	var i = 1
	for peer_id in players.keys():
		player_info[peer_id] = {
			'tank': "Player" + str(i),
			'position': $Map/PlayerStartPositions.get_node("Player" + str(i)).global_position,
			'rotation': $Map/PlayerStartPositions.get_node("Player" + str(i)).global_rotation,
		}
		i += 1
		
	rpc("preconfigure_game", player_info)
	
	$Map/DropCrateSpawnArea1.start()
	$Map/DropCrateSpawnArea2.start()

func restart_game() -> void:
	my_player = null
	players_ready.clear()
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

remotesync func preconfigure_game(player_info : Dictionary) -> void:
	# This is to clean up from a previous game.
	if game_started:
		i_am_dead = false
		$WatchCamera.current = false
		for child in $Players.get_children():
			$Players.remove_child(child)
			child.queue_free()
		$Map/DropCrateSpawnArea1.clear()
		$Map/DropCrateSpawnArea2.clear()
	
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
	assert(not players_ready.has(peer_id))
	
	players_ready[peer_id] = players[peer_id]
	
	if players_ready.size() == players.size():
		rpc("post_configure_game")

remotesync func post_configure_game():
	game_started = true
	$HUD.hide_all()
	$UILayer.hide_screen()

func _on_player_dead(peer_id : int) -> void:
	var my_id = get_tree().get_network_unique_id()
	
	if peer_id == my_id:
		# Switch to "watch" mode
		$WatchCamera.current = true
		i_am_dead = true
		$HUD.show_message("You lose!")
	
	if get_tree().is_network_server():
		if players_ready.has(peer_id):
			players_ready.erase(peer_id)
		if players_ready.size() == 1:
			var remaining_players = players_ready.values()
			var winner = remaining_players[0]
			$HUD.rpc("show_message", winner + " is the winner!")
			$HUD.show_start_button("Play again")

