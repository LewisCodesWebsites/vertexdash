extends Node2D

const Simulation = preload("res://scripts/simulation.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
const AssetCatalog = preload("res://scripts/asset_catalog.gd")
const GroundLine = preload("res://scripts/ground_line.gd")
const TICK_LENGTH := 1.0 / 240.0 # SIM-01
var simulation = Simulation.new()
var accumulator := 0.0
var previous_position := Vector2.ZERO
var current_position := Vector2.ZERO
var previous_rotation := 0.0
var current_rotation := 0.0
var jump_was_down := false
var scene_objects: Array[Dictionary] = []
var assets = AssetCatalog.new()
var camera: Camera2D
var ground_line: Node2D
var music_player: AudioStreamPlayer
const BACKGROUND_PARALLAX := 0.1 # B-07: placeholder pending measurement.
const MUSIC_OFFSET_SECONDS := 0.0 # B-08: placeholder pending measurement.
var bg_color := Color8(40, 125, 255) # COL-01
var ground_color := Color8(0, 102, 255) # COL-01
var line_color := Color.WHITE # COL-01
var object_color := Color.WHITE # COL-01

func _ready() -> void:
	# B-05: Space is the default jump control; mouse-left is also accepted.
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
		var space := InputEventKey.new()
		space.physical_keycode = KEY_SPACE
		InputMap.action_add_event("jump", space)
	var selection := _load_selected_level()
	if selection.has("list"):
		get_tree().quit(0)
		return
	if selection.has("error"):
		push_error(String(selection.error))
		get_tree().quit(1)
		return
	scene_objects = selection.objects
	simulation.reset(scene_objects)
	_snap_render_state()
	_load_install_assets()
	_setup_camera()
	if assets.available:
		music_player = AudioStreamPlayer.new()
		music_player.stream = assets.music
		add_child(music_player)
		_start_attempt_music() # MUS-01, B-08
	queue_redraw()

func _load_install_assets() -> void:
	var install := String(ProjectSettings.get_setting("vertexdash/assets/install_path", ""))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gd-install="):
			install = arg.trim_prefix("--gd-install=")
	if install.is_empty():
		var program_files := OS.get_environment("ProgramFiles(x86)")
		if program_files.is_empty():
			program_files = "C:/Program Files (x86)"
		install = program_files.path_join("Steam/steamapps/common/Geometry Dash")
	var resources := install if install.get_file().to_lower() == "resources" else install.path_join("Resources")
	if not assets.load_from_resources(resources):
		print("Geometry Dash Resources not found or incomplete; using code-drawn fallback shapes.")
	else:
		print("Loaded Geometry Dash presentation assets from: %s" % resources)

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "LevelCamera"
	camera.enabled = true
	add_child(camera)
	ground_line = GroundLine.new()
	ground_line.name = "GroundLine"
	ground_line.z_index = 2
	add_child(ground_line)
	ground_line.configure(assets, camera, line_color)
	_update_camera()

func _update_camera() -> void:
	if camera == null:
		return
	var viewport_size := get_viewport_rect().size
	var zoom := viewport_size.y / 320.0 # CAM-01: 320 world units tall at every window shape.
	var view_width := viewport_size.x / zoom
	var camera_left := maxf(15.0, _interpolated_position().x - 209.4) # CAM-01: fixed until player reaches follow threshold.
	camera.zoom = Vector2(zoom, zoom)
	camera.position = Vector2(camera_left + view_width * 0.5, -160.0) # CAM-01: world bottom y=0, fixed vertical.
	if ground_line != null:
		ground_line.queue_redraw()

func _load_selected_level() -> Dictionary:
	var args := OS.get_cmdline_user_args()
	var requested_level := ""
	var save_path := OS.get_environment("LOCALAPPDATA").path_join("GeometryDash").path_join("CCLocalLevels.dat") # LVL-01
	for arg in args:
		if arg.begins_with("--gd-save="):
			save_path = arg.trim_prefix("--gd-save=")
		elif arg.begins_with("--level="):
			requested_level = arg.trim_prefix("--level=")
	var result: Dictionary = LevelLoader.load_save(save_path) # LVL-01, LVL-02
	if result.has("error"):
		return result
	var levels: Array = result.levels
	if requested_level.is_empty():
		var names: PackedStringArray = []
		for level in levels:
			names.append(String(level.name).strip_edges()) # B-02 selection rule
		print("Available levels: %s" % ", ".join(names))
		return {"list": true}
	for level in levels:
		if String(level.name).strip_edges().to_lower() == requested_level.strip_edges().to_lower():
			return {"objects": level.objects}
	return {"error": "No level named '%s' in %s" % [requested_level, save_path]}

func _process(delta: float) -> void:
	accumulator += delta
	var jump_down := Input.is_action_pressed("jump") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var pressed := jump_down and not jump_was_down
	jump_was_down = jump_down
	simulation.set_jump(jump_down, pressed)
	while accumulator >= TICK_LENGTH:
		previous_position = current_position
		previous_rotation = current_rotation
		var state: Dictionary = simulation.step()
		if state.event == "restart":
			_snap_render_state() # OBJ-03: do not interpolate between attempts.
		else:
			current_position = Vector2(float(state.x), float(state.y))
			current_rotation = float(state.angle) # CUBE-07
		if state.dead:
			accumulator = 0.0
			music_player.stop() if music_player != null else null # B-08: new attempt begins on next simulation step.
			break
		accumulator -= TICK_LENGTH
		if state.event == "restart":
			_start_attempt_music() # MUS-01, B-08: restart from the beginning on every attempt.
	_update_camera()
	queue_redraw()

func _draw() -> void:
	var view_width := get_viewport_rect().size.x / (get_viewport_rect().size.y / 320.0)
	var camera_left := maxf(15.0, _interpolated_position().x - 209.4) # CAM-01
	if assets.available:
		_draw_background(camera_left, view_width) # AST-06, COL-02
		_draw_ground(camera_left, view_width) # AST-05, COL-02
	else:
		_draw_fallback_environment(camera_left, view_width)
	for obj in scene_objects:
		var center := Vector2(float(obj.x), -(float(obj.y) + 90.0)) # SIM-02, LVL-03
		var custom_channel := int(obj.get("color_channel", 1004)) != 1004 # COL-02, LVL-03
		if assets.available and not custom_channel:
			var sprite_name := "square_01_001.png" if int(obj.id) == 1 else "spike_01_001.png"
			var sprite_frame := assets.frame("game", sprite_name) # AST-03, AST-04
			if not sprite_frame.is_empty():
				draw_texture_rect_region(assets.game_sheet, Rect2(center - Vector2(15, 15), Vector2(30, 30)), sprite_frame.rect, object_color) # COL-02 channel 1004
			else:
				_draw_fallback_object(int(obj.id), center)
		else:
			_draw_fallback_object(int(obj.id), center)
	var render_position := _interpolated_position()
	var render_rotation := _interpolated_rotation()
	var player_center := Vector2(render_position.x, -render_position.y) # SIM-02
	var main_frame := assets.frame("icons", "player_01_001.png") # AST-02
	var secondary_frame := assets.frame("icons", "player_01_2_001.png") # AST-02
	if assets.available and not main_frame.is_empty() and not secondary_frame.is_empty():
		draw_set_transform(player_center, -deg_to_rad(render_rotation), Vector2.ONE) # CUBE-07
		_draw_icon_frame(main_frame, Rect2(Vector2(-15, -15), Vector2(30, 30)), assets.primary_color)
		var detail_size := Vector2(secondary_frame.rect.size) # AST-01/AST-02: low-res sheet is 1 px per world unit; draw at native size, centred.
		_draw_icon_frame(secondary_frame, Rect2(-detail_size / 2.0, detail_size), assets.secondary_color)
	else:
		# B-06: code-drawn cube remains the fallback when the runtime icon asset is absent.
		draw_set_transform(player_center, -deg_to_rad(render_rotation), Vector2.ONE) # CUBE-07
		draw_rect(Rect2(Vector2(-15, -15), Vector2(30, 30)), Color("f7d777"))
		draw_rect(Rect2(Vector2(-15, -15), Vector2(30, 30)), Color("8a6d1f"), false, 1.5)
		draw_rect(Rect2(Vector2(3, -11), Vector2(7, 7)), Color("8a6d1f"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _snap_render_state() -> void:
	previous_position = Vector2(simulation.x, simulation.y)
	current_position = previous_position
	previous_rotation = simulation.angle
	current_rotation = previous_rotation

func _render_alpha() -> float:
	return clampf(accumulator / TICK_LENGTH, 0.0, 1.0)

func _interpolated_position() -> Vector2:
	return previous_position.lerp(current_position, _render_alpha())

func _interpolated_rotation() -> float:
	# CUBE-07: interpolate through 360° wrap along the shortest angular distance.
	var delta := fposmod(current_rotation - previous_rotation + 180.0, 360.0) - 180.0
	return previous_rotation + delta * _render_alpha()

func _draw_background(camera_left: float, view_width: float) -> void:
	# AST-06, B-07: 512-unit tiles scroll at a placeholder fraction of camera motion; fixed vertically.
	var scroll_x := camera_left * (1.0 - BACKGROUND_PARALLAX)
	var start_x := floorf(scroll_x / 512.0) * 512.0
	for x in range(int(start_x), int(scroll_x + view_width + 512.0), 512):
		draw_texture_rect(assets.background, Rect2(Vector2(x - scroll_x + camera_left, -512), Vector2(512, 512)), false, bg_color)

func _draw_icon_frame(frame: Dictionary, destination: Rect2, tint: Color) -> void:
	# AST-01: atlas rectangles are top-left-origin; restore clockwise-stored frames before drawing.
	var source: Rect2i = frame.rect
	if not bool(frame.rotated):
		draw_texture_rect_region(assets.icon_sheet, destination, source, tint)
		return
	var image: Image = assets.icon_sheet.get_image()
	var cropped: Image = image.get_region(source)
	cropped.rotate_90(CLOCKWISE)
	var texture := ImageTexture.create_from_image(cropped)
	draw_texture_rect(texture, destination, false, tint)

func _start_attempt_music() -> void:
	if music_player == null:
		return
	music_player.stop()
	music_player.play(MUSIC_OFFSET_SECONDS) # MUS-01, B-08

func _draw_ground(camera_left: float, view_width: float) -> void:
	# AST-05: tile top meets world y=90 and continues 128 units downward.
	var start_x := floorf(camera_left / 128.0) * 128.0
	for x in range(int(start_x), int(camera_left + view_width + 128.0), 128):
		draw_texture_rect(assets.ground, Rect2(Vector2(x, -90), Vector2(128, 128)), false, ground_color)

func _draw_fallback_environment(camera_left: float, view_width: float) -> void:
	draw_rect(Rect2(Vector2(camera_left, -320), Vector2(view_width, 410)), Color("25293b"))
	draw_rect(Rect2(Vector2(camera_left, -90), Vector2(view_width, 128)), Color("294c83"))
	draw_line(Vector2(camera_left, -90), Vector2(camera_left + view_width, -90), Color("7bb7ff"), 1.0)

func _draw_fallback_object(object_id: int, center: Vector2) -> void:
	if object_id == 1:
		draw_rect(Rect2(center - Vector2(15, 15), Vector2(30, 30)), Color("7c7fe8"))
	else:
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -15), center + Vector2(-15, 15), center + Vector2(15, 15)]), Color("f16d83"))
