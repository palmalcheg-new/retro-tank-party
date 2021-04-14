extends Node

var config: Dictionary
var match_scene
var map_path: String
var game
var ui_layer: UILayer

func match_setup(_info: Dictionary, _match_scene, _game, _ui_layer) -> void:
	config = _info['config']
	map_path = _info['map_path']
	match_scene = _match_scene
	game = _game
	ui_layer = _ui_layer
	
	_do_match_setup()

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
