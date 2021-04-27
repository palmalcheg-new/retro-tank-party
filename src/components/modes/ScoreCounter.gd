extends Reference

class ScorableEntity extends Reference:
	var name: String
	var score := 0
	
	func _init(_name: String) -> void:
		name = _name

var _score := {}

func _init() -> void:
	pass

func add_entity(id: int, name: String) -> void:
	var entity = ScorableEntity.new(name)
	_score[id] = entity

func get_entity(id: int) -> ScorableEntity:
	return _score.get(id)

func remove_entity(id: int) -> void:
	_score.erase(id)

func remove_all_entities() -> void:
	_score.clear()

func get_name(id: int) -> String:
	var entity = get_entity(id)
	assert (entity != null, "Cannot get name for scorable entity %s" % id)
	if entity:
		return entity.name
	return ""

func clear_score() -> void:
	for id in _score:
		_score[id].score = 0

func get_score(id: int) -> int:
	var entity = get_entity(id)
	assert (entity != null, "Cannot get score for scorable entity %s" % id)
	if entity:
		return entity.score
	return 0

func get_all_scores() -> Dictionary:
	var scores := {}
	for id in _score:
		scores[id] = _score[id].score
	return scores

func increment_score(id: int) -> void:
	var entity = get_entity(id)
	assert (entity != null, "Cannot increment for scorable entity %s" % id)
	if entity:
		entity.score += 1

func find_highest() -> Array:
	var max_score: int = get_all_scores().values().max()	
	
	var highest := []
	for id in _score:
		if _score[id].score == max_score:
			highest.append(id)
	
	return highest

