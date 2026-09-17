extends RefCounted

var create_reticle := ProjectSettings.get_setting(
	"2d_factory/animated_sprites/create_socket_reticle",
	true
)

func _find_initial_socket_data(
		sprite_frames: SpriteFrames,
		json_entries: Array[Dictionary]
	) -> Dictionary:
	var initial_socket_data: Dictionary = {}
	var animation_names := sprite_frames.get_animation_names()
	if animation_names.is_empty():
		return initial_socket_data
	for animation_name in animation_names:
		for entry in json_entries:
			var json_meta: Dictionary = entry.get(
				"meta",
				{}
			)
			var frame_tags: Dictionary = json_meta.get(
				"frameTags",
				{}
			)
			if not frame_tags.has(animation_name):
				continue
			var anim_frame_tags: Dictionary = frame_tags[animation_name]
			var anim_frames: Array = anim_frame_tags.get(
				"frames",
				[]
			)
			if anim_frames.is_empty():
				continue
			var frame_count := anim_frames.size()
			var direction := str(
				anim_frame_tags.get(
					"direction",
                    "forward"
				)
			).to_lower()
			var original_frame_index := 0
			match direction:
				"reverse":
					original_frame_index = frame_count - 1
				"pingpong":
					original_frame_index = 0
				"forward", _:
					original_frame_index = 0
			if original_frame_index < 0 \
					or original_frame_index >= frame_count:
				continue
			var frame_data: Dictionary = anim_frames[
				original_frame_index
			]
			var sockets: Dictionary = frame_data.get(
				"sockets",
				{}
			)
			for socket_name in sockets.keys():
				var socket_name_string := str(socket_name)
				if socket_name_string.is_empty():
					continue
				if initial_socket_data.has(
						socket_name_string
					):
					continue
				initial_socket_data[socket_name_string] = {
					"meta": json_meta,
					"animation": animation_name,
					"frame_data": frame_data
				}
	return initial_socket_data

func _create_2dsocket_nodes(
		animated_sprite: AnimatedSprite2D,
		json_meta: Dictionary
	):
	var socket_root: Node2D = animated_sprite.get_node_or_null(
		"Socket"
	)
	if socket_root == null:
		socket_root = Node2D.new()
		socket_root.name = "Socket"
		animated_sprite.add_child(socket_root)
		socket_root.owner = animated_sprite.owner
	var reticle_texture := load(
		"res://addons/2DFactory/resources/socket_reticle.png"
	) as Texture2D
	if reticle_texture == null:
		print("WARNING: Could not load socket reticle texture.")
	var frame_tags: Dictionary = json_meta.get(
		"frameTags",
		{}
	)
	for tag_name in frame_tags.keys():
		var tag_data: Dictionary = frame_tags[tag_name]
		var frames: Array = tag_data.get("frames", [])
		for frame_data in frames:
			if not frame_data is Dictionary:
				continue
			var sockets: Dictionary = frame_data.get(
				"sockets",
				{}
			)
			for socket_name in sockets.keys():
				var socket_name_string := str(socket_name)
				if socket_name_string.is_empty():
					continue
				if socket_root.has_node(socket_name_string):
					continue
				# -------------------------------------------------
				# Create socket transform node
				# -------------------------------------------------
				var socket_node := Node2D.new()
				socket_node.name = socket_name_string
				socket_root.add_child(socket_node)
				socket_node.owner = animated_sprite.owner
				# -------------------------------------------------
				# Create visible socket reticle
				# -------------------------------------------------
				if create_reticle and reticle_texture != null:
					var reticle := Sprite2D.new()
					reticle.name = "Reticle"
					reticle.texture = reticle_texture
					reticle.centered = true
					reticle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					socket_node.add_child(reticle)
					reticle.owner = animated_sprite.owner
				
func _create_3dsocket_nodes(
		animated_sprite: AnimatedSprite3D,
		json_meta: Dictionary
	):
	var socket_root: Node3D = animated_sprite.get_node_or_null(
		"Socket"
	)
	if socket_root == null:
		socket_root = Node3D.new()
		socket_root.name = "Socket"
		animated_sprite.add_child(socket_root)
		socket_root.owner = animated_sprite.owner
	var reticle_texture := load(
		"res://addons/2DFactory/resources/socket_reticle.png"
	) as Texture2D
	if reticle_texture == null:
		print("WARNING: Could not load socket reticle texture.")
	var frame_tags: Dictionary = json_meta.get(
		"frameTags",
		{}
	)
	for tag_name in frame_tags.keys():
		var tag_data: Dictionary = frame_tags[tag_name]
		var frames: Array = tag_data.get("frames", [])
		for frame_data in frames:
			if not frame_data is Dictionary:
				continue
			var sockets: Dictionary = frame_data.get(
				"sockets",
				{}
			)
			for socket_name in sockets.keys():
				var socket_name_string := str(socket_name)
				if socket_name_string.is_empty():
					continue
				if socket_root.has_node(socket_name_string):
					continue
				# -------------------------------------------------
				# Create socket transform node
				# -------------------------------------------------
				var socket_node := Node3D.new()
				socket_node.name = socket_name_string
				socket_root.add_child(socket_node)
				socket_node.owner = animated_sprite.owner
				# -------------------------------------------------
				# Create visible socket reticle
				# -------------------------------------------------
				if create_reticle and reticle_texture != null:
					var reticle := Sprite3D.new()
					reticle.name = "Reticle"
					reticle.texture = reticle_texture
					reticle.pixel_size = 0.01
					reticle.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					reticle.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
					socket_node.add_child(reticle)
					reticle.owner = animated_sprite.owner

func _ensure_2dsocket_nodes(
		animated_sprite: AnimatedSprite2D,
		json_entries: Array[Dictionary]
	) -> void:
	var socket_root := animated_sprite.get_node_or_null(
		"Socket"
	) as Node2D
	# ---------------------------------------------------------
	# Create Socket root if it does not exist
	# ---------------------------------------------------------
	if socket_root == null:
		socket_root = Node2D.new()
		socket_root.name = "Socket"
		animated_sprite.add_child(socket_root)
		socket_root.owner = animated_sprite.owner
	var reticle_texture := load(
		"res://addons/2DFactory/resources/socket_reticle.png"
	) as Texture2D
	if reticle_texture == null:
		print("WARNING: Could not load socket reticle texture.")
	# ---------------------------------------------------------
	# Check every JSON entry
	# ---------------------------------------------------------
	for entry in json_entries:
		var json_meta: Dictionary = entry.get(
			"meta",
			{}
		)
		var frame_tags: Dictionary = json_meta.get(
			"frameTags",
			{}
		)
		for tag_name in frame_tags.keys():
			var tag_data: Dictionary = frame_tags[tag_name]
			var frames: Array = tag_data.get(
				"frames",
				[]
			)
			for frame_data in frames:
				if not frame_data is Dictionary:
					continue
				var sockets: Dictionary = frame_data.get(
					"sockets",
					{}
				)
				for socket_name in sockets.keys():
					var socket_name_string := str(socket_name)
					if socket_name_string.is_empty():
						continue
					# -------------------------------------------------
					# Socket already exists.
					# Preserve the existing node and anything
					# the user has added/modified under it.
					# -------------------------------------------------
					if socket_root.has_node(socket_name_string):
						continue
					# -------------------------------------------------
					# Create missing socket transform node
					# -------------------------------------------------
					var socket_node := Node2D.new()
					socket_node.name = socket_name_string
					socket_root.add_child(socket_node)
					socket_node.owner = animated_sprite.owner
					# -------------------------------------------------
					# Create visible socket reticle
					# -------------------------------------------------
					if create_reticle and reticle_texture != null:
						var reticle := Sprite2D.new()
						reticle.name = "Reticle"
						reticle.texture = reticle_texture
						reticle.centered = true
						reticle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
						socket_node.add_child(reticle)
						reticle.owner = animated_sprite.owner
					print(
						"Added missing socket: ",
						socket_name_string
					)
func _ensure_3dsocket_nodes(
		animated_sprite: AnimatedSprite3D,
		json_entries: Array[Dictionary]
	) -> void:
	var socket_root := animated_sprite.get_node_or_null(
		"Socket"
	) as Node3D
	# ---------------------------------------------------------
	# Create Socket root if it does not exist
	# ---------------------------------------------------------
	if socket_root == null:
		socket_root = Node3D.new()
		socket_root.name = "Socket"
		animated_sprite.add_child(socket_root)
		socket_root.owner = animated_sprite.owner
	var reticle_texture := load(
		"res://addons/2DFactory/resources/socket_reticle.png"
	) as Texture2D
	if reticle_texture == null:
		print("WARNING: Could not load socket reticle texture.")
	# ---------------------------------------------------------
	# Check every JSON entry
	# ---------------------------------------------------------
	for entry in json_entries:
		var json_meta: Dictionary = entry.get(
			"meta",
			{}
		)
		var frame_tags: Dictionary = json_meta.get(
			"frameTags",
			{}
		)
		for tag_name in frame_tags.keys():
			var tag_data: Dictionary = frame_tags[tag_name]
			var frames: Array = tag_data.get(
				"frames",
				[]
			)
			for frame_data in frames:
				if not frame_data is Dictionary:
					continue
				var sockets: Dictionary = frame_data.get(
					"sockets",
					{}
				)
				for socket_name in sockets.keys():
					var socket_name_string := str(socket_name)
					if socket_name_string.is_empty():
						continue
					# -------------------------------------------------
					# Socket already exists.
					# Preserve the existing node and anything
					# the user has added/modified under it.
					# -------------------------------------------------
					if socket_root.has_node(socket_name_string):
						continue
					# -------------------------------------------------
					# Create missing socket transform node
					# -------------------------------------------------
					var socket_node := Node3D.new()
					socket_node.name = socket_name_string
					socket_root.add_child(socket_node)
					socket_node.owner = animated_sprite.owner
					# -------------------------------------------------
					# Create visible socket reticle
					# -------------------------------------------------
					if create_reticle and reticle_texture != null:
						var reticle := Sprite3D.new()
						reticle.name = "Reticle"
						reticle.texture = reticle_texture
						reticle.centered = true
						reticle.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
						reticle.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
						socket_node.add_child(reticle)
						reticle.owner = animated_sprite.owner
					print(
						"Added missing socket: ",
						socket_name_string
					)

func _apply_default_2dsocket_transform(
		animated_sprite: AnimatedSprite2D,
		initial_socket_data: Dictionary
	) -> void:
	if initial_socket_data.is_empty():
		return
	for socket_name in initial_socket_data.keys():
		var socket_info: Dictionary = initial_socket_data[
			socket_name
		]
		var json_meta: Dictionary = socket_info.get(
			"meta",
			{}
		)
		var animation_name: StringName = socket_info.get(
			"animation",
            ""
		)
		var frame_data: Dictionary = socket_info.get(
			"frame_data",
			{}
		)
		var frame_tags: Dictionary = json_meta.get(
			"frameTags",
			{}
		)
		if not frame_tags.has(animation_name):
			continue
		var anim_frame_tags: Dictionary = frame_tags[
			animation_name
		]
		var frame_sockets: Dictionary = frame_data.get(
			"sockets",
			{}
		)
		if not frame_sockets.has(socket_name):
			continue
		var socket_data = frame_sockets[socket_name]
		if not socket_data is Dictionary:
			continue
		var socket_node := animated_sprite.get_node_or_null(
			"Socket/" + str(socket_name)
		)
		if socket_node == null:
			continue
		if not socket_node is Node2D:
			continue
		var socket_x := float(
			socket_data.get("x", 0.0)
		)
		var socket_y := float(
			socket_data.get("y", 0.0)
		)
		var socket_rz := float(
			socket_data.get("rz", 0.0)
		)
		var socket_sx := float(
			socket_data.get("sx", 1.0)
		)
		var socket_sy := float(
			socket_data.get("sy", 1.0)
		)
		var pivot: Vector2 = anim_frame_tags.get(
			"pivot",
			Vector2.ZERO
		)
		var crop_shift: Vector2 = anim_frame_tags.get(
			"cropShift",
			Vector2.ZERO
		)
		var local_x := socket_x - (
			pivot.x - crop_shift.x
		)
		var local_y := socket_y - (
			pivot.y - crop_shift.y
		)
		socket_node.position = Vector2(
			local_x,
			-local_y
		)
		socket_node.rotation = deg_to_rad(
			-socket_rz
		)
		socket_node.scale = Vector2(
			socket_sx,
			socket_sy
		)
		
func _apply_default_3dsocket_transform(
		animated_sprite: AnimatedSprite3D,
		initial_socket_data: Dictionary
	) -> void:
	if initial_socket_data.is_empty():
		return
	for socket_name in initial_socket_data.keys():
		var socket_info: Dictionary = initial_socket_data[
			socket_name
		]
		var json_meta: Dictionary = socket_info.get(
			"meta",
			{}
		)
		var animation_name: StringName = socket_info.get(
			"animation",
			""
		)
		var frame_data: Dictionary = socket_info.get(
			"frame_data",
			{}
		)
		var frame_tags: Dictionary = json_meta.get(
			"frameTags",
			{}
		)
		if not frame_tags.has(animation_name):
			continue
		var anim_frame_tags: Dictionary = frame_tags[
			animation_name
		]
		var frame_sockets: Dictionary = frame_data.get(
			"sockets",
			{}
		)
		if not frame_sockets.has(socket_name):
			continue
		var socket_data = frame_sockets[socket_name]
		if not socket_data is Dictionary:
			continue
		var socket_node := animated_sprite.get_node_or_null(
			"Socket/" + str(socket_name)
		)
		if socket_node == null:
			continue
		if not socket_node is Node3D:
			continue
		var socket_x := float(
			socket_data.get("x", 0.0)
		)
		var socket_y := float(
			socket_data.get("y", 0.0)
		)
		var socket_z := float(
			socket_data.get("z", 0.0)
		)
		var socket_rx := float(
			socket_data.get("rx", 0.0)
		)
		var socket_ry := float(
			socket_data.get("ry", 0.0)
		)
		var socket_rz := float(
			socket_data.get("rz", 0.0)
		)
		var socket_sx := float(
			socket_data.get("sx", 1.0)
		)
		var socket_sy := float(
			socket_data.get("sy", 1.0)
		)
		var socket_sz := float(
			socket_data.get("sz", 1.0)
		)
		var pivot: Vector2 = anim_frame_tags.get(
			"pivot",
			Vector2.ZERO
		)
		var crop_shift: Vector2 = anim_frame_tags.get(
			"cropShift",
			Vector2.ZERO
		)
		var local_x := socket_x - (
			pivot.x - crop_shift.x
		)
		var local_y := socket_y - (
			pivot.y - crop_shift.y
		)
		var pixel_size := animated_sprite.pixel_size
		socket_node.position = Vector3(
			local_x * pixel_size,
			local_y * pixel_size,
			-socket_z * pixel_size
		)
		socket_node.rotation = Vector3(
			0,
			deg_to_rad(socket_ry),
			deg_to_rad(socket_rz)
		)
		socket_node.scale = Vector3(
			socket_sx,
			socket_sy,
			socket_sz
		)
