extends SceneTree

const Simulation = preload("res://scripts/simulation.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
const CASES := [
	{"recording": "res://tests/recordings/tc01_vdjump_single_jump.csv", "level": "res://tests/levels/tc01_vdjump.level", "tap_after": 8},
	{"recording": "res://tests/recordings/tc02_vdblock_jump_onto_block.csv", "level": "res://tests/levels/tc02_vdblock.level", "tap_after": 200},
	{"recording": "res://tests/recordings/tc03_vdspike_death.csv", "level": "res://tests/levels/tc03_vdspike.level", "tap_after": -1},
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	for test_case in CASES:
		var case_failures := _run_case(test_case)
		failures.append_array(case_failures)
		if case_failures.is_empty():
			print("PASS %s" % test_case.recording.get_file())
	if failures.is_empty():
		print("PASS: every recording row and event matched")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _load_level(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	return LevelLoader.parse_level_string(file.get_as_text())

func _run_case(test_case: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var recording := FileAccess.open(test_case.recording, FileAccess.READ)
	if recording == null:
		return ["Cannot open recording %s" % test_case.recording]
	var lines := recording.get_as_text().strip_edges().split("\n")
	var rows: Array[Dictionary] = []
	for i in range(1, lines.size()):
		var columns := lines[i].strip_edges().split(",", true)
		if columns.size() >= 6:
			rows.append({"tick": int(columns[0]), "t_ms": float(columns[1]), "x": float(columns[2]), "y": float(columns[3]), "dead": columns[4] == "true", "event": columns[5]})
	if rows.is_empty():
		return ["No rows in recording %s" % test_case.recording]
	var objects := _load_level(test_case.level)
	if objects.is_empty():
		return ["Fixture %s has no objects" % test_case.level]
	var sim = Simulation.new()
	sim.reset(objects)
	var row_index := 0
	var last_tick: int = rows.back().tick
	if int(rows[0].tick) == 0:
		_check_row(test_case.recording, rows[0], sim.state(), errors)
		row_index = 1
	for tick in range(1, last_tick + 1):
		var state: Dictionary = sim.step()
		while row_index < rows.size() and int(rows[row_index].tick) == tick:
			_check_row(test_case.recording, rows[row_index], state, errors)
			_check_event(test_case.recording, rows[row_index], state, sim, errors)
			row_index += 1
		if tick == int(test_case.tap_after):
			sim.set_jump(false, true) # TC-01 / TC-02: tap between this tick and the next.
	return errors

func _check_row(path: String, row: Dictionary, state: Dictionary, errors: Array[String]) -> void:
	var label := "%s tick %d" % [path.get_file(), row.tick]
	if absf(float(state.x) - float(row.x)) > 0.001:
		errors.append("%s x expected %.5f got %.8f" % [label, row.x, state.x])
	if absf(float(state.y) - float(row.y)) > 0.001:
		errors.append("%s y expected %.5f got %.8f" % [label, row.y, state.y])
	if bool(state.dead) != bool(row.dead):
		errors.append("%s dead expected %s got %s" % [label, row.dead, state.dead])
	var expected_ms := float(row.tick) * 1000.0 / 240.0
	if absf(float(row.t_ms) - expected_ms) > 0.01:
		errors.append("%s recording timestamp is inconsistent with SIM-01" % label)

func _check_event(path: String, row: Dictionary, state: Dictionary, sim, errors: Array[String]) -> void:
	var note := String(row.event).strip_edges().to_lower()
	if note.is_empty():
		return
	var label := "%s event '%s'" % [path.get_file(), note]
	if note.contains("tapped"):
		var expected_tap_tick := 8 if path.contains("tc01") else 200
		if int(row.tick) != expected_tap_tick:
			errors.append("%s at wrong input tick %d" % [label, row.tick])
		return
	if note.contains("first airborne") or note.contains("first airborne tick"):
		if state.event != "jump": errors.append("%s missing jump departure on tick %d" % [label, row.tick])
		return
	if note.contains("apex"):
		if int(row.tick) != 59 or state.y <= 0.0: errors.append("%s wrong apex tick" % label)
		if sim.vy <= 0.0: errors.append("%s apex should be the last upward step" % label)
		return
	if note.contains("landed on block") or note.contains("landed on ground"):
		if state.event != "land": errors.append("%s missing landing at tick %d" % [label, row.tick])
		return
	if note.contains("last tick supported"):
		if int(row.tick) != 311 or not sim.supported: errors.append("%s support event tick mismatch" % label)
		return
	if note.contains("falling") or note.contains("rolled off"):
		if int(row.tick) != 312 or state.event != "fall": errors.append("%s roll-off event tick mismatch" % label)
		return
	if note.contains("last alive"):
		if int(row.tick) != 413 or state.dead: errors.append("%s alive boundary tick mismatch" % label)
		return
	if note.contains("death"):
		if state.event != "death" or int(row.tick) != 414: errors.append("%s death event tick mismatch" % label)
