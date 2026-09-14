extends AnimatedSprite2D

const TwoDFJsonParser = preload("res://addons/2DFactory/json_parser/2df_json_parser.gd")
const DirScanner = preload(
	"res://addons/2DFactory/utilities/2df_directory_scanner.gd"
)
var excluded_scan_dir: Array[String] = [".godot", "addons", "_reserved"]
var _json_data_valid := true
var json_data: Dictionary = {}
var _last_animation: StringName
var _last_frame: int = -1

#this _ready() function run once when game is loaded
func _ready():
	_load_json_data()
	if not _json_data_valid:
		return
	_last_animation = animation
	_last_frame = frame
	_apply_animation_data(animation)

# this _process() function executes continuously during game runtime
func _process(_delta):
	if not _json_data_valid:
		return
	if animation != _last_animation or frame != _last_frame:
		_last_animation = animation
		_last_frame = frame
		_apply_animation_data(animation)

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

func _load_json_data():
	var current_node: Node = self
	var scene_path := ""
	while current_node != null:
		if not current_node.scene_file_path.is_empty():
			scene_path = current_node.scene_file_path
			break
		current_node = current_node.get_parent()
	if scene_path.is_empty():
		print("ERROR: Could not determine current scene path.")
		return
	var scene_directory := scene_path.get_base_dir()
	print("Scanning JSON files from: ", scene_directory)
	var dir_scanner := DirScanner.new()
	var json_paths := dir_scanner.scan_json(
		scene_directory, excluded_scan_dir
	)
	if json_paths.is_empty():
		print("ERROR: No JSON files found.")
		return
	print("JSON files found: ", json_paths.size())
	var parser := TwoDFJsonParser.new()
	for json_path in json_paths:
		print("Loading JSON: ", json_path)
		if not parser.parse_json_file(json_path):
			print("WARNING: JSON parsing failed: ", json_path)
			continue
		var parsed_json: Dictionary = parser.json_meta
		# ---------------------------------------------------------
		# Validate 2D Factory JSON
		# ---------------------------------------------------------
		if not _is_valid_2df_json(parsed_json):
			print(
				"WARNING: JSON is not a valid 2D Factory JSON: ",
				json_path
			)
			continue
		# ---------------------------------------------------------
		# Collect animation data
		# ---------------------------------------------------------
		var frame_tags: Dictionary = parsed_json["frameTags"]
		for animation_name in frame_tags.keys():
			var animation_key := str(animation_name)
			var animation_data = frame_tags[animation_name]
			if not animation_data is Dictionary:
				continue
			if json_data.has(animation_key):
				print("")
				print("ERROR: Duplicate animation name found at runtime.")
				print("Animation: ", animation_key)
				print("JSON files:")
				print(
					"  - ",
					json_data[animation_key]["json_path"]
				)
				print(
					"  - ",
					json_path
				)
				_json_data_valid = false
				return
			json_data[animation_key] = {
				"data": animation_data,
				"json_path": json_path
			}
	print(
		"JSON successfully loaded. Animations found: ",
		json_data.size()
	)
	print(
		"JSON data valid: ",
		_json_data_valid)

func _apply_animation_data(animation_name: StringName):
	if json_data.is_empty():
		return
	if not json_data.has(animation_name):
		return
	var animation_entry: Dictionary = json_data[animation_name]
	var anim_frame_tags: Variant = animation_entry.get(
		"data",
		{}
	)
	if not anim_frame_tags is Dictionary:
		return
	_apply_pivot(anim_frame_tags)
	_apply_socket(anim_frame_tags, frame)

func _apply_pivot(anim_frame_tags: Dictionary):
	var pivot: Vector2 = anim_frame_tags.get(
		"pivot",
		Vector2.ZERO
	)
	centered = true
	offset = Vector2(
		-pivot.x,
		-pivot.y
	)

func _apply_socket(anim_frame_tags: Dictionary, frame_index: int):
	var anim_frames: Array = anim_frame_tags.get("frames", [])
	if anim_frames.is_empty():
		return
	var frame_count := anim_frames.size()
	var direction := str(
		anim_frame_tags.get("direction", "forward")
	).to_lower()
	var original_frame_index := frame_index
	match direction:
		"reverse":
			original_frame_index = frame_count - 1 - frame_index
		"pingpong":
			if frame_count > 1:
				var cycle_length := frame_count * 2 - 2
				var cycle_index := frame_index % cycle_length
				if cycle_index < frame_count:
					original_frame_index = cycle_index
				else:
					original_frame_index = cycle_length - cycle_index
			else:
				original_frame_index = 0
		"forward", _:
			original_frame_index = frame_index
	if original_frame_index < 0 or original_frame_index >= frame_count:
		return
	var frame_data: Dictionary = anim_frames[original_frame_index]
	var frame_sockets: Dictionary = frame_data.get("sockets", {})
	if frame_sockets.is_empty():
		return
	var pivot: Vector2 = anim_frame_tags.get("pivot", Vector2.ZERO)
	var crop_shift: Vector2 = anim_frame_tags.get("cropShift", Vector2.ZERO)
	# Socket Z settings
	var SocketOrderingModification: bool = ProjectSettings.get_setting(
		"2d_factory/animated_sprites/Socket_Ordering_Modification",
		true
	)
	var pixel_to_z_index_scale: float = ProjectSettings.get_setting(
		"2d_factory/animated_sprites/Pixel_per_Z_index_Threshold",
		0.1
	)
	var max_socket_z_index: int = ProjectSettings.get_setting(
		"2d_factory/animated_sprites/Maximum_Z_index_modification",
		5
	)
	for socket_name in frame_sockets.keys():
		var socket_data = frame_sockets[socket_name]
		if not socket_data is Dictionary:
			continue

		var socket_x := float(socket_data.get("x", 0.0))
		var socket_y := float(socket_data.get("y", 0.0))
		var socket_z := float(socket_data.get("z", 0.0))
		var socket_rz := float(socket_data.get("rz", 0.0))
		var socket_sx := float(socket_data.get("sx", 1.0))
		var socket_sy := float(socket_data.get("sy", 1.0))

		var local_x := socket_x - (pivot.x - crop_shift.x)
		var local_y := socket_y + (pivot.y - crop_shift.y)
		var socket_node := get_node_or_null(
			"Socket/" + str(socket_name)
		)
		if socket_node == null:
			continue
		if not socket_node is Node2D:
			continue
		socket_node.position = Vector2(local_x, -local_y)
		socket_node.rotation = deg_to_rad(-socket_rz)
		socket_node.scale = Vector2(socket_sx, socket_sy)

		# Convert Blender socket Z (pixels) to Godot z_index.
		if SocketOrderingModification:
			var socket_z_index := 0
			if not is_zero_approx(socket_z):
				socket_z_index = -sign(socket_z) * ceili(
					abs(socket_z) * pixel_to_z_index_scale
				)
			socket_z_index = clampi(
				socket_z_index,
				-max_socket_z_index,
				max_socket_z_index
			)
			socket_node.z_index = socket_z_index
