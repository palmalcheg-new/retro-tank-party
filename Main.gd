extends Node2D

var Player1 = preload("res://tanks/Player1.tscn")
var Player2 = preload("res://tanks/Player2.tscn")
var Player3 = preload("res://tanks/Player3.tscn")
var Player4 = preload("res://tanks/Player4.tscn")
var TankScenes = {}

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
	
	if "--test-mode" in OS.get_cmdline_args():
		test_mode = true
		_on_ConnectionScreen_serve('Tester', 12233)
		$HUD.hide_all()
		start_new_game()
		return
	
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
	
	if not game_started:
		rpc_id(peer_id, "register_player", player_name)
	else:
		$HUD.rpc_id(peer_id, "Game already in progress. Sorry!")

func _on_player_disconnected(peer_id : int) -> void:
	if players.has(peer_id):
		players.erase(peer_id)
	if players_ready.has(peer_id):
		players_ready.erase(peer_id)
	
	if get_tree().is_network_server() and not game_started:
		if players.size() == 0:
			$HUD.show_message("Waiting for players...")
			$HUD.hide_start_button()
		elif players.size() > 0:
			$HUD.show_message(str(players.size() + 1) + "/4 players connected")
			$HUD.show_start_button()

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
	if game_started:
		restart_game()
	else:
		start_new_game()

func start_new_game() -> void:
	var player_info = {
		1: {
			'tank': 'Player1',
			'position': $PlayerStartPositions/Player1.global_position,
			'rotation': $PlayerStartPositions/Player1.global_rotation,
		},
	}

	var i = 2
	for peer_id in players.keys():
		player_info[peer_id] = {
			'tank': "Player" + str(i),
			'position': $PlayerStartPositions.get_node("Player" + str(i)).global_position,
			'rotation': $PlayerStartPositions.get_node("Player" + str(i)).global_rotation,
		}
		i += 1
		
	rpc("preconfigure_game", player_info)
	
	$DropCrateSpawnArea1.start()
	$DropCrateSpawnArea2.start()

func restart_game() -> void:
	my_player = null
	players_ready.clear()
	start_new_game()

func _create_camera() -> Camera2D:	
	var camera = Camera2D.new()
	camera.current = true
	
	camera.limit_top = 0
	camera.limit_left = 0
	
	var tilemap_rect = $TileMap.get_used_rect()
	camera.limit_right = tilemap_rect.size.x * $TileMap.cell_size.x
	camera.limit_bottom = tilemap_rect.size.y * $TileMap.cell_size.y
	
	return camera

remotesync func preconfigure_game(player_info : Dictionary) -> void:
	# This is to clean up from a previous game.
	if game_started:
		i_am_dead = false
		$WatchCamera.current = false
		for child in $Players.get_children():
			$Players.remove_child(child)
			child.queue_free()
		$DropCrateSpawnArea1.clear()
		$DropCrateSpawnArea2.clear()
	
	var my_id = get_tree().get_network_unique_id()
	
	my_player = TankScenes[player_info[my_id]['tank']].instance()
	my_player.set_name(str(my_id))
	my_player.set_network_master(my_id)
	my_player.set_player_name(player_name)
	my_player.player_controlled = true
	my_player.position = player_info[my_id]['position']
	my_player.rotation = player_info[my_id]['rotation']
	my_player.add_child(_create_camera())
	my_player.connect("dead", self, "_on_player_dead")
	$Players.add_child(my_player)
	
	for peer_id in players:
		var other_player = TankScenes[player_info[peer_id]['tank']].instance()
		other_player.set_name(str(peer_id))
		other_player.set_network_master(peer_id)
		other_player.set_player_name(players[peer_id])
		other_player.position = player_info[peer_id]['position']
		other_player.rotation = player_info[peer_id]['rotation']
		other_player.connect("dead", self, "_on_player_dead")
		$Players.add_child(other_player)
	
	if my_id != 1:
		rpc_id(1, "done_preconfigure_game", my_id)

remote func done_preconfigure_game(peer_id) -> void:
	assert(get_tree().is_network_server())
	assert(peer_id in players)
	assert(not players_ready.has(peer_id))
	
	players_ready[peer_id] = players[peer_id]
	
	if players_ready.size() == players.size():
		rpc("post_configure_game")

remotesync func post_configure_game():
	game_started = true
	$HUD.hide_all()

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
		if players_ready.size() == 0 or (i_am_dead and players_ready.size() == 1):
			var winner = player_name
			if players_ready.size() > 0:
				var winners = players_ready.values()
				winner = winners[0]
			$HUD.rpc("show_message", winner + " is the winner!")
			$HUD.show_start_button("Play again")
