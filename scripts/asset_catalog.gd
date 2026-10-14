extends RefCounted
class_name VertexDashAssetCatalog

# AST-01: load the low-resolution (one pixel per world unit) images consistently.
var background: Texture2D
var ground: Texture2D
var game_sheet: Texture2D
var icon_sheet: Texture2D
var primary_color := Color8(125, 255, 0) # COL-01, B-06 placeholder default.
var secondary_color := Color8(0, 255, 255) # COL-01, B-06 placeholder default.
var frames := {"game": {}, "icons": {}}
var music: AudioStream
var available := false

func load_from_resources(resources: String) -> bool:
	var background_image := _load_image(resources.path_join("game_bg_01_001.png")) # AST-06
	var ground_image := _load_image(resources.path_join("groundSquare_01_001.png")) # AST-05
	var game := _load_sheet(resources, "GJ_GameSheet") # AST-01, AST-03, AST-04, AST-05
	var icons := _load_sheet(resources.path_join("icons"), "player_01") # AST-02
	var song_path := resources.path_join("StereoMadness.mp3")
	if not background_image or not ground_image or game.get("texture") == null or icons.get("texture") == null or not FileAccess.file_exists(song_path):
		return false
	background = ImageTexture.create_from_image(background_image)
	ground = ImageTexture.create_from_image(ground_image)
	game_sheet = game.texture
	icon_sheet = icons.texture
	primary_color = Color(ProjectSettings.get_setting("vertexdash/player/primary", Color8(125, 255, 0))) # B-06: profile colors are not specified; configurable placeholder.
	secondary_color = Color(ProjectSettings.get_setting("vertexdash/player/secondary", Color8(0, 255, 255))) # B-06: profile colors are not specified; configurable placeholder.
	frames.game = game.frames
	frames.icons = icons.frames
	music = AudioStreamMP3.load_from_file(song_path) # MUS-01
	available = music != null
	return available

func frame(sheet: String, name: String) -> Dictionary:
	return frames.get(sheet, {}).get(name, {})

func _load_image(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return image

func _load_sheet(directory: String, name: String) -> Dictionary:
	var png_path := directory.path_join(name + ".png")
	var plist_path := directory.path_join(name + ".plist")
	var image := _load_image(png_path)
	if image == null or not FileAccess.file_exists(plist_path):
		return {}
	var parsed := _read_atlas(plist_path)
	if parsed.is_empty():
		return {}
	return {"texture": ImageTexture.create_from_image(image), "frames": parsed}

func _read_atlas(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := XMLParser.new()
	if parser.open_buffer(file.get_as_text().to_utf8_buffer()) != OK:
		return {}
	var stack: Array[Dictionary] = []
	var pending: Array[String] = []
	var current := ""
	var root: Dictionary = {}
	while parser.read() == OK:
		var node := parser.get_node_type()
		if node == XMLParser.NODE_ELEMENT:
			var tag := _tag(parser.get_node_name())
			if tag == "dict":
				current = ""
				if not parser.is_empty():
					stack.append({})
					pending.append("")
			elif tag == "key":
				current = "key"
			elif tag == "string" or tag == "integer" or tag == "real":
				current = "value"
			elif tag == "true" or tag == "false":
				if not stack.is_empty():
					stack[stack.size() - 1][pending[pending.size() - 1]] = tag == "true"
					pending[pending.size() - 1] = ""
				current = ""
			else:
				current = ""
		elif node == XMLParser.NODE_TEXT:
			if stack.is_empty():
				continue
			var data := parser.get_node_data()
			if current == "key":
				pending[pending.size() - 1] = data
			elif current == "value" and not pending[pending.size() - 1].is_empty():
				stack[stack.size() - 1][pending[pending.size() - 1]] = data
				pending[pending.size() - 1] = ""
			current = ""
		elif node == XMLParser.NODE_ELEMENT_END and _tag(parser.get_node_name()) == "dict":
			if not stack.is_empty():
				var child: Dictionary = stack.pop_back()
				pending.pop_back()
				if stack.is_empty():
					root = child
				else:
					var key := String(pending[pending.size() - 1])
					if not key.is_empty():
						stack[stack.size() - 1][key] = child
						pending[pending.size() - 1] = ""
			current = ""
	var frames_value: Variant = root.get("frames", {})
	if not frames_value is Dictionary:
		return {}
	var result := {}
	for sprite_name in frames_value:
		var item: Dictionary = frames_value[sprite_name]
		var rect_values := _numbers(str(item.get("textureRect", "")))
		if rect_values.size() != 4:
			continue
		result[String(sprite_name)] = {"rect": Rect2i(int(rect_values[0]), int(rect_values[1]), int(rect_values[2]), int(rect_values[3])), "rotated": str(item.get("textureRotated", false)).to_lower() == "true"} # AST-01
	return result

func _tag(name: String) -> String:
	match name:
		"d": return "dict"
		"k": return "key"
		"s": return "string"
		"i": return "integer"
		"r": return "real"
		"t": return "true"
		_: return name

func _numbers(text: String) -> Array[float]:
	var regex := RegEx.new()
	regex.compile("-?[0-9]+(?:\\.[0-9]+)?")
	var values: Array[float] = []
	for match_result in regex.search_all(text):
		values.append(float(match_result.get_string()))
	return values
