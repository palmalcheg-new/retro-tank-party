extends Node2D

var Player1 = preload("res://tanks/Player1.tscn")
var Player2 = preload("res://tanks/Player2.tscn")
var Player3 = preload("res://tanks/Player3.tscn")
var Player4 = preload("res://tanks/Player4.tscn")
var TankScenes = {}

export (PackedScene) var map_scene = preload("res://maps/Map1.tscn")

onready var map: Node2D = $Map
onready var players_node := $Players
onready var watch_camera := $WatchCamera

var game_started := false
var game_over := false
var players_alive := {}
var players_setup := {}
var i_am_dead := false

signal game_started ()
signal player_dead (player_id)
signal game_over (player_id)

func _ready() -> void:
	TankScenes['Player1'] = Player1
	TankScenes['Player2'] = Player2
	TankScenes['Player3'] = Player3
	TankScenes['Player4'] = Player4

func game_start(players: Dictionary) -> void:
	if GameState.online_play:
		rpc("_do_game_setup", players)
	else:
		_do_game_setup(players)

# Initializes the game so that it is ready to really start.
remotesync func _do_game_setup(players: Dictionary) -> void:
	get_tree().set_pause(true)
	
	if game_started:
		game_stop()
	
	game_started = true
	game_over = false
	players_alive = players
	
	reload_map()
	
	for player_id in players:
		var other_player = TankScenes["Player" + str(player_id)].instance()
		other_player.name = str(player_id)
		players_node.add_child(other_player)
		
		other_player.set_network_master(player_id)
		other_player.set_player_name(players[player_id])
		other_player.position = map.get_node("PlayerStartPositions/Player" + str(player_id)).position
		other_player.rotation = map.get_node("PlayerStartPositions/Player" + str(player_id)).rotation
		other_player.connect("player_dead", self, "_on_player_dead", [player_id])
		
		if not GameState.online_play:
			other_player.player_controlled = true
			other_player.input_prefix = "player" + str(player_id) + "_"
	
	# @todo Deal with multiple local players
	var my_id: int = get_tree().get_network_unique_id() if GameState.online_play else 1
	var my_player := players_node.get_node(str(my_id))
	my_player.add_child(_create_camera())
	
	if GameState.online_play:
		my_player.player_controlled = true
		
		# Tell the host that we've finished setup.
		rpc_id(1, "_finished_game_setup", my_id)
	else:
		_do_game_start()

# Records when each player has finished setup so we know when all players are ready.
mastersync func _finished_game_setup(player_id: int) -> void:
	players_setup[player_id] = players_alive[player_id]
	if players_setup.size() == players_alive.size():
		# Once all clients have finished setup, tell them to start the game.
		rpc("_do_game_start")

# Actually start the game on this client.
remotesync func _do_game_start() -> void:
	if map.has_method('map_start'):
		map.map_start()
	emit_signal("game_started")
	get_tree().set_pause(false)

func game_stop() -> void:
	if map.has_method('map_stop'):
		map.map_stop()
	
	game_started = false
	players_setup.clear()
	players_alive.clear()
	i_am_dead = false
	watch_camera.current = false
	
	for child in players_node.get_children():
		players_node.remove_child(child)
		child.queue_free()

func reload_map() -> void:
	var map_index = map.get_index()
	remove_child(map)
	map.queue_free()
	
	map = map_scene.instance()
	map.name = 'Map'
	add_child(map)
	move_child(map, map_index)

func _create_camera() -> Camera2D:	
	var camera = Camera2D.new()
	camera.current = true
	
	camera.limit_top = 0
	camera.limit_left = 0
	
	var tilemap_rect = $Map/TileMap.get_used_rect()
	camera.limit_right = tilemap_rect.size.x * $Map/TileMap.cell_size.x
	camera.limit_bottom = tilemap_rect.size.y * $Map/TileMap.cell_size.y
	
	return camera

func kill_player(player_id) -> void:
	var player_node = players_node.get_node(str(player_id))
	if player_node:
		if player_node.has_method("die"):
			player_node.die()
		else:
			# If there is no die method, we do the most important things it
			# would have done.
			player_node.queue_free()
			_on_player_dead(player_id)

func _on_player_dead(player_id) -> void:
	emit_signal("player_dead", player_id)
	
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		# Switch to "watch" mode
		$WatchCamera.current = true
		i_am_dead = true
	
	players_alive.erase(player_id)
	if not game_over and players_alive.size() == 1:
		game_over = true
		var player_keys = players_alive.keys()
		emit_signal("game_over", player_keys[0])
