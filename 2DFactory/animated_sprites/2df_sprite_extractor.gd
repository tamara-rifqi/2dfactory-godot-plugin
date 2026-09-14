extends RefCounted

const MAP_MODE_NONE := 0
const MAP_MODE_NORMAL := 1
const MAP_MODE_PBR := 2

func _create_canvas_texture(main_texture: Texture2D,normal_texture: Texture2D,
				output_directory: String,base_name: String) -> CanvasTexture:
	var canvas_texture := CanvasTexture.new()
	canvas_texture.diffuse_texture = main_texture
	canvas_texture.normal_texture = normal_texture
	var canvas_path := output_directory.path_join(
		base_name + "_CanvasTexture.tres"
	)
	var result := ResourceSaver.save(
		canvas_texture,
		canvas_path
	)
	if result != OK:
		print("ERROR: Failed to save CanvasTexture: ", result)
		return null
	print("CanvasTexture saved: ", canvas_path)
	return canvas_texture
	
func _load_optional_map(
		directory: String,
		base_name: String,
		extension: String,
		suffix: String
	) -> Texture2D:
	var file_name := (
		base_name + suffix + "." + extension
	)
	var path := directory.path_join(file_name)
	if not FileAccess.file_exists(path):
		print("No ", suffix, " map found: ", path)
		return null
	var texture := load(path) as Texture2D
	if texture == null:
		print(
			"WARNING: Could not load ",
			suffix,
			" map: ",
			path
		)
		return null
	print("Loaded ", suffix, " map: ", path)
	return texture
	
func _validate_existing_sprite_frames(
		sprite_frames: SpriteFrames,
		use_canvas_texture: bool
	) -> bool:
	for animation_name in sprite_frames.get_animation_names():
		var frame_count := sprite_frames.get_frame_count(
			animation_name
		)
		for frame_index in range(frame_count):
			var texture := sprite_frames.get_frame_texture(
				animation_name,
				frame_index
			)
			if texture == null:
				continue
			if not texture is AtlasTexture:
				continue
			var atlas := texture as AtlasTexture
			if atlas.atlas == null:
				continue
			if atlas.atlas is CanvasTexture \
					and not use_canvas_texture:
				print_rich("[color=red]ERROR: Existing SpriteFrames uses 
	CanvasTexture, which is incompatible 
	with the current 3D workflow.[/color]"
				)
				return false
			# First valid frame is enough for a generated
			# SpriteFrames resource.
			return true
	return true
	
func _create_or_update_sprite_frames(json_meta: Dictionary, main_texture: Texture2D,
		canvas_texture: CanvasTexture, use_canvas_texture: bool,
		sprite_frames_path: String) -> SpriteFrames:
	var sprite_frames: SpriteFrames
	# ---------------------------------------------------------
	# 1. Load existing SpriteFrames if it exists
	# ---------------------------------------------------------
	if FileAccess.file_exists(sprite_frames_path):
		print("Existing SpriteFrames found: ", sprite_frames_path)
		sprite_frames = ResourceLoader.load(
			sprite_frames_path,
			"",
			ResourceLoader.CACHE_MODE_REPLACE
		) as SpriteFrames
		if sprite_frames == null:
			print(
				"ERROR: Could not load existing SpriteFrames."
			)
			return null
		if not _validate_existing_sprite_frames(
				sprite_frames,
				use_canvas_texture
			):
			return null
	else:
		# -----------------------------------------------------
		# 2. No existing SpriteFrames -> create new
		# -----------------------------------------------------
		print("No existing SpriteFrames. Creating new one.")
		sprite_frames = SpriteFrames.new()
		# Remove Godot's default animation.
		if sprite_frames.has_animation("default"):
			sprite_frames.remove_animation("default")
			
	# Add/update animations from this JSON
	if not add_json_animations(
			sprite_frames,
			json_meta,
			main_texture,
			canvas_texture,
			use_canvas_texture
		):
		return null
	# ---------------------------------------------------------
	# 5. Save the same SpriteFrames resource
	# ---------------------------------------------------------
	var save_result := ResourceSaver.save(
		sprite_frames,
		sprite_frames_path
	)
	if save_result != OK:
		print(
			"ERROR: Could not save SpriteFrames: ",
			save_result
		)
		return null
	print(
		"SpriteFrames saved/updated: ",
		sprite_frames_path
	)
	return sprite_frames
	
func add_json_animations(
		sprite_frames: SpriteFrames,
		json_meta: Dictionary,
		main_texture: Texture2D,
		canvas_texture: CanvasTexture,
		use_canvas_texture: bool
	) -> bool:
	# ---------------------------------------------------------
	# Get animations from JSON
	# ---------------------------------------------------------
	var frame_tags: Dictionary = json_meta.get(
		"frameTags", {})
	if frame_tags.is_empty():
		print("ERROR: No frame tags found in JSON.")
		return false
	# ---------------------------------------------------------
	# Process ONLY animations present in JSON
	# ---------------------------------------------------------
	for tag_name in frame_tags.keys():
		var tag_data: Dictionary = frame_tags[tag_name]
		var frames: Array = tag_data.get("frames", [])
		if frames.is_empty():
			print("WARNING: No frames found for tag: ", tag_name)
			continue
		print("Updating animation: ", tag_name)
		# -----------------------------------------------------
		# Animation properties
		# -----------------------------------------------------
		var existing_frame_durations: Array[float] = []
		var animation_speed := 5.0
		var tag_loop := true
		# Loop is ALWAYS controlled by JSON.
		if tag_data.has("loop"):
			tag_loop = str(
				tag_data["loop"]
			).to_lower() == "true"
		if sprite_frames.has_animation(tag_name):
			# -------------------------------------------------
			# Existing animation:
			# Preserve FPS.
			# -------------------------------------------------
			animation_speed = sprite_frames.get_animation_speed(
				tag_name
			)
			# -------------------------------------------------
			# Preserve individual frame duration multipliers.
			# -------------------------------------------------
			var old_frame_count := sprite_frames.get_frame_count(
				tag_name
			)
			for i in range(old_frame_count):
				existing_frame_durations.append(
					sprite_frames.get_frame_duration(
						tag_name,
						i
					)
				)
			# Replace old frames.
			sprite_frames.clear(tag_name)
		else:
			# -------------------------------------------------
			# New animation
			# -------------------------------------------------
			sprite_frames.add_animation(tag_name)
			# Default FPS for newly created animations.
			animation_speed = 5.0
		# -----------------------------------------------------
		# Apply animation-level settings
		# -----------------------------------------------------
		sprite_frames.set_animation_speed(tag_name, animation_speed)
		sprite_frames.set_animation_loop(tag_name, tag_loop)
		# ---------------------------------------------------------
		# Determine frame order from animation direction
		# ---------------------------------------------------------
		var ordered_frame_indices: Array[int] = []
		var frame_count := frames.size()
		var direction := "forward"
		if tag_data.has("direction"):
			direction = str(tag_data["direction"]).to_lower()
		match direction:
			"reverse":
				for i in range(frame_count - 1, -1, -1):
					ordered_frame_indices.append(i)
			"pingpong":
				for i in range(frame_count):
					ordered_frame_indices.append(i)
				if frame_count > 1:
					for i in range(frame_count - 2, -1, -1):
						ordered_frame_indices.append(i)
			"forward", _:
				for i in range(frame_count):
					ordered_frame_indices.append(i)
		# ---------------------------------------------------------
		# Frame extraction
		# ---------------------------------------------------------
		for original_frame_index in ordered_frame_indices:
			var frame_data = frames[original_frame_index]
			if not frame_data is Dictionary:
				continue
			var frame_rect: Dictionary = frame_data.get(
				"frame",
				{}
			)
			if frame_rect.is_empty():
				continue
			var x := int(frame_rect.get("x", 0))
			var y := int(frame_rect.get("y", 0))
			var w := int(frame_rect.get("w", 0))
			var h := int(frame_rect.get("h", 0))
			if w <= 0 or h <= 0:
				continue
			# -----------------------------------------------------
			# Create AtlasTexture for this frame
			# -----------------------------------------------------
			var atlas := AtlasTexture.new()
			if use_canvas_texture and canvas_texture != null:
				atlas.atlas = canvas_texture
			else:
				atlas.atlas = main_texture
			atlas.region = Rect2(
				x,
				y,
				w,
				h
			)
			# -----------------------------------------------------
			# Preserve frame duration
			# -----------------------------------------------------
			var frame_duration := 1.0
			if original_frame_index < existing_frame_durations.size():
				frame_duration = existing_frame_durations[
					original_frame_index
				]
			# -----------------------------------------------------
			# Add frame
			# -----------------------------------------------------
			sprite_frames.add_frame(
				tag_name,
				atlas,
				frame_duration
			)
	return true
	
func prepare_source(
		json_meta: Dictionary,
		json_file_path: String,
		map_mode: int
	) -> Dictionary:
	# ---------------------------------------------------------
	# 1. Get information from JSON
	# ---------------------------------------------------------
	var json_directory := json_file_path.get_base_dir()
	var image_name: String = json_meta.get("image", "")
	if image_name.is_empty():
		print("ERROR: JSON meta does not contain 'image'.")
		return {}
	print("JSON directory: ", json_directory)
	print("Main image: ", image_name)
	# ---------------------------------------------------------
	# 2. Locate main sprite sheet
	# ---------------------------------------------------------
	var main_sheet_path := json_directory.path_join(
		image_name
	)
	if not FileAccess.file_exists(main_sheet_path):
		print("ERROR: Main sprite sheet not found.")
		print("Expected: ", main_sheet_path)
		return {}
	print("Main sprite sheet found: ", main_sheet_path)
	# ---------------------------------------------------------
	# 3. Locate optional normal map
	# ---------------------------------------------------------
	var image_base_name := image_name.get_basename()
	var image_extension := image_name.get_extension()
	# ---------------------------------------------------------
	# 5. Load textures
	# ---------------------------------------------------------
	var main_texture := load(
		main_sheet_path
	) as Texture2D
	if main_texture == null:
		print("ERROR: Could not load main sprite sheet.")
		return {}
	if map_mode == MAP_MODE_NONE:
		return {
			"json_directory": json_directory,
			"image_name": image_name,
			"image_base_name": image_base_name,
			"main_sheet_path": main_sheet_path,
			"main_texture": main_texture,
			"normal_texture": null,
			"ao_texture": null,
			"roughness_texture": null,
			"emission_texture": null,
			"canvas_texture": null,
			"use_canvas_texture": false,
			"map_mode": map_mode
		}
	
	var normal_texture: Texture2D = null
	var canvas_texture: CanvasTexture = null
	var use_normal_map := false
	if map_mode == MAP_MODE_NORMAL:
		var normal_map_name := (
			image_base_name + "_N." + image_extension
		)
		var normal_map_path := json_directory.path_join(
			normal_map_name
		)
		if FileAccess.file_exists(normal_map_path):
			print("Normal map found: ", normal_map_path)
			normal_texture = load(
				normal_map_path
			) as Texture2D

			if normal_texture != null:
				use_normal_map = true
				canvas_texture = _create_canvas_texture(
					main_texture,
					normal_texture,
					json_directory,
					image_base_name
				)
				if canvas_texture == null:
					print(
	                    "ERROR: Could not create CanvasTexture."
					)
					return {}
		return {
			"json_directory": json_directory,
			"image_name": image_name,
			"image_base_name": image_base_name,
			"main_sheet_path": main_sheet_path,
			"main_texture": main_texture,
			"normal_texture": normal_texture,
			"ao_texture": null,
			"roughness_texture": null,
			"emission_texture": null,
			"canvas_texture": canvas_texture,
			"use_canvas_texture": canvas_texture != null,
			"map_mode": map_mode
		}
	var ao_texture: Texture2D = null
	var roughness_texture: Texture2D = null
	var emission_texture: Texture2D = null
	if map_mode == MAP_MODE_PBR:
		normal_texture = _load_optional_map(
			json_directory,
			image_base_name,
			image_extension,
	        "_N"
		)
		ao_texture = _load_optional_map(
			json_directory,
			image_base_name,
			image_extension,
	        "_AO"
		)
		roughness_texture = _load_optional_map(
			json_directory,
			image_base_name,
			image_extension,
	        "_R"
		)
		emission_texture = _load_optional_map(
			json_directory,
			image_base_name,
			image_extension,
	        "_E"
		)
		return {
			"json_directory": json_directory,
			"image_name": image_name,
			"image_base_name": image_base_name,
			"main_sheet_path": main_sheet_path,
			"main_texture": main_texture,
			"normal_texture": normal_texture,
			"ao_texture": ao_texture,
			"roughness_texture": roughness_texture,
			"emission_texture": emission_texture,
			"canvas_texture": null,
			"use_canvas_texture": false,
			"map_mode": map_mode
		}
	return {}
	
func extract(
		json_meta: Dictionary,
		json_file_path: String,
		sprite_type: String,
		map_mode: int
	) -> SpriteFrames:
	print("=== 2D FACTORY: SPRITE EXTRACTION ===")
	# ---------------------------------------------------------
	# 1. Prepare source
	# ---------------------------------------------------------
	var source := prepare_source(
		json_meta,
		json_file_path,
		map_mode
	)
	if source.is_empty():
		print("ERROR: Could not prepare sprite source.")
		return null
	# ---------------------------------------------------------
	# 2. Get prepared source data
	# ---------------------------------------------------------
	var json_directory: String = source["json_directory"]
	var image_base_name: String = source["image_base_name"]
	var main_texture: Texture2D = source["main_texture"]
	var canvas_texture: CanvasTexture = source["canvas_texture"]
	var use_canvas_texture: bool = source[
		"use_canvas_texture"
	]
	# ---------------------------------------------------------
	# 3. Create or update SpriteFrames
	# ---------------------------------------------------------
	var sprite_frames_path := json_directory.path_join(
		image_base_name + "_SpriteFrames.tres"
	)
	var sprite_frames := _create_or_update_sprite_frames(
		json_meta,
		main_texture,
		canvas_texture,
		use_canvas_texture,
		sprite_frames_path
	)
	if sprite_frames == null:
		print("ERROR: Could not create/update SpriteFrames.")
		return null
	print(
		"SpriteFrames ready: ",
		sprite_frames_path
	)
	return sprite_frames
