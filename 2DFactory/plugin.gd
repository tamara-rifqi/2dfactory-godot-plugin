@tool
extends EditorPlugin

const FileSystemContextMenu = preload("res://addons/2DFactory/context_menu/2df_filesystem_context_menu.gd")
var filesystem_context_menu

func _enter_tree():
	_register_project_settings()
	filesystem_context_menu = FileSystemContextMenu.new()
	add_context_menu_plugin(
		EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM,
		filesystem_context_menu
	)

func _exit_tree():
	remove_context_menu_plugin(
		filesystem_context_menu
	)
	filesystem_context_menu = null
	
func _register_project_settings():
	# =========================================================
	# GENERAL
	# =========================================================
	var sprite_creation_menu := (
		"2d_factory/general/sprite_creation_menu"
	)
	if not ProjectSettings.has_setting(sprite_creation_menu):
		ProjectSettings.set_setting(
			sprite_creation_menu,
			2
		)
	ProjectSettings.set_initial_value(
		sprite_creation_menu,
		2
	)
	ProjectSettings.set_as_basic(
		sprite_creation_menu,
		true
	)
	ProjectSettings.add_property_info({
		"name": sprite_creation_menu,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "2D,3D,2D and 3D",
		"description": (
			"Determines which sprite workflow is available from the 2D Factory 
			FileSystem context menu. Choose 2D, 3D, or Both."
		)
	})
	var max_scan_depth_name := (
		"2d_factory/general/max_recursive_scan_depth"
	)
	if not ProjectSettings.has_setting(max_scan_depth_name):
		ProjectSettings.set_setting(
			max_scan_depth_name,
			5
		)
	ProjectSettings.set_initial_value(
		max_scan_depth_name,
		5
	)
	ProjectSettings.set_as_basic(
		max_scan_depth_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": max_scan_depth_name,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,100,1",
		"description": (
			"Limit recursive directory scan (e.g. json files search) level (e.g. 1 level means 1 subfolder below)" 
		)
	})
	var apply_texture_settings_name := (
		"2d_factory/sprite_sheet_import/apply_texture_settings"
	)
	if not ProjectSettings.has_setting(apply_texture_settings_name):
		ProjectSettings.set_setting(
			apply_texture_settings_name,
			true
		)
	ProjectSettings.set_initial_value(
		apply_texture_settings_name,
		true
	)
	ProjectSettings.set_as_basic(
		apply_texture_settings_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": apply_texture_settings_name,
		"type": TYPE_BOOL,
		"description": (
			"Apply the texture settings to all imported sheets, such as predefined Compression Mode, 
			and disable both Detect 3D and Roughness Mode."
		)
	})
	
	var main_compression_name := (
		"2d_factory/sprite_sheet_import/main_compression"
	)
	if not ProjectSettings.has_setting(main_compression_name):
		ProjectSettings.set_setting(
			main_compression_name,
			0
		)
	ProjectSettings.set_initial_value(
		main_compression_name,
		0
	)
	ProjectSettings.set_as_basic(
		main_compression_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": main_compression_name,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": (
			"Lossless,Lossy,VRAM Compressed,"
			+ "VRAM Uncompressed,Basis Universal"
		),
		"description": (
			"Sets the texture compression mode applied to the main sprite sheet 
			when 2D Factory imports or updates the sprite sheet."
		)
	})
	#normal
	var normal_compression_name := (
		"2d_factory/sprite_sheet_import/normal_map_compression"
	)
	if not ProjectSettings.has_setting(normal_compression_name):
		ProjectSettings.set_setting(
			normal_compression_name,
			0
		)
	ProjectSettings.set_initial_value(
		normal_compression_name,
		0
	)
	ProjectSettings.set_as_basic(
		normal_compression_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": normal_compression_name,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": (
			"Lossless,Lossy,VRAM Compressed,"
			+ "VRAM Uncompressed,Basis Universal"
		),
		"description": (
			"Sets the texture compression mode applied to the optional _N 
			normal map associated with the sprite sheet."
		)
	})
	#roughness
	var roughness_compression_name := (
	"2d_factory/sprite_sheet_import/roughness_map_compression"
	)
	if not ProjectSettings.has_setting(roughness_compression_name):
		ProjectSettings.set_setting(
			roughness_compression_name,
			0
		)
	ProjectSettings.set_initial_value(
		roughness_compression_name,
		0
	)
	ProjectSettings.set_as_basic(
		roughness_compression_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": roughness_compression_name,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": (
			"Lossless,Lossy,VRAM Compressed,"
			+ "VRAM Uncompressed,Basis Universal"
		),
		"description": (
			"Sets the texture compression mode applied to the optional _R 
			roughness map associated with the sprite sheet."
		)
	})
	#ao
	var ao_compression_name := (
	"2d_factory/sprite_sheet_import/ao_map_compression"
	)
	if not ProjectSettings.has_setting(ao_compression_name):
		ProjectSettings.set_setting(
			ao_compression_name,
			0
		)
	ProjectSettings.set_initial_value(
		ao_compression_name,
		0
	)
	ProjectSettings.set_as_basic(
		ao_compression_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": ao_compression_name,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": (
			"Lossless,Lossy,VRAM Compressed,"
			+ "VRAM Uncompressed,Basis Universal"
		),
		"description": (
			"Sets the texture compression mode applied to the optional _N 
			AO map associated with the sprite sheet."
		)
	})
	#emission
	var emission_compression_name := (
	"2d_factory/sprite_sheet_import/emission_map_compression"
	)
	if not ProjectSettings.has_setting(emission_compression_name):
		ProjectSettings.set_setting(
			emission_compression_name,
			0
		)
	ProjectSettings.set_initial_value(
		emission_compression_name,
		0
	)
	ProjectSettings.set_as_basic(
		emission_compression_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": emission_compression_name,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": (
			"Lossless,Lossy,VRAM Compressed,"
			+ "VRAM Uncompressed,Basis Universal"
		),
		"description": (
			"Sets the texture compression mode applied to the optional _N 
			emission map associated with the sprite sheet."
		)
	})
	
	
	var texture_filter_2d_name := (
		"2d_factory/animated_sprites/texture_filter_2d"
	)
	if not ProjectSettings.has_setting(texture_filter_2d_name):
		ProjectSettings.set_setting(
			texture_filter_2d_name,
			CanvasItem.TEXTURE_FILTER_NEAREST
		)
	ProjectSettings.set_initial_value(
		texture_filter_2d_name,
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	ProjectSettings.set_as_basic(
		texture_filter_2d_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": texture_filter_2d_name,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": (
			"Inherit,Nearest,Linear,"
			+ "Nearest Mipmap,Linear Mipmap"
		),
		"description": (
			"Sets the default texture filtering mode for generated AnimatedSprite2D nodes."
		)
	})
	var texture_filter_3d_name := (
		"2d_factory/animated_sprites/texture_filter_3d"
	)
	if not ProjectSettings.has_setting(texture_filter_3d_name):
		ProjectSettings.set_setting(
			texture_filter_3d_name,
			BaseMaterial3D.TEXTURE_FILTER_NEAREST
		)
	ProjectSettings.set_initial_value(
		texture_filter_3d_name,
		BaseMaterial3D.TEXTURE_FILTER_NEAREST
	)
	ProjectSettings.set_as_basic(
		texture_filter_3d_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": texture_filter_3d_name,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": (
			"Nearest,Linear,"
			+ "Nearest Mipmap,Linear Mipmap"
		),
		"description": (
			"Sets the default texture filtering mode for generated AnimatedSprite3D nodes."
		)
	})
	var separate_sheet_output_name := (
		"2d_factory/animated_sprites/separate_sheet_output_name"
	)
	if not ProjectSettings.has_setting(separate_sheet_output_name):
		ProjectSettings.set_setting(
			separate_sheet_output_name,
			"{FOLDER}"
		)
	ProjectSettings.set_initial_value(
		separate_sheet_output_name,
		"{FOLDER}"
	)
	ProjectSettings.set_as_basic(
		separate_sheet_output_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": separate_sheet_output_name,
		"type": TYPE_STRING,
		"description": (
			"Sets the output name for the Separate Sheet 
			workflow. Use {FOLDER} to insert the name of 
			the selected folder. If left empty, 
			{FOLDER}_combined is used."
		)
	})
	
	# ---------------------------------------------------------
	# Socket Reticle
	# ---------------------------------------------------------
	var socket_reticle_name := (
		"2d_factory/animated_sprites/create_socket_reticle"
	)
	if not ProjectSettings.has_setting(socket_reticle_name):
		ProjectSettings.set_setting(
			socket_reticle_name,
			true
		)
	ProjectSettings.set_initial_value(
		socket_reticle_name,
		true
	)
	ProjectSettings.set_as_basic(
		socket_reticle_name,
		true
	)
	ProjectSettings.add_property_info({
		"name": socket_reticle_name,
		"type": TYPE_BOOL,
		"description": (
			"When enabled, creates a visible reticle under each generated socket node 
			to make socket positions easier to identify and edit in the Godot editor."
		)
	})
	# ---------------------------------------------------------
	# Modify AnimatedSprite2D Ordering Settings
	# ---------------------------------------------------------
	var SocketOrderingModification := (
		"2d_factory/animated_sprites/Socket_Ordering_Modification"
	)
	if not ProjectSettings.has_setting(SocketOrderingModification):
		ProjectSettings.set_setting(
			SocketOrderingModification,
			true
		)
	ProjectSettings.set_initial_value(
		SocketOrderingModification,
		true
	)
	ProjectSettings.set_as_basic(
		SocketOrderingModification,
		true
	)
	ProjectSettings.add_property_info({
		"name": SocketOrderingModification,
		"type": TYPE_BOOL,
		"description": (
			"When enabled, modify AnimatedSprite2D socket ordering using 
			socket z translation data exported in the JSON."
		)
	})
	var PixelPerZindexThreshold := (
		"2d_factory/animated_sprites/Pixel_per_Z_index_Threshold"
	)
	if not ProjectSettings.has_setting(PixelPerZindexThreshold):
		ProjectSettings.set_setting(
			PixelPerZindexThreshold,
			0.1
		)
	ProjectSettings.set_initial_value(
		PixelPerZindexThreshold,
		0.1
	)
	ProjectSettings.set_as_basic(
		PixelPerZindexThreshold,
		true
	)
	ProjectSettings.add_property_info({
		"name": PixelPerZindexThreshold,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.001,100,0.001",
		"description": (
			"Set the number of socket z-translation pixels represented by one 
			Z-index level. Any non-zero z translation produces at least a 
			one-level Z-index modification."
		)
	})
	var MaxZindexModification := (
		"2d_factory/animated_sprites/Maximum_Z_index_modification"
	)
	if not ProjectSettings.has_setting(MaxZindexModification):
		ProjectSettings.set_setting(
			MaxZindexModification,
			5
		)
	ProjectSettings.set_initial_value(
		MaxZindexModification,
		5
	)
	ProjectSettings.set_as_basic(
		MaxZindexModification,
		true
	)
	ProjectSettings.add_property_info({
		"name": MaxZindexModification,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,100,1",
		"description": (
			"Limit the maximum positive or negative Z-index modification 
			applied to a socket."
		)
	})
