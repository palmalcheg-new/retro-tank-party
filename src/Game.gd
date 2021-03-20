extends Node2D

var ShakeCamera = preload("res://src/ShakeCamera.tscn")

var Player1 = preload("res://src/tanks/Player1.tscn")
var Player2 = preload("res://src/tanks/Player2.tscn")
var Player3 = preload("res://src/tanks/Player3.tscn")
var Player4 = preload("res://src/tanks/Player4.tscn")
var TankScenes = {}

export (PackedScene) var map_scene = preload("res://src/maps/Map1.tscn")

onready var map: Node2D = $Map
onready var players_node := $Players
onready var watch_camera := $WatchCamera

var game_started := false
var game_over := false
var players_alive := {}

signal game_started ()
signal player_dead (player_id)

func _ready() -> void:
	TankScenes['Player1'] = Player1
	TankScenes['Player2'] = Player2
	TankScenes['Player3'] = Player3
	TankScenes['Player4'] = Player4

func _get_synchronized_rpc_methods() -> Array:
	return ['game_setup']

# Initializes the game so that it is ready to really start.
func game_setup(players: Dictionary) -> void:
	get_tree().set_pause(true)
	
	if game_started:
		game_stop()
	
	game_started = true
	game_over = false
	players_alive = players
	
	reload_map()
	
	var player_index := 1
	for peer_id in players:
		var other_player = TankScenes["Player" + str(player_index)].instance()
		other_player.name = str(peer_id)
		players_node.add_child(other_player)
		
		other_player.set_network_master(peer_id)
		other_player.set_player_name(players[peer_id])
		other_player.position = map.get_node("PlayerStartPositions/Player" + str(player_index)).position
		other_player.rotation = map.get_node("PlayerStartPositions/Player" + str(player_index)).rotation
		other_player.connect("player_dead", self, "_on_player_dead", [peer_id])
		
		player_index += 1
	
	var my_id: int = get_tree().get_network_unique_id()
	var my_player := players_node.get_node(str(my_id))
	my_player.player_controlled = true
	my_player.add_child(_create_camera())

# Actually start the game on this client.
remotesync func game_start() -> void:
	if map.has_method('map_start'):
		map.map_start()
	emit_signal("game_started")
	get_tree().set_pause(false)

func game_stop() -> void:
	if map.has_method('map_stop'):
		map.map_stop()
	
	game_started = false
	players_alive.clear()
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
	var camera = ShakeCamera.instance()
	camera.name = "Camera"
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

func enable_watch_camera(enable: bool = true) -> void:
	watch_camera.current = enable

func _on_player_dead(player_id) -> void:
	players_alive.erase(player_id)
	emit_signal("player_dead", player_id)


