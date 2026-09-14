extends EditorContextMenuPlugin

const WorkflowMode = preload("res://addons/2DFactory/animated_sprites/2df_workflow_mode.gd")

var scan_path: String = ""
var sprite_type: String = ""

func _popup_menu(paths: PackedStringArray):
	if paths.size() != 1:
		return
	var path := paths[0]
	if not DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path(path)
	):
		return
	scan_path = path
	var workflow_mode := ProjectSettings.get_setting(
		"2d_factory/general/sprite_creation_menu",
		0
	)
	var icon2d := load(
		"res://addons/2DFactory/resources/2df_icon2d.png"
	)
	var icon3d := load(
		"res://addons/2DFactory/resources/2df_icon3d.png"
	)
	var singleSheetIcon := load(
		"res://addons/2DFactory/resources/2df_singlesheet_icon.png"
	)
	var separateSheetIcon := load(
		"res://addons/2DFactory/resources/2df_separatesheet_icon.png"
	)
	# ---------------------------------------------------------
	# 2D SPRITES
	# ---------------------------------------------------------
	if workflow_mode == 0 or workflow_mode == 2:
		var submenu_2d := PopupMenu.new()
		submenu_2d.add_icon_item(singleSheetIcon, "Single Sheet Mode")
		submenu_2d.add_icon_item(separateSheetIcon, "Separate Sheet Mode")
		submenu_2d.id_pressed.connect(
			_on_2d_submenu_pressed
		)
		add_context_submenu_item(
			"Create 2D Sprites",
			submenu_2d,
			icon2d
		)
	# ---------------------------------------------------------
	# 3D SPRITES
	# ---------------------------------------------------------
	if workflow_mode == 1 or workflow_mode == 2:
		var submenu_3d := PopupMenu.new()
		submenu_3d.add_icon_item(singleSheetIcon, "Single Sheet Mode")
		submenu_3d.add_icon_item(separateSheetIcon, "Separate Sheet Mode")
		submenu_3d.id_pressed.connect(
			_on_3d_submenu_pressed
		)
		add_context_submenu_item(
			"Create 3D Sprites",
			submenu_3d,
			icon3d
		)

func _on_2d_submenu_pressed(id: int):
	sprite_type = "2D"
	var workflow_mode := WorkflowMode.new()
	match id:
		0:
			workflow_mode.single_sheet_workflow(scan_path, sprite_type)
		1:
			workflow_mode.separate_sheet_workflow(scan_path, sprite_type)

func _on_3d_submenu_pressed(id: int):
	sprite_type = "3D"
	var workflow_mode := WorkflowMode.new()
	match id:
		0:
			workflow_mode.single_sheet_workflow(scan_path, sprite_type)
		1:
			workflow_mode.separate_sheet_workflow(scan_path, sprite_type)
