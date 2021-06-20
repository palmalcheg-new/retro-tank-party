extends Node

const ScoreCounter = preload("res://src/components/modes/ScoreCounter.gd")
const Game = preload("res://src/Game.gd")

var config: Dictionary
var match_scene
var map_path: String
var teams := []
var use_teams := false
var game
var ui_layer: UILayer
var players := {}
var score := ScoreCounter.new()

func match_setup(_info: Dictionary, _match_scene, _game, _ui_layer) -> void:
	config = _info['config']
	map_path = _info['map_path']
	teams = _info['teams']
	use_teams = config.get('teams', false)
	match_scene = _match_scene
	game = _game
	ui_layer = _ui_layer
	
	_setup_players()
	_setup_score()
	
	# Now, the child classes setup.
	_do_match_setup()

func _setup_players() -> void:
	var online_players = OnlineMatch.get_players_by_peer_id()
	var peer_ids = online_players.keys()
	peer_ids.sort()
	
	var player_index := 1
	for peer_id in peer_ids:
		var online_player = online_players[peer_id]
		players[peer_id] = Game.Player.new(peer_id, online_player.username, player_index, get_player_team(peer_id))
		player_index += 1

func _setup_score() -> void:
	if use_teams:
		for team_id in range(teams.size()):
			score.add_entity(team_id, Globals.TEAM_NAMES[team_id])
	else:
		for player_id in players:
			score.add_entity(player_id, players[player_id].name)

func get_player_team(peer_id: int) -> int:
	if not use_teams:
		return -1
	
	var team_index := 0
	for team in teams:
		if peer_id in team:
			return team_index
		team_index += 1
	
	return -1

#
# For child classes to override:
#

func _do_match_setup() -> void:
	# A sensible default.
	game.game_setup(players, map_path)

func match_start() -> void:
	# A sensible default.
	game.rpc("game_start")

func match_stop() -> void:
	pass
