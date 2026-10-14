extends Node2D

var catalog
var camera: Camera2D
var tint := Color.WHITE

func configure(asset_catalog, active_camera: Camera2D, color: Color) -> void:
	catalog = asset_catalog
	camera = active_camera
	tint = color
	# COL-01/COL-02: the default ground-line channel is white with blending enabled.
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	queue_redraw()

func _draw() -> void:
	if catalog == null or not catalog.available:
		return
	var info: Dictionary = catalog.frame("game", "floorLine_001.png") # AST-05
	if info.is_empty():
		return
	var viewport_size := get_viewport_rect().size
	var zoom := viewport_size.y / 320.0 # CAM-01
	var view_width := viewport_size.x / zoom
	var camera_left := maxf(15.0, 0.0)
	if camera != null:
		camera_left = camera.position.x - view_width * 0.5
	var start := floorf(camera_left / 442.0) * 442.0
	for x in range(int(start), int(camera_left + view_width + 442.0), 442):
		draw_texture_rect_region(catalog.game_sheet, Rect2(Vector2(x, -91), Vector2(442, 2)), info.rect, tint) # COL-02
