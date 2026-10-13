extends Node2D

const Simulation = preload("res://scripts/simulation.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
var simulation = Simulation.new()
var accumulator := 0.0
var jump_was_down := false
var scene_objects: Array[Dictionary] = []

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
	queue_redraw()

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
	while accumulator >= 1.0 / 240.0:
		var state: Dictionary = simulation.step()
		if state.dead:
			accumulator = 0.0
			break
		accumulator -= 1.0 / 240.0
	queue_redraw()

func _draw() -> void:
	# B-04 prototype framing: 30 world units = 60 px; player at one-third width.
	var scale_factor := 2.0
	var origin := Vector2(0, 500) # ground remains near the bottom of the 540 px viewport.
	draw_rect(Rect2(Vector2(0, origin.y), Vector2(960, 150)), Color("25293b"))
	for obj in scene_objects:
		var center := Vector2(320 + (float(obj.x) - simulation.x) * scale_factor, origin.y - float(obj.y) * scale_factor) # SIM-02, LVL-03 y is relative to ground
		if int(obj.id) == 1:
			draw_rect(Rect2(center - Vector2(30, 30), Vector2(60, 60)), Color("7c7fe8"))
		else:
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -24), center + Vector2(-15, 6), center + Vector2(15, 6)]), Color("f16d83"))
	var player_center := Vector2(320, origin.y - (simulation.y - 90.0) * scale_factor)
	# CUBE-07: rotation is visual only; Godot's positive rotation is clockwise on screen.
	draw_set_transform(player_center, deg_to_rad(simulation.angle), Vector2.ONE)
	draw_rect(Rect2(Vector2(-30, -30), Vector2(60, 60)), Color("f7d777"))
	draw_rect(Rect2(Vector2(-30, -30), Vector2(60, 60)), Color("8a6d1f"), false, 4.0)
	draw_rect(Rect2(Vector2(6, -22), Vector2(14, 14)), Color("8a6d1f"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(ThemeDB.fallback_font, Vector2(20, 28), "VertexDash | tick %d | x %.2f | y %.2f" % [simulation.tick, simulation.x, simulation.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if simulation.dead:
		draw_string(ThemeDB.fallback_font, Vector2(20, 52), "DEAD — restarting", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ff7777"))
