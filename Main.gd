extends Node2D

var Tank = preload("res://assets/Tank.tscn")

var player_name : String
var players = {}
var players_ready = []

var my_player

var game_started = false

func _ready():
	$CanvasLayer/ConnectionScreen.visible = true
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _on_ConnectionScreen_serve(_name : String, port : int) -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, 3)
	get_tree().set_network_peer(peer)
	
	player_name = _name
	
	$CanvasLayer/ConnectionScreen.visible = false
	$HUD.show_message("Waiting for players...")

func _on_ConnectionScreen_connect(_name : String, host : String, port : int) -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(host, port)
	get_tree().set_network_peer(peer)
	
	player_name = _name
	
	$CanvasLayer/ConnectionScreen.visible = false
	$HUD.show_message("Connecting...")

func _on_player_connected(peer_id : int) -> void:
	# This signal is emitted even on clients when they connect,
	# with peer_id = 1 for the server.
	
	rpc_id(peer_id, "register_player", player_name)

func _on_player_disconnected(peer_id : int) -> void:
	if players.has(peer_id):
		players.erase(peer_id)
	
	# TODO: if game hasn't started yet, change message about connected players

func _on_connected() -> void:
	$HUD.show_message("Waiting for game to start...")

func _on_connection_failed() -> void:
	$HUD.show_message("Failed to connect...")
	$CanvasLayer/ConnectionScreen.visible = true

func _on_server_disconnected() -> void:
	$HUD.show_message("Disconnected from server!")

remote func register_player(_name) -> void:
	var id = get_tree().get_rpc_sender_id()
	players[id] = _name
	
	if get_tree().is_network_server():
		if players.size() > 0:
			$HUD.show_message(str(players.size() + 1) + "/4 players connected")
			$HUD.show_start_button()

func _on_HUD_start() -> void:
	var player_start_positions = {}
	
	player_start_positions[1] = $PlayerStartPositions/Player1.position
	
	var i = 2
	for peer_id in players.keys():
		player_start_positions[peer_id] = $PlayerStartPositions.get_node("Player" + str(i)).global_position
		i += 1
		
	rpc("preconfigure_game", player_start_positions)

func _create_camera() -> Camera2D:	
	var camera = Camera2D.new()
	camera.current = true
	
	camera.limit_top = 0
	camera.limit_left = 0
	
	var tilemap_rect = $TileMap.get_used_rect()
	camera.limit_right = tilemap_rect.size.x * $TileMap.cell_size.x
	camera.limit_bottom = tilemap_rect.size.y * $TileMap.cell_size.y
	
	return camera

remotesync func preconfigure_game(player_start_positions : Dictionary) -> void:
	var my_id = get_tree().get_network_unique_id()
	
	my_player = Tank.instance()
	my_player.set_name(str(my_id))
	my_player.set_network_master(my_id)
	my_player.player_controlled = true
	my_player.position = player_start_positions[my_id]
	my_player.add_child(_create_camera())
	$Players.add_child(my_player)
	
	for peer_id in players:
		var other_player = Tank.instance()
		other_player.set_name(str(peer_id))
		other_player.set_network_master(peer_id)
		other_player.position = player_start_positions[peer_id]
		$Players.add_child(other_player)
	
	if my_id != 1:
		rpc_id(1, "done_preconfigure_game", my_id)

remote func done_preconfigure_game(peer_id) -> void:
	assert(get_tree().is_network_server())
	assert(peer_id in players)
	assert(not peer_id in players_ready)
	
	players_ready.append(peer_id)
	
	if players_ready.size() == players.size():
		rpc("post_configure_game")

remotesync func post_configure_game():
	$HUD.hide_all()
