extends HBoxContainer

func _get_score_node(player_index: int):
	return get_node("Player%s/PlayerScore" % player_index)

func set_player_count(count: int) -> void:
	for i in range(1, 5):
		var score_node_parent = get_node("Player%s" % i)
		score_node_parent.visible = (i <= count)

func hide_player_score(player_index: int) -> void:
	var score_node_parent = get_node("Player%s" % player_index)
	score_node_parent.visible = false

func set_player_name(player_index: int, name: String) -> void:
	var score_node = _get_score_node(player_index)
	score_node.set_player_name(name)

remotesync func set_score(player_index: int, score: int) -> void:
	var score_node = _get_score_node(player_index)
	score_node.set_score(score)
