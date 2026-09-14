extends RefCounted

func scan_json(
		scan_path: String,
		excluded_directories: Array[String] = [],
		max_depth: int = 5
	) -> Array[String]:
	var all_json: Array[String] = []
	_scan_json_recursive(
		scan_path,
		excluded_directories,
		all_json,
		0,
		max_depth
	)
	all_json.sort()
	return all_json

func _scan_json_recursive(
		directory_path: String,
		excluded_directories: Array[String],
		all_json: Array[String],
		current_depth: int,
		max_depth: int
	) -> void:
	var dir := DirAccess.open(directory_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := directory_path.path_join(file_name)
		if dir.current_is_dir():
			if (
				file_name not in excluded_directories
				and current_depth < max_depth
			):
				_scan_json_recursive(
					full_path,
					excluded_directories,
					all_json,
					current_depth + 1,
					max_depth
				)
		else:
			if file_name.get_extension().to_lower() == "json":
				all_json.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
