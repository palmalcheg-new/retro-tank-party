extends "res://src/ui/Screen.gd"

onready var field_container = $Panel/VBoxContainer/GridContainer
onready var next_button = $Panel/VBoxContainer/NextButton

var fields := []
var player_ids := []

func _ready() -> void:
	# @todo: handle a player disconnecting during setup
	var player_names = OnlineMatch.get_player_names_by_peer_id()
	player_ids = player_names.keys()
	player_ids.sort()
	
	for i in range(4):
		var player_number = i + 1
		var label = field_container.get_node("Player%sLabel" % player_number)
		var field = field_container.get_node("Player%sTeam" % player_number)

		field.add_item("Red", Globals.Teams.RED, Globals.TEAM_COLORS[Globals.Teams.RED])
		field.add_item("Blue", Globals.Teams.BLUE, Globals.TEAM_COLORS[Globals.Teams.BLUE])
		field.set_value(i % 2, false)
		field.connect("item_selected", self, "_on_team_selected", [i])
		fields.append(field)
		
		if player_number > OnlineMatch.players.size():
			label.visible = false
			field.visible = false
			continue
		
		var player_id = player_ids[i]
		label.text = player_names[player_id]

func _show_screen(info: Dictionary = {}) -> void:
	fields[0].focus.grab_without_sound()

func disable_screen() -> void:
	for field in fields:
		field.disabled = true
	next_button.disabled = true

func _on_team_selected(value, index, field_index) -> void:
	if is_network_master():
		rpc("_remote_update", field_index, value)

puppet func _remote_update(field_index: int, value: int) -> void:
	fields[field_index].value = value

func _on_NextButton_pressed() -> void:
	var teams = get_teams()
	for team in teams:
		if team.size() == 0:
			ui_layer.show_message('Each team must have at least 1 player!')
			return
	
	ui_layer.rpc("show_screen", "MapScreen")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed('ui_accept'):
		get_tree().set_input_as_handled()
		_on_NextButton_pressed()

func get_teams() -> Array:
	var teams = []
	for i in range(2):
		teams.append([])
	
	for i in range(4):
		if i < player_ids.size():
			teams[fields[i].value].append(player_ids[i])
	
	return teams

func set_teams(teams: Array) -> void:
	for team_id in range(2):
		for player_id in teams[team_id]:
			var i = player_ids.find(player_id)
			if i != -1:
				fields[i].value = team_id
