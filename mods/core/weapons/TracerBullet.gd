extends "res://src/objects/Bullet.gd"

var target_seek_speed := 21845

var target_path: String = ''

func _network_spawn_preprocess(info: Dictionary) -> Dictionary:
	var res := ._network_spawn_preprocess(info)
	res['target_path'] = str(info['target'].get_path()) if info['target'] != null else ''
	return res

func _network_spawn(info: Dictionary) -> void:
	._network_spawn(info)
	target_path = info['target_path']

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['target_path'] = target_path
	return state

func _load_state(state: Dictionary) -> void:
	._load_state(state)
	target_path = state['target_path']

func _network_process(delta: float, input: Dictionary) -> void:
	if target_path != '':
		var target = get_node_or_null(target_path)
		if target:
			var target_vector = target.get_global_fixed_position().sub(get_global_fixed_position()).normalized()
			vector = vector.linear_interpolate(target_vector, target_seek_speed).normalized()
			fixed_rotation = vector.angle()
	
	._network_process(delta, input)
