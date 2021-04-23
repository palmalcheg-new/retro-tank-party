extends Node

var Game = preload("res://src/Game.gd")

var config: Dictionary
var match_scene
var map_path: String
var game
var ui_layer: UILayer
var players := {}

func match_setup(_info: Dictionary, _match_scene, _game, _ui_layer) -> void:
	config = _info['config']
	map_path = _info['map_path']
	match_scene = _match_scene
	game = _game
	ui_layer = _ui_layer
	
	_setup_players()
	
	# Now, the child classes setup.
	_do_match_setup()

func _setup_players() -> void:
	var online_players = OnlineMatch.get_players_by_peer_id()
	var peer_ids = online_players.keys()
	peer_ids.sort()
	
	var player_index := 1
	for peer_id in peer_ids:
		var online_player = online_players[peer_id]
		players[peer_id] = Game.Player.new(peer_id, online_player.username, player_index, _get_player_team(peer_id))
		player_index += 1

func _get_player_team(peer_id: int) -> int:
	if not config.has('teams'):
		return -1
	
	for team in config['teams']:
		if peer_id in team:
			return team
	
	return -1

#
# For child classes to override:
#

func _do_match_setup() -> void:
	# A sensible default.
	game.game_setup(OnlineMatch.get_player_names_by_peer_id(), map_path)

func match_start() -> void:
	# A sensible default.
	game.rpc("game_start")

func match_stop() -> void:
	pass
