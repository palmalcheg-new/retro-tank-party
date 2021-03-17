extends "res://main/Screen.gd"

onready var matchmaker_match_button := $PanelContainer/VBoxContainer/MatchPanel/MatchButton
onready var matchmaker_player_count_control := $PanelContainer/VBoxContainer/MatchPanel/SpinBox
onready var join_match_id_control := $PanelContainer/VBoxContainer/JoinPanel/LineEdit

func _ready() -> void:
	$PanelContainer/VBoxContainer/MatchPanel/MatchButton.connect("pressed", self, "_on_match_button_pressed", [OnlineMatch.MatchMode.MATCHMAKER])
	$PanelContainer/VBoxContainer/CreatePanel/CreateButton.connect("pressed", self, "_on_match_button_pressed", [OnlineMatch.MatchMode.CREATE])
	$PanelContainer/VBoxContainer/JoinPanel/JoinButton.connect("pressed", self, "_on_match_button_pressed", [OnlineMatch.MatchMode.JOIN])
	
	OnlineMatch.connect("matchmaker_matched", self, "_on_OnlineMatch_matchmaker_matched")
	OnlineMatch.connect("match_created", self, "_on_OnlineMatch_created")
	OnlineMatch.connect("match_joined", self, "_on_OnlineMatch_joined")

func _show_screen(_info: Dictionary = {}) -> void:
	matchmaker_player_count_control.value = 2
	join_match_id_control.text = ''
	matchmaker_match_button.grab_focus()

func _on_match_button_pressed(mode) -> void:
	# If our session has expired, show the ConnectionScreen again.
	if Online.nakama_session == null or Online.nakama_session.is_expired():
		ui_layer.show_screen("ConnectionScreen", { next_screen = null, reconnect = true })
		
		# Wait to see if we get a new valid session.
		yield(Online, "session_changed")
		if Online.nakama_session == null:
			return
	
	# Connect socket to realtime Nakama API if not connected.
	if not Online.is_nakama_socket_connected():
		Online.connect_nakama_socket()
		yield(Online, "socket_connected")
	
	ui_layer.hide_message()
	
	# Ask Nakma for the ICE servers via RPC.
	var ice_servers_result: NakamaAPI.ApiRpc = yield(Online.nakama_client.rpc_async(Online.nakama_session, 'get_ice_servers'), "completed")
	if not ice_servers_result.is_exception():
		var json_result = JSON.parse(ice_servers_result.payload)
		if json_result.error == OK:
			if json_result.result["success"]:
				var ice_servers = json_result.result["response"]["ice_servers"]
				for server in ice_servers:
					# Set 'credentials' due to bug in WebRTC GDNative plugin.
					if server.has('credential'):
						server['credentials'] = server['credential']
					# I'm not sure this is necessary, but we usually give 'urls'
					# as an array.
					if server.has('urls') and typeof(server['urls']) != TYPE_ARRAY:
						server['urls'] = [ server['urls'] ]

				print ("Using ICE server list from server")
				OnlineMatch.ice_servers = ice_servers
			else:
				print ("Server error in RPC call get_ice_servers(): %s" % json_result.result["response"])
		else:
			print ("Unable to parse JSON: %s" % ice_servers_result.payload)
	else:
		print ("Client error in RPC call get_ice_servers(): %s" % ice_servers_result.get_exception().message)
	
	# Call internal method to do actual work.
	match mode:
		OnlineMatch.MatchMode.MATCHMAKER:
			_start_matchmaking()
		OnlineMatch.MatchMode.CREATE:
			_create_match()
		OnlineMatch.MatchMode.JOIN:
			_join_match()

func _start_matchmaking() -> void:
	var min_players = matchmaker_player_count_control.value
	
	ui_layer.hide_screen()
	ui_layer.show_message("Looking for match...")
	
	var data = {
		min_count = min_players,
		string_properties = {
			game = "retro_tank_party1",
		},
		query = "+properties.game:retro_tank_party1",
	}
	
	OnlineMatch.start_matchmaking(Online.nakama_socket, data)

func _on_OnlineMatch_matchmaker_matched(_players: Dictionary):
	ui_layer.hide_message()
	ui_layer.show_screen("ReadyScreen", { players = _players })

func _create_match() -> void:
	OnlineMatch.create_match(Online.nakama_socket)

func _on_OnlineMatch_created(match_id: String):
	ui_layer.show_screen("ReadyScreen", { match_id = match_id, clear = true })

func _join_match() -> void:
	var match_id = join_match_id_control.text.strip_edges()
	if match_id == '':
		ui_layer.show_message("Need to paste Match ID to join")
		return
	if not match_id.ends_with('.'):
		match_id += '.'
	
	OnlineMatch.join_match(Online.nakama_socket, match_id)

func _on_OnlineMatch_joined(match_id: String):
	ui_layer.show_screen("ReadyScreen", { match_id = match_id, clear = true })

func _on_PasteButton_pressed() -> void:
	join_match_id_control.text = OS.clipboard
