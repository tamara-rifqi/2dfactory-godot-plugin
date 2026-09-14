extends RefCounted

const SpritesExtractor = preload("res://addons/2DFactory/animated_sprites/2df_sprite_extractor.gd")
const SceneCreator = preload("res://addons/2DFactory/scene_creator/2df_animated_sprite.gd")
const TwoDFJsonParser = preload("res://addons/2DFactory/json_parser/2df_json_parser.gd")
const TextureImporter = preload("res://addons/2DFactory/dedicated_setting/2df_tximporter_setting.gd")
const DirScanner = preload("res://addons/2DFactory/utilities/2df_directory_scanner.gd")
var excluded_scan_dir: Array[String] = [".godot", "addons", "_reserved"]
const MAX_OUTPUT_NAME_LENGTH := 64
const MAX_SCAN_DEPTH_SETTING := (
	"2d_factory/general/max_recursives_can_depth"
)

func _apply_texture_importer(json_directory: String, image_name: String) -> void:
	if image_name.is_empty():
		print("ERROR: JSON does not specify an image.")
		return
	var texture_importer := TextureImporter.new()
	if not texture_importer._apply_sprite_sheet_import_settings(
			json_directory,
			image_name
		):
		print("ERROR: Failed to apply sprite sheet import settings.")
		return
	return


func _is_valid_2df_json(json_meta: Dictionary) -> bool:
	if not json_meta.has("image"):
		print("No image field found in JSON")
		return false
	if not json_meta.has("frameTags"):
		print("No frameTags field found in JSON")
		return false
	if not json_meta["frameTags"] is Dictionary:
		print("The frameTags found in JSON is not dict")
		return false
	return true
	
func _register_animation_sources(
		json_meta: Dictionary,
		json_file_path: String,
		animation_sources: Dictionary
	) -> bool:
	var frame_tags: Dictionary = json_meta.get(
		"frameTags",
		{}
	)
	for animation_name in frame_tags.keys():
		var animation_key := str(animation_name)
		if animation_sources.has(animation_key):
			print("")
			print("ERROR: Duplicate animation name found.")
			print("Animation: ", animation_key)
			print("JSON files:")
			print(
				"  - ",
				animation_sources[animation_key]
			)
			print(
				"  - ",
				json_file_path
			)
			return false
		animation_sources[animation_key] = json_file_path
	return true
	
func _get_separate_sheet_output_name(
		scan_path: String
	) -> String:
	var output_name := str(
		ProjectSettings.get_setting(
			"2d_factory/animated_sprites/separate_sheet_output_name",
			"{FOLDER}"
		)
	)
	if output_name.is_empty():
		output_name = "{FOLDER}"
	var folder_name := scan_path.get_base_dir().get_file()
	output_name = output_name.replace(
		"{FOLDER}",
		folder_name
	)
	const MAX_OUTPUT_NAME_LENGTH := 64
	if output_name.length() > MAX_OUTPUT_NAME_LENGTH:
		print(
			"WARNING: Separate Sheet output name is too long. ",
			"It will be truncated to ",
			MAX_OUTPUT_NAME_LENGTH,
			" characters."
		)
		output_name = output_name.left(
			MAX_OUTPUT_NAME_LENGTH
		)
	return output_name
	
func single_sheet_workflow(
		scan_path: String,
		sprite_type: String
	) -> void:
	var max_scan_depth: int = ProjectSettings.get_setting(
		MAX_SCAN_DEPTH_SETTING,
		5
	)
	var dir_scanner := DirScanner.new()
	var json_paths := dir_scanner.scan_json(scan_path, excluded_scan_dir)
	if json_paths.is_empty():
		print("No JSON files found.")
		return
	print("")
	print_rich("[color=yellow]=========================================[/color]")
	print_rich("[color=yellow]=========================================[/color]")
	print("=== 2D FACTORY: SINGLE SHEET WORKFLOW ===")
	print("JSON files found: ", json_paths.size())
	var extractor := SpritesExtractor.new()
	var scene_creator := SceneCreator.new()
	var animation_sources: Dictionary = {}
	for json_file_path in json_paths:
		print("----------------------------------------")
		print("Processing JSON: ", json_file_path)
		print("----------------------------------------")
		# 1. Parse JSON
		var parser := TwoDFJsonParser.new()
		if not parser.parse_json_file(json_file_path):
			print("ERROR: JSON parsing failed.")
			continue
		var json_meta: Dictionary = parser.json_meta
		if not _register_animation_sources(
				json_meta,
				json_file_path,
				animation_sources
			):
			print("")
			print_rich("[color=red]Single Sheet workflow aborted.[/color]")
			print_rich("[color=red]Duplicate animation found. Please rename the duplicate animation(s).[/color]")
			return
		var json_directory := json_file_path.get_base_dir()
		var image_name: String = json_meta.get("image", "")
		var apply_texture_settings := ProjectSettings.get_setting(
			"2d_factory/sprite_sheet_import/apply_texture_settings",
			true
		)
		if apply_texture_settings:
			_apply_texture_importer(json_directory, image_name)
		# 2. Extract/update SpriteFrames
		var map_mode := SpritesExtractor.MAP_MODE_NONE
		if sprite_type == "2D":
			map_mode = SpritesExtractor.MAP_MODE_NORMAL
		else:
			map_mode = SpritesExtractor.MAP_MODE_PBR
		var sprite_frames := extractor.extract(
			json_meta,
			json_file_path,
			sprite_type,
			map_mode
		)
		if sprite_frames == null:
			print("ERROR: Sprite extraction failed.")
			continue
		# 3. Determine resource paths
		if image_name.is_empty():
			print("ERROR: JSON does not contain 'image'.")
			continue
		var image_base_name := image_name.get_basename()
		var sprite_frames_path := json_directory.path_join(
			image_base_name + "_SpriteFrames.tres"
		)
		var scene_path := json_directory.path_join(
			image_base_name + ".tscn"
		)
		# 4. Create/update scene
		var source := extractor.prepare_source(
			json_meta,
			json_file_path,
			map_mode
		)
		var json_entries: Array[Dictionary] = []
		json_entries.append({
			"path": json_file_path,
			"meta": json_meta,
			"source": source
		})
		if not scene_creator.create_or_update(
				json_entries,
				sprite_frames,
				scene_path,
				image_base_name,
				sprite_type):
			print_rich("[color=red]ERROR: Failed to create/update scene.[/color]")
			continue
		print("=== SINGLE SHEET PROCESSING COMPLETED ===")
		print("SpriteFrames: ", sprite_frames_path)
		print("Scene: ", scene_path)
	
	print_rich("[color=yellow]=========================================[/color]")
	print_rich("[color=yellow]=========================================[/color]")
	print("")
	
func separate_sheet_workflow(
		scan_path: String,
		sprite_type: String
	) -> void:
	print("")
	print_rich("[color=yellow]=========================================[/color]")
	print_rich("[color=yellow]=========================================[/color]")
	print("=== 2D FACTORY: SEPARATE SHEET WORKFLOW ===")
	# ---------------------------------------------------------
	# 1. Collect all JSON files
	# ---------------------------------------------------------
	var max_scan_depth: int = ProjectSettings.get_setting(
		MAX_SCAN_DEPTH_SETTING,
		5
	)
	var dir_scanner := DirScanner.new()
	var json_paths := dir_scanner.scan_json(
		scan_path,
		excluded_scan_dir
	)
	if json_paths.is_empty():
		print("No JSON files found.")
		return
	print("JSON files found: ", json_paths.size())
	var output_name := _get_separate_sheet_output_name(
		scan_path
	)
	# =========================================================
	# PHASE 1 — VALIDATE AND PREPARE
	# =========================================================
	var extractor := SpritesExtractor.new()
	var json_entries: Array[Dictionary] = []
	var animation_sources: Dictionary = {}
	for json_file_path in json_paths:
		print("----------------------------------------")
		print("Processing JSON: ", json_file_path)
		print("----------------------------------------")
		# -----------------------------------------------------
		# 1a. Parse JSON
		# -----------------------------------------------------
		var parser := TwoDFJsonParser.new()
		if not parser.parse_json_file(json_file_path):
			print_rich("[color=red]ERROR: JSON parsing failed.[/color]")
			print("Path: ", json_file_path)
			print("Separate Sheet workflow aborted.")
			return
		var json_meta: Dictionary = parser.json_meta
		# -----------------------------------------------------
		# 1b. Validate JSON structure
		# -----------------------------------------------------
		if not _is_valid_2df_json(json_meta):
			print(
				"ERROR: Invalid 2D Factory JSON: ",
				json_file_path
			)
			print("Separate Sheet workflow aborted.")
			return
		# -----------------------------------------------------
		# 1c. Check duplicate animation names
		# -----------------------------------------------------
		if not _register_animation_sources(
				json_meta,
				json_file_path,
				animation_sources
			):
			print_rich("[color=red]Separate Sheet workflow aborted.[/color]")
			print("Please rename the duplicate animation(s).")
			return
		# -----------------------------------------------------
		# 1d. Apply texture import settings
		# -----------------------------------------------------
		var json_directory := json_file_path.get_base_dir()
		var image_name: String = json_meta.get(
			"image",
			""
		)
		var apply_texture_settings := ProjectSettings.get_setting(
			"2d_factory/sprite_sheet_import/apply_texture_settings",
			true
		)
		if apply_texture_settings:
			_apply_texture_importer(json_directory, image_name)
		# -----------------------------------------------------
		# 1e. Prepare texture source
		# -----------------------------------------------------
		var map_mode := SpritesExtractor.MAP_MODE_NONE
		if sprite_type == "2D":
			map_mode = SpritesExtractor.MAP_MODE_NORMAL
		else:
			map_mode = SpritesExtractor.MAP_MODE_NONE
		var source := extractor.prepare_source(
			json_meta,
			json_file_path,
			map_mode
		)
		if source.is_empty():
			print(
				"ERROR: Could not prepare sprite source."
			)
			print("Path: ", json_file_path)
			print("Separate Sheet workflow aborted.")
			return
		# -----------------------------------------------------
		# 1f. Store everything needed for Phase 2
		# -----------------------------------------------------
		json_entries.append({
			"path": json_file_path,
			"meta": json_meta,
			"source": source
		})
	print("Processed JSON files: ", json_entries.size())

	# =========================================================
	# PHASE 2 — GENERATE
	# =========================================================
	# ---------------------------------------------------------
	# 2a. Create / load combined SpriteFrames
	# ---------------------------------------------------------
	var combined_sprite_frames_path := scan_path.path_join(
		output_name + "_SpriteFrames.tres"
	)
	var combined_sprite_frames: SpriteFrames
	if FileAccess.file_exists(
			combined_sprite_frames_path
		):
		print(
			"Existing SpriteFrames found: ",
			combined_sprite_frames_path
		)
		combined_sprite_frames = ResourceLoader.load(
			combined_sprite_frames_path,
			"",
			ResourceLoader.CACHE_MODE_REPLACE
		) as SpriteFrames
		if combined_sprite_frames == null:
			print(
				"ERROR: Could not load combined SpriteFrames."
			)
			return
	else:
		print("Creating new SpriteFrames.")
		combined_sprite_frames = SpriteFrames.new()
		if combined_sprite_frames.has_animation(
				"default"
			):
			combined_sprite_frames.remove_animation(
				"default"
			)
	# ---------------------------------------------------------
	# 2b. Add all animations
	# ---------------------------------------------------------
	for entry in json_entries:
		var json_file_path: String = entry["path"]
		var json_meta: Dictionary = entry["meta"]
		var source: Dictionary = entry["source"]
		var main_texture: Texture2D = source[
			"main_texture"
		]
		var canvas_texture: CanvasTexture = source[
			"canvas_texture"
		]
		var use_canvas_texture: bool = source[
			"use_canvas_texture"
		]
		print("")
		print(
			"Adding animations from: ",
			json_file_path
		)
		if not extractor.add_json_animations(
				combined_sprite_frames,
				json_meta,
				main_texture,
				canvas_texture,
				use_canvas_texture
			):
			print_rich("[color=red]
				ERROR: Could not add animations from JSON.[/color]"
			)
			print("Path: ", json_file_path)
			print("Separate Sheet workflow aborted.")
			return
	# ---------------------------------------------------------
	# 2c. Save combined SpriteFrames
	# ---------------------------------------------------------
	var save_result := ResourceSaver.save(
		combined_sprite_frames,
		combined_sprite_frames_path
	)
	if save_result != OK:
		print(
			"ERROR: Could not save combined SpriteFrames: ",
			combined_sprite_frames_path
		)
		return
	# ---------------------------------------------------------
	# 2d. Create / update scene
	# ---------------------------------------------------------
	var scene_creator := SceneCreator.new()
	var scene_path := scan_path.path_join(
		output_name + ".tscn"
	)
	if not scene_creator.create_or_update(
			json_entries,
			combined_sprite_frames,
			scene_path,
			output_name,
			sprite_type
		):
		print_rich("[color=red]
			ERROR: Could not create/update combined scene.[/color]"
		)
		return
	# ---------------------------------------------------------
	# 2e. Refresh Godot filesystem
	# ---------------------------------------------------------
	var editor_filesystem := (
		EditorInterface.get_resource_filesystem()
	)
	editor_filesystem.scan()
	print("=== SEPARATE SHEET PROCESSING COMPLETED ===")
	print("SpriteFrames: ", combined_sprite_frames_path)
	print("Scene: ", scene_path)
	print_rich("[color=yellow]=========================================[/color]")
	print_rich("[color=yellow]=========================================[/color]")
	print("")
