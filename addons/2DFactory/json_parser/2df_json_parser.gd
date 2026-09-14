extends RefCounted

var json_meta: Dictionary = {
	"image": "",
	"size": Vector2i.ZERO,
	"scale": 1.0,
	"frameTags": {},
	"frames": {}
}

func parse_json_file(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("ERROR: Could not open JSON file: ", file_path)
		return false
	var json_text = file.get_as_text()
	file.close()
	var json_data = JSON.parse_string(json_text)
	if json_data == null:
		print("ERROR: Could not parse JSON.")
		return false
	if not json_data is Dictionary:
		print("ERROR: JSON root is not a Dictionary.")
		return false
	return parse_json_metadata(json_data)

func parse_json_metadata(json_data: Dictionary) -> bool:
	json_meta["image"] = ""
	json_meta["size"] = Vector2i.ZERO
	json_meta["scale"] = 1.0
	json_meta["frameTags"].clear()
	json_meta["frames"].clear()

	var meta = json_data.get("meta", {})
	if not meta is Dictionary:
		print("ERROR: 'meta' is not an object.")
		return false

	json_meta["image"] = str(meta.get("image", ""))
	if meta.has("size") and meta["size"] is Dictionary:
		var size: Dictionary = meta["size"]

		json_meta["size"] = Vector2i(
			int(size.get("w", 0)),
			int(size.get("h", 0))
		)
	json_meta["scale"] = float(meta.get("scale", 1.0))

	if meta.has("frameTags") and meta["frameTags"] is Array:
		for tag in meta["frameTags"]:
			if not tag is Dictionary:
				continue
			var tag_name := str(tag.get("name", ""))
			if tag_name.is_empty():
				continue
			var tag_data: Dictionary = {
				"from": int(tag.get("from", 0)),
				"to": int(tag.get("to", 0)),
				"direction": str(
					tag.get("direction", "forward")
				),
				"loop": str(
					tag.get("loop", "false")
				),
				"cropShift": Vector2.ZERO,
				"pivot": Vector2.ZERO,
				"frames": []
			}
			if tag.has("cropShift") and tag["cropShift"] is Dictionary:
				var crop_shift: Dictionary = tag["cropShift"]

				tag_data["cropShift"] = Vector2(
					float(crop_shift.get("x", 0.0)),
					float(crop_shift.get("y", 0.0))
				)
			else:
				tag_data["cropShift"] = Vector2.ZERO
			if tag.has("pivot") and tag["pivot"] is Dictionary:
				var pivot: Dictionary = tag["pivot"]

				tag_data["pivot"] = Vector2(
					float(pivot.get("x", 0.0)),
					float(pivot.get("y", 0.0))
				)
			else:
				tag_data["pivot"] = Vector2.ZERO
				
			json_meta["frameTags"][tag_name] = tag_data

	# ---------------------------------------------------------
	# FRAMES
	# ---------------------------------------------------------
	if not parse_json_frames(json_data):
		return false
	print("Metadata parsed successfully.")
	return true

func parse_json_frames(json_data: Dictionary) -> bool:
	var all_frames = json_data.get("frames", {})
	if not all_frames is Dictionary:
		print("ERROR: 'frames' is not an object.")
		return false

	for tag_name in json_meta["frameTags"].keys():
		var tag_data: Dictionary = json_meta["frameTags"][tag_name]
		var parsed_frames: Array = []

		for frame_name in all_frames.keys():
			var frame_name_string := str(frame_name)
			if not frame_name_string.contains(str(tag_name)):
				continue
			var frame_data = all_frames[frame_name]
			if not frame_data is Dictionary:
				continue
			var parsed_frame = parse_single_frame(
				frame_name_string,
				frame_data
			)
			if parsed_frame == null:
				continue
			parsed_frames.append(parsed_frame)

		tag_data["frames"] = parsed_frames
		json_meta["frameTags"][tag_name] = tag_data

	print("Frames parsed successfully.")
	return true

func parse_single_frame(frame_name: String,	frame_data: Dictionary) -> Dictionary:
	var parsed_frame = {
		"name": frame_name,
		"frame": {
			"x": 0,
			"y": 0,
			"w": 0,
			"h": 0
		},
		"sprite_source_size": {
			"x": 0,
			"y": 0,
			"w": 0,
			"h": 0
		},
		"source_size": Vector2i.ZERO,
		"duration": 0,
		"rotated": false,
		"trimmed": false,
		"sockets": {}
	}

	if frame_data.has("frame") and frame_data["frame"] is Dictionary:
		var rect = frame_data["frame"]
		parsed_frame["frame"]["x"] = int(rect.get("x", 0))
		parsed_frame["frame"]["y"] = int(rect.get("y", 0))
		parsed_frame["frame"]["w"] = int(rect.get("w", 0))
		parsed_frame["frame"]["h"] = int(rect.get("h", 0))

	if frame_data.has("spriteSourceSize") and frame_data["spriteSourceSize"] is Dictionary:
		var source_rect = frame_data["spriteSourceSize"]
		parsed_frame["sprite_source_size"]["x"] = int(
			source_rect.get("x", 0)
		)
		parsed_frame["sprite_source_size"]["y"] = int(
			source_rect.get("y", 0)
		)
		parsed_frame["sprite_source_size"]["w"] = int(
			source_rect.get("w", 0)
		)
		parsed_frame["sprite_source_size"]["h"] = int(
			source_rect.get("h", 0)
		)

	if frame_data.has("sourceSize") and frame_data["sourceSize"] is Dictionary:
		var source_size = frame_data["sourceSize"]

		parsed_frame["source_size"] = Vector2i(
			int(source_size.get("w", 0)),
			int(source_size.get("h", 0))
		)

	parsed_frame["duration"] = int(
		frame_data.get("duration", 0)
	)

	parsed_frame["rotated"] = bool(
		frame_data.get("rotated", false)
	)

	parsed_frame["trimmed"] = bool(
		frame_data.get("trimmed", false)
	)

	if frame_data.has("sockets") and frame_data["sockets"] is Dictionary:
		var sockets = frame_data["sockets"]
		for socket_name in sockets:
			var socket_data = sockets[socket_name]
			if not socket_data is Dictionary:
				continue
			var socket_transform = {
				"x": float(socket_data.get("x", 0.0)),
				"y": float(socket_data.get("y", 0.0)),
				"z": float(socket_data.get("z", 0.0)),

				"rx": float(socket_data.get("rx", 0.0)),
				"ry": float(socket_data.get("ry", 0.0)),
				"rz": float(socket_data.get("rz", 0.0)),

				"sx": float(socket_data.get("sx", 1.0)),
				"sy": float(socket_data.get("sy", 1.0)),
				"sz": float(socket_data.get("sz", 1.0))
			}
			parsed_frame["sockets"][socket_name] = socket_transform
	return parsed_frame
