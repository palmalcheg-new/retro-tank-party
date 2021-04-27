extends HBoxContainer

func _get_score_node(index: int):
	return get_node("Entity%s/EntityScore" % index)

func set_entity_count(count: int) -> void:
	for i in range(1, 5):
		var score_node_parent = get_node("Entity%s" % i)
		score_node_parent.visible = (i <= count)

func hide_entity_score(index: int) -> void:
	var score_node_parent = get_node("Entity%s" % index)
	score_node_parent.visible = false

func set_entity_name(index: int, name: String) -> void:
	var score_node = _get_score_node(index)
	score_node.set_entity_name(name)

remotesync func set_score(index: int, score: int) -> void:
	var score_node = _get_score_node(index)
	score_node.set_score(score)
