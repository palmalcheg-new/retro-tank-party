extends "res://src/ui/Screen.gd"

onready var option_switcher := $PanelContainer/VBoxContainer/OptionSwitcher
onready var panel_parent := $PanelContainer/VBoxContainer/MarginContainer
onready var matchmaker_player_count_control := $PanelContainer/VBoxContainer/MarginContainer/MatchPanel/Fields/PlayerCount
onready var join_match_id_control := $PanelContainer/VBoxContainer/MarginContainer/JoinPanel/Fields/LineEdit

func _ready() -> void:
	option_switcher.add_item("Create a private match", "CreatePanel")
	option_switcher.add_item("Join a private match", "JoinPanel")
	option_switcher.add_item("Find a public match", "MatchPanel")
	
	matchmaker_player_count_control.add_item("2 players", 2)
	matchmaker_player_count_control.add_item("3 players", 3)
	matchmaker_player_count_control.add_item("4 players", 4)
	
	$PanelContainer/VBoxContainer/MarginContainer/MatchPanel/MatchButton.connect("pressed", self, "_on_match_button_pressed", [OnlineMatch.MatchMode.MATCHMAKER])
	$PanelContainer/VBoxContainer/MarginContainer/CreatePanel/CreateButton.connect("pressed", self, "_on_match_button_pressed", [OnlineMatch.MatchMode.CREATE])
	$PanelContainer/VBoxContainer/MarginContainer/JoinPanel/JoinButton.connect("pressed", self, "_on_match_button_pressed", [OnlineMatch.MatchMode.JOIN])
	
	OnlineMatch.connect("matchmaker_matched", self, "_on_OnlineMatch_matchmaker_matched")
	OnlineMatch.connect("match_created", self, "_on_OnlineMatch_created")
	OnlineMatch.connect("match_joined", self, "_on_OnlineMatch_joined")

func _show_screen(_info: Dictionary = {}) -> void:
	option_switcher.value = "CreatePanel"
	matchmaker_player_count_control.value = 2
	join_match_id_control.text = ''
	option_switcher.focus.grab_without_sound()
	
	if Globals.arguments.has('join'):
		# @todo Handle other values.
		if Globals.arguments['join'] == 'matchmaker':
			_on_match_button_pressed(OnlineMatch.MatchMode.MATCHMAKER)

func _on_OptionSwitcher_item_selected(value, index) -> void:
	var panel = panel_parent.get_node(value)
	if not panel:
		return
	
	for child in panel_parent.get_children():
		child.visible = false
	panel.visible = true

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
	
	if GameSettings.use_network_relay >= GameSettings.NetworkRelay.FALLBACK:
		OnlineMatch.ice_servers = Build.fallback_ice_servers
	else:
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
					OnlineMatch.ice_servers = ice_servers + Build.fallback_ice_servers
				else:
					print ("Server error in RPC call get_ice_servers(): %s" % json_result.result)
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

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if get_focus_owner() is Button:
		return
	
	if event.is_action_pressed("ui_accept"):
		get_tree().set_input_as_handled()
		_ui_accept_pressed()
	
func _ui_accept_pressed() -> void:
	var match_mode: int
	match option_switcher.value:
		"CreatePanel":
			match_mode = OnlineMatch.MatchMode.CREATE
		"JoinPanel":
			match_mode = OnlineMatch.MatchMode.JOIN
		"MatchPanel":
			match_mode = OnlineMatch.MatchMode.MATCHMAKER
	
	_on_match_button_pressed(match_mode)

func _on_LineEdit_text_entered(new_text: String) -> void:
	_ui_accept_pressed()
