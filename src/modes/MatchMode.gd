extends Resource
class_name MatchMode

export (String) var name: String
export (String, MULTILINE) var description: String
export (String, FILE, "*.tscn") var manager_scene: String
export (String, FILE, "*.tscn") var config_scene: String

func instance_config_scene():
	var packed_scene = load(config_scene)
	if packed_scene == null or not packed_scene is PackedScene:
		return null
	return packed_scene.instance()
