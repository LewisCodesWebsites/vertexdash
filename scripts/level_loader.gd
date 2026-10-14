extends RefCounted
class_name VertexDashLevelLoader

static func parse_level_string(level_text: String) -> Array[Dictionary]:
	var objects: Array[Dictionary] = []
	for section in level_text.split(";"):
		if section.is_empty() or section.begins_with("kS38"):
			continue
		var pairs := section.split(",")
		if pairs.size() % 2 != 0:
			continue
		var fields := {}
		for index in range(0, pairs.size(), 2):
			fields[pairs[index]] = pairs[index + 1]
		if fields.has("1") and fields.has("2") and fields.has("3"):
			var object := {"id": int(fields["1"]), "x": float(fields["2"]), "y": float(fields["3"])} # LVL-03
			if fields.has("21"):
				object["color_channel"] = int(fields["21"]) # LVL-03
			objects.append(object)
	return objects

static func load_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": "Save file does not exist: %s" % path}
	var input := FileAccess.open(path, FileAccess.READ)
	if input == null:
		return {"error": "Cannot read save file: %s" % path}
	var encrypted := input.get_buffer(input.get_length())
	var encoded := PackedByteArray()
	encoded.resize(encrypted.size())
	for i in range(encrypted.size()):
		encoded[i] = encrypted[i] ^ 11 # LVL-02
	var text := encoded.get_string_from_ascii().replace("-", "+").replace("_", "/")
	while text.length() % 4 != 0:
		text += "="
	var compressed := Marshalls.base64_to_raw(text) # LVL-02
	var xml_bytes: PackedByteArray = compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP) # LVL-02
	if xml_bytes.is_empty():
		return {"error": "Save file could not be decoded (LVL-02)"}
	var parsed := _parse_save_xml(xml_bytes.get_string_from_utf8())
	if parsed.is_empty():
		return {"error": "Save file contains no readable levels"}
	return {"levels": parsed}

# LVL-02: nested plist elements use abbreviated names (d, k, s, i, r, t).
const PLIST_TAGS := {"d": "dict", "k": "key", "s": "string", "i": "integer", "r": "real", "t": "true"}

static func _tag(parser: XMLParser) -> String:
	var name := parser.get_node_name()
	return String(PLIST_TAGS.get(name, name))

static func _parse_save_xml(xml: String) -> Array[Dictionary]:
	var parser := XMLParser.new()
	if parser.open_buffer(xml.to_utf8_buffer()) != OK:
		return []
	var levels: Array[Dictionary] = []
	var stack: Array[Dictionary] = []
	var pending_key := ""
	var current := ""
	while parser.read() == OK:
		var node_type := parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT:
			var tag := _tag(parser)
			if tag == "dict":
				pending_key = ""
				current = ""
				if not parser.is_empty():
					stack.append({})
			elif parser.is_empty():
				# A value with no text, such as <t />, consumes the pending key.
				if tag != "key":
					pending_key = ""
				current = ""
			else:
				current = tag
		elif node_type == XMLParser.NODE_TEXT:
			if stack.is_empty() or current.is_empty():
				continue
			var data := parser.get_node_data()
			if current == "key":
				pending_key = data
			else:
				if current == "string" and not pending_key.is_empty():
					stack[stack.size() - 1][pending_key] = data
				pending_key = ""
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if _tag(parser) == "dict" and not stack.is_empty():
				var value: Dictionary = stack.pop_back()
				_collect_level(value, levels)
			current = ""
	return levels

static func _collect_level(value: Dictionary, levels: Array[Dictionary]) -> void:
	if not (value.has("k2") and value.has("k4")):
		return
	var encoded_level := String(value.k4).replace("-", "+").replace("_", "/")
	while encoded_level.length() % 4 != 0:
		encoded_level += "="
	var level_bytes := Marshalls.base64_to_raw(encoded_level) # LVL-02
	var level_data: PackedByteArray = level_bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP) # LVL-02
	if not level_data.is_empty():
		levels.append({"name": String(value.k2), "objects": parse_level_string(level_data.get_string_from_utf8())})
