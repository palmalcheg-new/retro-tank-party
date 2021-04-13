extends Node

func _ready() -> void:
	if OS.has_feature('standalone'):
		_load_pcks()

func _load_pcks() -> void:
	for file_path in list_pcks():
		print (">> Loading mod %s..." % file_path)
		ProjectSettings.load_resource_pack(file_path, false)

func list_pcks() -> Array:
	var file_paths = []
	var mods_path = OS.get_executable_path().get_base_dir() + '/mods/'
	
	var dir = Directory.new()
	if dir.open(mods_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".pck"):
					file_paths.append(mods_path + file_name)
			file_name = dir.get_next()
	
	return file_paths

func list_mods() -> Array:
	var mods := []
	
	var dir = Directory.new()
	if dir.open('res://mods/') == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				mods.append(file_name)
			file_name = dir.get_next()
	
	return mods

func _list_resources(path) -> Array:
	var file_paths = []
	
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".tres.converted.res"):
					file_name = file_name.left(file_name.length() - 14)
				if file_name.ends_with(".tres"):
					file_paths.append(path + file_name)
			file_name = dir.get_next()
	
	return file_paths

func find_resources(resource_name: String) -> Array:
	var file_paths = _list_resources("res://src/%s/" % resource_name)
	
	for mod in list_mods():
		file_paths = file_paths + _list_resources("res://mods/%s/%s/" % [mod, resource_name])
	
	return file_paths
