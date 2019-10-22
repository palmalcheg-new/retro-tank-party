extends Node

export (int) var min_players = 2
export (int) var max_players = 4

# Nakama variables:
var realtime_client
var my_session_id : String
var match_data : Dictionary
var matchmaker_ticket : String

# WebRTC variables:
var webrtc_multiplayer: WebRTCMultiplayer
var webrtc_peers : Dictionary
var webrtc_peers_connected : Dictionary

var players : Dictionary
var next_peer_id : int

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
signal disconnected (data)

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

func start_matchmaking(nakama_client, data: Dictionary = {}):
	leave()
	match_mode = MatchMode.MATCHMAKER
	_create_realtime_client(nakama_client)
	yield(realtime_client, "connected")
	
	if data.has('min_count'):
		data['min_count'] = max(min_players, data['min_count'])
	else:
		data['min_count'] = min_players
	
	if data.has('max_count'):
		data['max_count'] = min(max_players, data['max_count'])
	else:
		data['max_count'] = max_players
	
	if not data.has('query'):
		data['query'] = '*'
	
	var result = realtime_client.send({ matchmaker_add = data }, self, "_on_nakama_matchmaker_add")
	if result != OK:
		leave()
		emit_signal("error", "Unable to join match making pool")
	else:
		match_state = MatchState.MATCHING

func start_playing():
	assert(match_state == MatchState.READY)
	match_state = MatchState.PLAYING

func leave():
	# WebRTC disconnect.
	if webrtc_multiplayer:
		webrtc_multiplayer.close()
		get_tree().set_network_peer(null)
	
	# Nakama disconnect.
	if realtime_client:
		if match_data:
			realtime_client.send({ match_leave = { match_id = match_data['match_id'] }})
		elif matchmaker_ticket:
			realtime_client.send({ matchmaker_remove = { ticket = matchmaker_ticket }})
		realtime_client.disconnect_from_host()
	
	# Initialize all the variables to their default state.
	my_session_id = ''
	match_data = {}
	matchmaker_ticket = ''
	webrtc_multiplayer = WebRTCMultiplayer.new()
	webrtc_multiplayer.connect("peer_connected", self, "_on_webrtc_peer_connected")
	webrtc_multiplayer.connect("peer_disconnected", self, "_on_webrtc_peer_disconnected")
	webrtc_peers = {}
	webrtc_peers_connected = {}
	players = {}
	next_peer_id = 1
	match_state = MatchState.LOBBY
	match_mode = MatchMode.NONE

func get_my_session_id():
	if my_session_id:
		return my_session_id
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

func _on_nakama_error(data):
	print ("ERROR:")
	print(data)
	leave()
	emit_signal("error", "Websocket connection error")

func _on_nakama_disconnected(data):
	leave()
	emit_signal("disconnected", data)

func _on_nakama_match_created(data) -> void:
	if data.has('match'):
		match_data = data['match']
		match_data['self']['peer_id'] = 1
		var my_player = match_data['self']
		my_session_id = my_player['session_id']
		players[my_session_id] = my_player
		next_peer_id += 1
		
		webrtc_multiplayer.initialize(1)
		get_tree().set_network_peer(webrtc_multiplayer)
		
		emit_signal("match_created", match_data['match_id'])
		emit_signal("player_joined", my_player)
		emit_signal("player_status_changed", my_player, PlayerStatus.CONNECTED)
	else:
		emit_signal("failed", "Failed to create match")

func _on_nakama_match_presence(data):
	if data.has('joins'):
		for u in data['joins']:
			if u['session_id'] == my_session_id:
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
			if u['session_id'] == my_session_id:
				continue
			
			_webrtc_disconnect_peer(u)
			var player = players[u['session_id']]
			
			# If the host disconnects, this is the end!
			if player['peer_id'] == 1:
				leave()
				emit_signal("error", "Host has disconnected")
			else:
				players.erase(u['session_id'])
				emit_signal("player_left", player)
				
				if players.size() < min_players:
					# If state was previously ready, but this brings us below the minimum players,
					# then we aren't ready anymore.
					if match_state == MatchState.READY || match_state == MatchState.PLAYING:
						emit_signal("match_not_ready")

func _on_nakama_match_join(data):
	if data.has('match'):
		match_data = data['match']
		my_session_id = match_data['self']['session_id']
		
		if match_mode == MatchMode.JOIN:
			emit_signal("match_joined", match_data['match_id'])
		elif match_mode == MatchMode.MATCHMAKER:
			for u in match_data['presences']:
				if u['session_id'] == my_session_id:
						continue
				_webrtc_connect_peer(players[u['session_id']])
	else:
		leave()
		emit_signal("error", "Unable to join match")

func _on_nakama_matchmaker_add(data):
	if data.has('matchmaker_ticket'):
		matchmaker_ticket = data['matchmaker_ticket']['ticket']

func _on_nakama_matchmaker_matched(data):
	if data.has('users') && data.has('token') && data.has('self'):
		my_session_id = data['self']['presence']['session_id']
		
		# Use the list of users to assign peer ids.
		for u in data['users']:
			players[u['presence']['session_id']] = u['presence']
		var session_ids = players.keys();
		session_ids.sort()
		for session_id in session_ids:
			players[session_id]['peer_id'] = next_peer_id
			next_peer_id += 1
		
		# Initialize multiplayer using our peer id
		webrtc_multiplayer.initialize(players[my_session_id]['peer_id'])
		get_tree().set_network_peer(webrtc_multiplayer)
		
		emit_signal("matchmaker_matched", players)
		emit_signal("player_status_changed", players[data['self']['presence']['session_id']], PlayerStatus.CONNECTED)
		
		# Join the match.
		realtime_client.send({ match_join = {token = data['token']}}, self, '_on_nakama_match_join');
	else:
		leave()
		emit_signal("error", "Matchmaker error")

func _on_nakama_match_data(data):
	var json_result = JSON.parse(data['data'])
	if json_result.error != OK:
		return
		
	var content = json_result.result
	if data['op_code'] == 1:
		if content['target'] == my_session_id:
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
				if session_id == my_session_id:
					webrtc_multiplayer.initialize(players[session_id]['peer_id'])
					get_tree().set_network_peer(webrtc_multiplayer)
					
					emit_signal("player_status_changed", players[session_id], PlayerStatus.CONNECTED)
	if data['op_code'] == 3:
		if content['target'] == my_session_id:
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
	
	var webrtc_peer := WebRTCPeerConnection.new()
	webrtc_peer.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	webrtc_peer.connect("session_description_created", self, "_on_webrtc_peer_session_description_created", [u['session_id']])
	webrtc_peer.connect("ice_candidate_created", self, "_on_webrtc_peer_ice_candidate_created", [u['session_id']])
	
	webrtc_peers[u['session_id']] = webrtc_peer
	
	webrtc_multiplayer.add_peer(webrtc_peer, u['peer_id'])
	
	if my_session_id.casecmp_to(u['session_id']) < 0:
		var result = webrtc_peer.create_offer()
		if result != OK:
			emit_signal("error", "Unable to create WebRTC offer")

func _webrtc_disconnect_peer(u: Dictionary):
	var webrtc_peer = webrtc_peers[u['session_id']]
	webrtc_peer.close()
	webrtc_peers.erase(u['session_id'])

func _on_webrtc_peer_session_description_created(type : String, sdp : String, session_id : String):
	var webrtc_peer = webrtc_peers[session_id]
	webrtc_peer.set_local_description(type, sdp)
	
	# Send this data to the peer so they can call call .set_remote_description().
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
	# Send this data to the peer so they can call .add_ice_candidate()
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

func _on_webrtc_peer_connected(peer_id: int):
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			webrtc_peers_connected[session_id] = true
			emit_signal("player_status_changed", players[session_id], PlayerStatus.CONNECTED)

	# We have a WebRTC peer for each connection to another player, so we'll have one less than
	# the number of players (ie. no peer connection to ourselves).
	if webrtc_peers_connected.size() == players.size() - 1:
		if players.size() >= min_players:
			# All our peers are good, so we can assume RPC will work now.
			match_state = MatchState.READY;
			emit_signal("match_ready", players)
		else:
			match_state = MatchState.WAITING_FOR_ENOUGH_PLAYERS

func _on_webrtc_peer_disconnected(peer_id: int):
	print ("WebRTC peer disconnected: " + str(peer_id))
	
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			webrtc_peers_connected.erase(session_id)

func _process(delta: float) -> void:
	if realtime_client:
		realtime_client.poll()

