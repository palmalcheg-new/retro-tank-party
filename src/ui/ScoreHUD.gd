extends HBoxContainer

func _get_score_node(index: int):
	return get_node("Entity%s/EntityScore" % index)

func set_entity_count(count: int) -> void:
	for i in range(1, 5):
		var score_node_parent = get_node("Entity%s" % i)
		assert(score_node_parent != null)
		if score_node_parent:
			score_node_parent.visible = (i <= count)

func hide_entity_score(index: int) -> void:
	var score_node_parent = get_node("Entity%s" % index)
	assert(score_node_parent != null)
	if score_node_parent:
		score_node_parent.visible = false

func set_entity_name(index: int, name: String) -> void:
	var score_node = _get_score_node(index)
	assert(score_node != null)
	if score_node:
		score_node.set_entity_name(name)

func set_score(index: int, score: int) -> void:
	var score_node = _get_score_node(index)
	assert(score_node != null)
	if score_node:
		score_node.set_score(score)
