extends RefCounted

func _set_texture_import_compression(
		texture_path: String,
		compression_mode: int
	) -> void:
	var import_path := texture_path + ".import"
	if not FileAccess.file_exists(import_path):
		print(
			"WARNING: Import file does not exist yet: ",
			import_path
		)
		return
	var config_file := ConfigFile.new()
	var load_result := config_file.load(import_path)
	if load_result != OK:
		print(
			"ERROR: Could not load import configuration: ",
			import_path
		)
		return
	# ---------------------------------------------------------
	# Change ResourceImporterTexture compression mode
	# ---------------------------------------------------------
	config_file.set_value(
		"params",
		"roughness/mode",
		1
	)
	config_file.set_value(
		"params",
		"detect_3d/compress_to",
		0
	)
	config_file.set_value(
		"params",
		"compress/mode",
		compression_mode
	)
	var save_result := config_file.save(import_path)
	if save_result != OK:
		print(
			"ERROR: Could not save import configuration: ",
			import_path
		)
		return
	print(
		"Texture compression updated: ",
		texture_path,
		" -> mode ",
		compression_mode
	)
	# ---------------------------------------------------------
	# Tell Godot to reimport the texture
	# ---------------------------------------------------------
	var editor_filesystem := (
		EditorInterface.get_resource_filesystem()
	)
	editor_filesystem.reimport_files(
		PackedStringArray([texture_path])
	)
	
func _apply_sprite_sheet_import_settings(
		json_directory: String,
		image_name: String
	) -> bool:
	var image_base_name := image_name.get_basename()
	var image_extension := image_name.get_extension()
	# ---------------------------------------------------------
	# Main sprite sheet
	# ---------------------------------------------------------
	var main_sheet_path := json_directory.path_join(
		image_name
	)
	if FileAccess.file_exists(main_sheet_path):
		var main_compression := ProjectSettings.get_setting(
			"2d_factory/sprite_sheet_import/main_compression",
			0
		)
		_set_texture_import_compression(
			main_sheet_path,
			main_compression
		)
	else:
		print(
			"WARNING: Main sprite sheet not found: ",
			main_sheet_path
		)
	# ---------------------------------------------------------
	# Optional normal map
	# ---------------------------------------------------------
	var normal_map_name := (
		image_base_name + "_N." + image_extension
	)
	var normal_map_path := json_directory.path_join(
		normal_map_name
	)
	if FileAccess.file_exists(normal_map_path):
		var normal_compression := ProjectSettings.get_setting(
			"2d_factory/sprite_sheet_import/normal_map_compression",
			0
		)
		_set_texture_import_compression(
			normal_map_path,
			normal_compression
		)
	else:
		print("No normal map found.")
		
	# ---------------------------------------------------------
	# Optional roughness map
	# ---------------------------------------------------------
	var roughness_map_name := (
		image_base_name + "_R." + image_extension
	)
	var roughness_map_path := json_directory.path_join(
		roughness_map_name
	)
	if FileAccess.file_exists(roughness_map_path):
		var roughness_compression := ProjectSettings.get_setting(
			"2d_factory/sprite_sheet_import/roughness_map_compression",
			0
		)
		_set_texture_import_compression(
			roughness_map_path,
			roughness_compression
		)
	else:
		print("No roughness map found.")
	# ---------------------------------------------------------
	# Optional ao map
	# ---------------------------------------------------------
	var ao_map_name := (
		image_base_name + "_AO." + image_extension
	)
	var ao_map_path := json_directory.path_join(
		ao_map_name
	)
	if FileAccess.file_exists(ao_map_path):
		var ao_compression := ProjectSettings.get_setting(
			"2d_factory/sprite_sheet_import/ao_map_compression",
			0
		)
		_set_texture_import_compression(
			ao_map_path,
			ao_compression
		)
	else:
		print("No ao map found.")
	# ---------------------------------------------------------
	# Optional emmision map
	# ---------------------------------------------------------
	var emission_map_name := (
		image_base_name + "_E." + image_extension
	)
	var emission_map_path := json_directory.path_join(
		emission_map_name
	)
	if FileAccess.file_exists(emission_map_path):
		var emission_compression := ProjectSettings.get_setting(
			"2d_factory/sprite_sheet_import/emission_map_compression",
			0
		)
		_set_texture_import_compression(
			emission_map_path,
			emission_compression
		)
	else:
		print("No emission map found.")
		
	return true
