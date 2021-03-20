extends Node2D

var ShakeCamera = preload("res://src/game/ShakeCamera.tscn")

var TankScene = preload("res://src/objects/Tank.tscn")

export (PackedScene) var map_scene = preload("res://src/maps/Map1.tscn")

onready var map: Node2D = $Map
onready var players_node := $Players
onready var watch_camera := $WatchCamera

var game_started := false
var players_alive := {}
var players_index := {}

signal game_started ()
signal player_dead (player_id, killer_id)

func _get_synchronized_rpc_methods() -> Array:
	return ['game_setup', 'respawn_player']

# Initializes the game so that it is ready to really start.
func game_setup(players: Dictionary) -> void:
	get_tree().set_pause(true)
	
	if game_started:
		game_stop()
	
	game_started = true
	players_alive = players
	
	reload_map()
	
	var player_index := 1
	for peer_id in players:
		players_index[peer_id] = player_index
		respawn_player(peer_id, players[peer_id])
		player_index += 1
	
	var my_id: int = get_tree().get_network_unique_id()
	make_player_controlled(my_id)

func respawn_player(peer_id, username) -> void:
	if players_node.has_node(str(peer_id)):
		return
	
	var player_index = players_index[peer_id]
	
	var player = TankScene.instance()
	player.name = str(peer_id)
	players_node.add_child(player)
	
	player.set_network_master(peer_id)
	player.set_player_name(username)
	player.player_index = player_index
	player.position = map.get_node("PlayerStartPositions/Player" + str(player_index)).position
	player.rotation = map.get_node("PlayerStartPositions/Player" + str(player_index)).rotation
	player.connect("player_dead", self, "_on_player_dead", [peer_id])

func make_player_controlled(peer_id) -> void:
	var my_player := players_node.get_node(str(peer_id))
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
			_on_player_dead(-1, player_id)

func enable_watch_camera(enable: bool = true) -> void:
	watch_camera.current = enable

func _on_player_dead(killer_id, player_id) -> void:
	# Ensure this will only ever be called once per player
	if players_alive.has(player_id):
		players_alive.erase(player_id)
		emit_signal("player_dead", player_id, killer_id)


