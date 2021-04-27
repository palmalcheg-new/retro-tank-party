extends Reference

class ScorableEntity extends Reference:
	var name: String
	var score: int
	
	func _init(_name: String, entities: int = 0) -> void:
		name = _name
		score = entities
	
	static func from_dict(data: Dictionary) -> ScorableEntity:
		return ScorableEntity.new(data['name'], int(data['score']))
	
	func to_dict() -> Dictionary:
		return {
			name = name,
			score = score,
		}

var entities := {}

func _init(serialized: Dictionary = {}) -> void:
	for id in serialized:
		entities[id] = ScorableEntity.from_dict(serialized[id])

func to_dict() -> Dictionary:
	var result := {}
	for id in entities:
		result[id] = entities[id].to_dict()
	return result

func add_entity(id: int, name: String) -> void:
	var entity = ScorableEntity.new(name)
	entities[id] = entity

func get_entity(id: int) -> ScorableEntity:
	return entities.get(id)

func remove_entity(id: int) -> void:
	entities.erase(id)

func remove_all_entities() -> void:
	entities.clear()

func get_name(id: int) -> String:
	var entity = get_entity(id)
	assert (entity != null, "Cannot get name for scorable entity %s" % id)
	if entity:
		return entity.name
	return ""

func clear_score() -> void:
	for id in entities:
		entities[id].score = 0

func get_score(id: int) -> int:
	var entity = get_entity(id)
	assert (entity != null, "Cannot get score for scorable entity %s" % id)
	if entity:
		return entity.score
	return 0

func get_all_scores() -> Dictionary:
	var scores := {}
	for id in entities:
		scores[id] = entities[id].score
	return scores

func increment_score(id: int) -> void:
	var entity = get_entity(id)
	assert (entity != null, "Cannot increment for scorable entity %s" % id)
	if entity:
		entity.score += 1

func find_highest() -> Array:
	var max_score: int = get_all_scores().values().max()	
	
	var highest := []
	for id in entities:
		if entities[id].score == max_score:
			highest.append(id)
	
	return highest

