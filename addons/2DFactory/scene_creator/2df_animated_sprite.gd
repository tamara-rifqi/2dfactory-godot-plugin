extends RefCounted

const ANIM_CONTROLLER2D_SCRIPT := preload("res://addons/2DFactory/anim_controller/2df_anim_controller2d.gd")
const ANIM_CONTROLLER3D_SCRIPT := preload("res://addons/2DFactory/anim_controller/2df_anim_controller3d.gd")
const Socket_Creator = preload("res://addons/2DFactory/animated_sprites/2df_socket_creator.gd")

const MAP_MODE_NONE := 0
const MAP_MODE_NORMAL := 1
const MAP_MODE_PBR := 2

func _find_pbr_source(
		json_entries: Array[Dictionary]
	) -> Dictionary:
	for entry in json_entries:
		var source: Dictionary = entry.get(
			"source",
			{}
		)
		if source.get(
				"map_mode",
				MAP_MODE_NONE
			) == MAP_MODE_PBR:
			return source
	return {}
	
func _apply_pbr_material(
		sprite_3d: AnimatedSprite3D,
		source: Dictionary,
		isUpdating: bool,
	) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = source.get(
		"main_texture",
		null
	)
	var roughness_texture: Texture2D = source.get(
		"roughness_texture",
		null
	)
	material.roughness_texture = roughness_texture
	var normal_texture: Texture2D =  source.get(
		"normal_texture",
		null
	)
	material.normal_texture = normal_texture
	if normal_texture:
		material.normal_enabled = true
	var ao_texture: Texture2D = source.get(
		"ao_texture",
		null
	)
	material.ao_texture = ao_texture
	if ao_texture:
		material.ao_enabled = true
	var emission_texture: Texture2D = source.get(
		"emission_texture",
		null
	)
	material.emission_texture = emission_texture
	if emission_texture:
		material.emission_enabled = true
	if not isUpdating:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.5
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		var godot_version = Engine.get_version_info()
		if godot_version["major"] == 4 and godot_version["minor"] < 6:
			material.vertex_color_is_srgb = true
	if (roughness_texture != null
		or normal_texture != null
		or ao_texture != null
		or emission_texture != null
		):
		sprite_3d.material_override = material

func create_or_update(
		json_entries: Array[Dictionary],
		sprite_frames: SpriteFrames,
		scene_path: String,
		base_name: String,
		sprite_type: String
	) -> bool:
	var texture_filter2d := ProjectSettings.get_setting(
		"2d_factory/animated_sprites/texture_filter_2d",
		CanvasItem.TEXTURE_FILTER_PARENT_NODE
	)
	var texture_filter3d := ProjectSettings.get_setting(
		"2d_factory/animated_sprites/texture_filter_3d",
		BaseMaterial3D.TEXTURE_FILTER_NEAREST
	)
	var createSocket := Socket_Creator.new()
	var socket_first_meta: Dictionary = \
		createSocket._find_initial_socket_data(
			sprite_frames,
			json_entries
		)
	var pbr_source := _find_pbr_source(
		json_entries
	)
	# ---------------------------------------------------------
	# UPDATE EXISTING SCENE
	# ---------------------------------------------------------
	if FileAccess.file_exists(scene_path):
		print(
			"Existing scene found: ",
			scene_path
		)
		var packed_scene := ResourceLoader.load(
			scene_path,
			"",
			ResourceLoader.CACHE_MODE_REPLACE
		) as PackedScene
		if packed_scene == null:
			print_rich("[color=red]
				ERROR: Could not load existing scene: [/color]",
				scene_path
			)
			return false
		var root := packed_scene.instantiate()
		var animated_sprite: Node
		if sprite_type == "2D":
			var animated_sprite_2d := root.get_node_or_null(
				"AnimatedSprite2D"
			)
			var animated_sprite_3d := root.get_node_or_null(
				"AnimatedSprite3D"
			)
			if animated_sprite_3d != null:
				print_rich("[color=red]ERROR: Existing scene contains 
	AnimatedSprite3D, but the current workflow 
	is set to 2D: [/color]",
					scene_path
				)
				root.queue_free()
				return false
			animated_sprite = animated_sprite_2d
		elif sprite_type == "3D":
			var animated_sprite_2d := root.get_node_or_null(
				"AnimatedSprite2D"
			)
			var animated_sprite_3d := root.get_node_or_null(
				"AnimatedSprite3D"
			)
			if animated_sprite_2d != null:
				print_rich("[color=red]ERROR: Existing scene contains 
	AnimatedSprite2D, but the current workflow 
	is set to 3D: [/color]",
					scene_path
				)
				root.queue_free()
				return false
			animated_sprite = animated_sprite_3d
		else:
			print(
				"ERROR: Unknown sprite type: ",
				sprite_type
			)
			root.queue_free()
			return false
		if animated_sprite == null:
			print_rich("[color=yellow]AnimatedSprite",
				sprite_type,
				" not found in existing scene. 
				Recreating scene.[/color]"
			)
			root.queue_free()
		else:
			print("Updating scene: ", scene_path)
			# -----------------------------------------------------
			# Reassign SpriteFrames
			# -----------------------------------------------------
			if sprite_type == "2D":
				var sprite_2d := animated_sprite as AnimatedSprite2D
				sprite_2d.sprite_frames = sprite_frames
			elif sprite_type == "3D":
				var sprite_3d := animated_sprite as AnimatedSprite3D
				sprite_3d.sprite_frames = sprite_frames
				if not pbr_source.is_empty():
					_apply_pbr_material(
						sprite_3d,
						pbr_source,
						true
					)
			print("SpriteFrames reassigned successfully.")
			# -----------------------------------------------------
			# Ensure socket synced
			# -----------------------------------------------------
			if sprite_type == "2D":
				createSocket._ensure_2dsocket_nodes(
					animated_sprite as AnimatedSprite2D,
					json_entries
				)
				createSocket._apply_default_2dsocket_transform(
					animated_sprite as AnimatedSprite2D,
					socket_first_meta
				)
				print("Socket successfully updated")
			elif sprite_type == "3D":
				createSocket._ensure_3dsocket_nodes(
					animated_sprite as AnimatedSprite3D,
					json_entries
				)
				createSocket._apply_default_3dsocket_transform(
					animated_sprite as AnimatedSprite3D,
					socket_first_meta
				)
				print("Socket successfully updated")
			# -----------------------------------------------------
			# Re-pack existing scene
			# -----------------------------------------------------
			var updated_scene := PackedScene.new()
			var pack_result := updated_scene.pack(root)
			if pack_result != OK:
				print(
					"ERROR: Failed to repack existing ",
					sprite_type,
					" scene: ",
					pack_result
				)
				root.queue_free()
				return false
			var save_result := ResourceSaver.save(
				updated_scene,
				scene_path
			)
			root.queue_free()
			if save_result != OK:
				print(
					"ERROR: Failed to save updated ",
					sprite_type,
					" scene: ",
					save_result
				)
				return false
			print("Scene updated successfully: ", scene_path)
			return true
	# ---------------------------------------------------------
	# CREATE NEW SCENE
	# ---------------------------------------------------------
	print("No existing scene. Creating new scene: ", scene_path)
	var root: Node
	var animated_sprite: Node
	# ---------------------------------------------------------
	# Create 2D or 3D scene hierarchy
	# ---------------------------------------------------------
	if sprite_type == "2D":
		root = Node2D.new()
		root.name = base_name
		var sprite_2d := AnimatedSprite2D.new()
		sprite_2d.name = "AnimatedSprite2D"
		sprite_2d.sprite_frames = sprite_frames
		sprite_2d.set_script(ANIM_CONTROLLER2D_SCRIPT)
		sprite_2d.texture_filter = texture_filter2d
		animated_sprite = sprite_2d
	elif sprite_type == "3D":
		root = Node3D.new()
		root.name = base_name
		var sprite_3d := AnimatedSprite3D.new()
		sprite_3d.name = "AnimatedSprite3D"
		sprite_3d.sprite_frames = sprite_frames
		sprite_3d.set_script(ANIM_CONTROLLER3D_SCRIPT)
		sprite_3d.texture_filter = texture_filter3d
		animated_sprite = sprite_3d
		if not pbr_source.is_empty():
			_apply_pbr_material(
				sprite_3d,
				pbr_source,
				false
			)
	else:
		print("ERROR: Unknown sprite type: ", sprite_type)
		return false
	# ---------------------------------------------------------
	# Assign default pivot
	# ---------------------------------------------------------
	var first_json_meta: Dictionary = {}
	var animation_names := sprite_frames.get_animation_names()
	if not animation_names.is_empty():
		var first_animation: StringName = animation_names[0]
		for entry in json_entries:
			var entry_meta: Dictionary = entry.get(
				"meta",
				{}
			)
			var frame_tags: Dictionary = entry_meta.get(
				"frameTags",
				{}
			)
			if frame_tags.has(first_animation):
				first_json_meta = entry_meta
				break
		var first_frame_tags: Dictionary = first_json_meta.get(
			"frameTags",
			{}
		)
		if first_frame_tags.has(first_animation):
			var first_data: Dictionary = first_frame_tags[first_animation]
			var first_pivot: Vector2 = first_data.get(
				"pivot",
				Vector2.ZERO
			)
			if sprite_type == "2D":
				var sprite_2d := animated_sprite as AnimatedSprite2D
				sprite_2d.centered = true
				sprite_2d.offset = Vector2(
					-first_pivot.x,
					first_pivot.y
				)
			elif sprite_type == "3D":
				var sprite_3d := animated_sprite as AnimatedSprite3D
				sprite_3d.centered = true
				sprite_3d.offset = Vector2(
					-first_pivot.x,
					-first_pivot.y
				)
	# ---------------------------------------------------------
	# Add AnimatedSprite to scene
	# ---------------------------------------------------------
	root.add_child(animated_sprite)
	animated_sprite.owner = root
	# ---------------------------------------------------------
	# Create socket hierarchy
	# ---------------------------------------------------------
	for entry in json_entries:
		var entry_meta: Dictionary = entry.get(
			"meta",
			{}
		)
		if sprite_type == "2D":
			createSocket._create_2dsocket_nodes(
				animated_sprite,
				entry_meta
			)
		elif sprite_type == "3D":
			createSocket._create_3dsocket_nodes(
				animated_sprite,
				entry_meta
			)
	if sprite_type == "2D":
		createSocket._apply_default_2dsocket_transform(
			animated_sprite as AnimatedSprite2D,
			socket_first_meta
		)
	elif sprite_type == "3D":
		createSocket._apply_default_3dsocket_transform(
			animated_sprite as AnimatedSprite3D,
			socket_first_meta
		)
	# ---------------------------------------------------------
	# Pack scene
	# ---------------------------------------------------------
	var packed_scene := PackedScene.new()
	var result := packed_scene.pack(root)
	if result != OK:
		print(
			"ERROR: Failed to pack ",
			sprite_type,
			" AnimatedSprite scene: ",
			result
		)
		return false
	# ---------------------------------------------------------
	# Save scene
	# ---------------------------------------------------------
	result = ResourceSaver.save(
		packed_scene,
		scene_path
	)
	if result != OK:
		print(
			"ERROR: Failed to save ",
			sprite_type,
			" AnimatedSprite scene: ",
			result
		)
		return false
	return true
