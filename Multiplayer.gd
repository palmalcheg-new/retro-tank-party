extends Node

export (int) var min_players = 2
export (int) var max_players = 4

# Nakama variables:
var realtime_client
var match_data : Dictionary = {}
var matchmaker_ticket : String = ''

# WebRTC variables:
var webrtc_multiplayer: WebRTCMultiplayer = WebRTCMultiplayer.new()
var webrtc_peers : Dictionary = {}

var players : Dictionary = {}
var next_peer_id : int = 1

enum MatchState {
	LOBBY = 0,
	MATCHING = 1,
	CONNECTING = 2,
	WAITING_FOR_ENOUGH_PLAYERS = 3,
	READY = 4,
	PLAYING = 5,
}
var match_state : int = MatchState.LOBBY

enum MatchMode {
	NONE = 0,
	CREATE = 1,
	JOIN = 2,
	MATCHMAKER = 3,
}
var match_mode : int = MatchMode.NONE

enum PlayerStatus {
	CONNECTING = 0,
	CONNECTED = 1,
}

signal error (message)

signal match_created (match_id)
signal match_joined (match_id)
signal matchmaker_matched (players)

signal player_joined (player)
signal player_left (player)
signal player_status_changed (player, status)

signal match_ready (players)
signal match_not_ready ()

func create_match(nakama_client):
	leave()
	match_mode = MatchMode.CREATE
	_create_realtime_client(nakama_client)
	yield(realtime_client, "connected")
	
	var result = realtime_client.send({ match_create = {} }, self, '_on_nakama_match_created')
	if result != OK:
		leave()
		emit_signal("error", "Unable to create match with code: " + str(result))

func join_match(nakama_client, match_id: String):
	leave()
	match_mode = MatchMode.JOIN
	_create_realtime_client(nakama_client)
	yield(realtime_client, "connected")
	
	var result = realtime_client.send({ match_join = { match_id = match_id }}, self, '_on_nakama_match_join')
	if result != OK:
		leave()
		emit_signal("error", "Unable to join match")

func start_matchmaking(nakama_client, min_players: int = 2):
	leave()
	match_mode = MatchMode.MATCHMAKER
	_create_realtime_client(nakama_client)
	yield(realtime_client, "connected")
	
	var result = realtime_client.send({
		matchmaker_add = {
			min_count = min_players,
			max_count = max_players,
			# @todo We need to update query to be game specific! 
			# At some point, we'll have multiple games on the same Nakama server.
			query = '*',
		}
	}, self, "_on_nakama_matchmaker_add")
	
	if result != OK:
		leave()
		emit_signal("error", "Unable to join match making pool")

func start_playing():
	assert(match_state == MatchState.READY)
	match_state = MatchState.PLAYING

func leave():
	# @todo clean up all old resources
	# @todo re-initialize everything to default value
	pass

func get_my_session_id():
	if match_data && match_data.has('self'):
		return match_data['self']['session_id']
	return null

func get_session(peer_id: int):
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			return session_id
	return null

func get_player_names_by_peer_id():
	var result = {}
	for session_id in players:
		result[players[session_id]['peer_id']] = players[session_id]['username']
	return result

func _create_realtime_client(nakama_client):
	realtime_client = nakama_client.create_realtime_client(true)
	realtime_client.connect("error", self, "_on_nakama_error")
	realtime_client.connect("disconnected", self, "_on_nakama_disconnected")
	realtime_client.connect("match_data", self, "_on_nakama_match_data")
	realtime_client.connect("match_presence", self, "_on_nakama_match_presence")
	realtime_client.connect("matchmaker_matched", self, "_on_nakama_matchmaker_matched")

func _on_nakama_error():
	leave()
	emit_signal("error", "Websocket connection error")

func _on_nakama_disconnected(data):
	leave()
	
	var msg = "Disconnected from server"
	if not data['was_clean_close']:
		msg += " uncleanly"
	if data['reason']:
		msg += " with reason: " + data['reason']
	if data['code']:
		msg += " (" + str(data['code']) + ")"
	
	emit_signal("error", msg)

func _on_nakama_match_created(data) -> void:
	print (data)
	if data.has('match'):
		match_data = data['match']
		match_data['self']['peer_id'] = 1
		var my_player = match_data['self']
		players[my_player['session_id']] = my_player
		next_peer_id += 1
		
		webrtc_multiplayer.initialize(1)
		get_tree().set_network_peer(webrtc_multiplayer)
		
		emit_signal("match_created", match_data['match_id'])
		emit_signal("player_joined", my_player)
		emit_signal("player_status_changed", my_player, PlayerStatus.CONNECTED)
	else:
		emit_signal("failed", "Failed to create match")

func _on_nakama_match_presence(data):
	print("match_presence:")
	print (data)
	
	if data.has('joins'):
		for u in data['joins']:
			if u['session_id'] == match_data['self']['session_id']:	
				continue
			
			if match_mode == MatchMode.CREATE:
				if match_state == MatchState.PLAYING:
					# Tell this player that we've already started
					realtime_client.send({
						match_data_send = {
							match_id = match_data['match_id'],
							op_code = 3,
							
							data = JSON.print({
								target = u['session_id'],
								reason = 'Sorry! The match has already begun.',
							}),
						},
					})
				
				if players.size() < max_players:
					u['peer_id'] = next_peer_id
					next_peer_id += 1
					players[u['session_id']] = u
					emit_signal("player_joined", u)
					
					_webrtc_connect_peer(u)
					
					# Tell this player (and the others) about all the players peer ids.
					realtime_client.send({
						match_data_send = {
							match_id = match_data['match_id'],
							op_code = 2,
							data = JSON.print({
								players = players,
							}),
						},
					})
				else:
					# Tell this player that we're full up!
					realtime_client.send({
						match_data_send = {
							match_id = match_data['match_id'],
							op_code = 3,
							
							data = JSON.print({
								target = u['session_id'],
								reason = 'Sorry! The match is full.,',
							}),
						},
					})
			elif match_mode == MatchMode.MATCHMAKER:
				emit_signal("player_joined", players[u['session_id']])
				_webrtc_connect_peer(players[u['session_id']])
	
	if data.has('leaves'):
		for u in data['leaves']:
			if u['session_id'] != match_data['self']['session_id']:
				_webrtc_disconnect_peer(u)
			
			if match_mode == MatchMode.JOIN:
				# @todo if the host disconnected then the match is over
				pass
			
			players.erase(u['session_id'])
			emit_signal("player_left", u)

func _on_nakama_match_join(data):
	if data.has('match'):
		match_data = data['match']
		
		if match_mode == MatchMode.JOIN:
			emit_signal("match_joined", match_data['match_id'])
		elif match_mode == MatchMode.MATCHMAKER:
			for u in match_data['presences']:
				if u['session_id'] == match_data['self']['session_id']:
						continue
				_webrtc_connect_peer(players[u['session_id']])
	else:
		leave()
		emit_signal("error", "Unable to join match")

func _on_nakama_matchmaker_add(data):
	if data.has('matchmaker_ticket'):
		matchmaker_ticket = data['matchmaker_ticket']['ticket']

func _on_nakama_matchmaker_matched(data):
	print ("Matchmaker matched:")
	print (data)
	
	if data.has('users') && data.has('token') && data.has('self'):
		# Use the list of users to assign peer ids.
		for u in data['users']:
			players[u['presence']['session_id']] = u['presence']
		var session_ids = players.keys();
		session_ids.sort()
		for session_id in session_ids:
			players[session_id]['peer_id'] = next_peer_id
			next_peer_id += 1
		
		# Initialize multiplayer using our peer id
		webrtc_multiplayer.initialize(players[data['self']['presence']['session_id']]['peer_id'])
		get_tree().set_network_peer(webrtc_multiplayer)
		
		emit_signal("matchmaker_matched", players)
		emit_signal("player_status_changed", players[data['self']['presence']['session_id']], PlayerStatus.CONNECTED)
		
		# Join the match.
		realtime_client.send({ match_join = {token = data['token']}}, self, '_on_nakama_match_join');
	else:
		leave()
		emit_signal("error", "Matchmaker error")

func _on_nakama_match_data(data):
	print("match_data:")
	print(data)
	
	var json_result = JSON.parse(data['data'])
	if json_result.error != OK:
		return
		
	var content = json_result.result
	if data['op_code'] == 1:
		if content['target'] == match_data['self']['session_id']:
			var webrtc_peer = webrtc_peers[data['presence']['session_id']]
			match content['method']:
				'set_remote_description':
					webrtc_peer.set_remote_description(content['type'], content['sdp'])
				
				'add_ice_candidate':
					webrtc_peer.add_ice_candidate(content['media'], content['index'], content['name'])
	if data['op_code'] == 2 && match_mode == MatchMode.JOIN:
		for session_id in content['players']:
			if not players.has(session_id):
				players[session_id] = content['players'][session_id]
				# Going back and forth over the wire, 'peer_id' turns into a string somehow.
				players[session_id]['peer_id'] = int(players[session_id]['peer_id'])
				_webrtc_connect_peer(players[session_id])
				emit_signal("player_joined", players[session_id])
				if session_id == match_data['self']['session_id']:
					webrtc_multiplayer.initialize(players[session_id]['peer_id'])
					get_tree().set_network_peer(webrtc_multiplayer)
					
					emit_signal("player_status_changed", players[session_id], PlayerStatus.CONNECTED)
	if data['op_code'] == 3:
		if content['target'] == match_data['self']['session_id']:
			leave()
			emit_signal("error", content['reason'])

func _webrtc_connect_peer(u: Dictionary):
	# Don't add the same peer twice!
	if webrtc_peers.has(u['session_id']):
		return
	
	# If the match was previously ready, then we need to switch back to not ready.
	if match_state == MatchState.READY:
		emit_signal("match_not_ready")
	
	# Put in CONNECTING mode so we'll check if all the WebRTC peers are ready.
	match_state = MatchState.CONNECTING
	
	print ("Connecting peer: " + u['session_id'])
	var webrtc_peer := WebRTCPeerConnection.new()
	webrtc_peer.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	webrtc_peer.connect("session_description_created", self, "_on_webrtc_peer_session_description_created", [u['session_id']])
	webrtc_peer.connect("ice_candidate_created", self, "_on_webrtc_peer_ice_candidate_created", [u['session_id']])
	
	webrtc_peers[u['session_id']] = webrtc_peer
	
	webrtc_multiplayer.add_peer(webrtc_peer, u['peer_id'])
	
	if match_data['self']['session_id'].casecmp_to(u['session_id']) < 0:
		print ("Create offer")
		var result = webrtc_peer.create_offer()
		if result != OK:
			print ("Unable to create offer")

func _webrtc_disconnect_peer(u: Dictionary):
	pass

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

func _process(delta: float) -> void:
	if realtime_client:
		realtime_client.poll()
	
	# Wait for all peers to be ready.
	if match_state == MatchState.CONNECTING:
		var all_connected = true
		
		# First, check that we have peers for every player we were matched with.
		for session_id in players:
			if session_id == match_data['self']['session_id']:
				continue
			if not webrtc_peers.has(session_id):
				all_connected = false
			else:
				# Then, check if each existing peer is connected.
				var webrtc_peer = webrtc_peers[session_id]
				if webrtc_peer.get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED:
					emit_signal("player_status_changed", players[session_id], PlayerStatus.CONNECTED)
				else:
					all_connected = false	
		
		if all_connected:
			if players.size() >= min_players:
				# All our peers are good, so we can assume RPC will work now.
				match_state = MatchState.READY;
				
				# Wait for a moment.
				#yield(get_tree().create_timer(1), 'timeout')
				
				emit_signal("match_ready", players)
			else:
				match_state = MatchState.WAITING_FOR_ENOUGH_PLAYERS
