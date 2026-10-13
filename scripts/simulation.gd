class_name VertexDashSimulation
extends RefCounted

# SIM-01: fixed tick. SIM-02: coordinate system and start state.
# CUBE-01, CUBE-02, CUBE-03: measured normal speed, gravity and jump impulse.
const SPEED := 1.29825
const GRAVITY := 0.0486
const JUMP_VELOCITY := 2.5155
const START_Y := 105.0
const GROUND_Y := 90.0
const OUTER_HALF := 15.0 # CUBE-06
const INNER_HALF := 4.5 # CUBE-06
const SPIKE_HALF_WIDTH := 3.0 # OBJ-02
const SPIKE_HALF_HEIGHT := 6.0 # OBJ-02
const SPIN_PER_TICK := 1.725 # CUBE-07: degrees clockwise per airborne tick.
const SETTLE_FACTOR := 0.883 # CUBE-07: remaining angle kept per grounded tick.

var tick := 0
var x := 0.0
var y := START_Y
var vy := 0.0
var dead := false
var angle := 0.0 # CUBE-07: visual only, degrees clockwise. Never used for collision.
var supported := true
var support_top := GROUND_Y
var jump_held := false
var jump_buffered := false
var objects: Array[Dictionary] = []

func reset(level_objects: Array[Dictionary]) -> void:
	tick = 0
	x = 0.0
	y = START_Y
	vy = 0.0
	dead = false
	angle = 0.0
	supported = true
	support_top = GROUND_Y
	jump_held = false
	jump_buffered = false
	objects = level_objects.duplicate(true)

func set_jump(held: bool, pressed: bool = false) -> void:
	jump_held = held
	if pressed:
		jump_buffered = true

func step() -> Dictionary:
	if dead:
		reset(objects) # OBJ-03: next step begins a new attempt at tick 0.
		return state("restart")
	tick += 1
	var event := ""
	var old_y := y
	x += SPEED # CUBE-01
	var auto_rejump := false
	if supported:
		if _support_remains():
			y = support_top + OUTER_HALF
			vy = 0.0
			if jump_buffered or jump_held:
				auto_rejump = jump_held and not jump_buffered
				vy = JUMP_VELOCITY
				supported = false
				jump_buffered = false
				event = "jump"
		else:
			supported = false
			vy = 0.0
			event = "fall" # OBJ-01: first unsupported tick after passing the block edge.
	if not supported:
		# CUBE-03: fresh presses receive gravity on departure; held auto-rejumps do not.
		if not auto_rejump:
			vy -= GRAVITY
		y += vy
		var landing_top := _landing_top(old_y, y)
		if landing_top > -INF:
			y = landing_top + OUTER_HALF
			vy = 0.0
			supported = true
			support_top = landing_top
			event = "land"
	if _block_death() or _spike_death(): # OBJ-03
		dead = true
		event = "death"
	_update_angle()
	# B-05: a press latch is consumed at a supported departure or discarded in air.
	if jump_buffered:
		jump_buffered = false
	return state(event)

func state(event: String = "") -> Dictionary:
	return {"tick": tick, "x": x, "y": y, "dead": dead, "event": event, "vy": vy, "angle": angle}

func _support_remains() -> bool:
	if is_equal_approx(support_top, GROUND_Y):
		return true
	for obj in objects:
		if int(obj.get("id", 0)) != 1:
			continue
		var ox := float(obj.x)
		var top := float(obj.y) + 90.0 + 15.0 # LVL-03, SIM-02, OBJ-01
		if is_equal_approx(top, support_top) and x + OUTER_HALF > ox - 15.0 and x - OUTER_HALF <= ox + 15.0:
			return true # OBJ-01
	return false

func _landing_top(old_y: float, new_y: float) -> float:
	var best := -INF
	if new_y - OUTER_HALF < GROUND_Y and old_y - OUTER_HALF >= GROUND_Y:
		best = GROUND_Y
	for obj in objects:
		if int(obj.get("id", 0)) != 1:
			continue
		var ox := float(obj.x)
		var top := float(obj.y) + 90.0 + 15.0 # LVL-03, SIM-02, OBJ-01
		if new_y - OUTER_HALF < top and old_y - OUTER_HALF >= top and x + OUTER_HALF > ox - 15.0 and x - OUTER_HALF < ox + 15.0:
			best = maxf(best, top)
	return best

func _block_death() -> bool:
	for obj in objects:
		if int(obj.get("id", 0)) != 1:
			continue
		var ox := float(obj.x)
		var oy := float(obj.y) + 90.0 # LVL-03, SIM-02
		if absf(x - ox) < INNER_HALF + 15.0 and absf(y - oy) < INNER_HALF + 15.0: # CUBE-06, OBJ-01
			return true
	return false

func _spike_death() -> bool:
	for obj in objects:
		if int(obj.get("id", 0)) != 8:
			continue
		var ox := float(obj.x)
		var oy := float(obj.y) + 90.0 # LVL-03, SIM-02
		if absf(x - ox) < OUTER_HALF + SPIKE_HALF_WIDTH and absf(y - oy) < OUTER_HALF + SPIKE_HALF_HEIGHT: # CUBE-06, OBJ-02
			return true
	return false

func _update_angle() -> void:
	# CUBE-07: spin at a constant rate while airborne; once supported, keep turning clockwise
	# towards the next multiple of 90 degrees, shrinking the remaining angle each tick.
	# Unverified in SPEC: settle direction when less than 45 degrees past a multiple of 90.
	if not supported:
		angle = fmod(angle + SPIN_PER_TICK, 360.0)
		return
	var target := ceilf(angle / 90.0 - 0.000001) * 90.0
	var remaining := target - angle
	if remaining < 0.01:
		angle = fmod(target, 360.0)
	else:
		angle = target - remaining * SETTLE_FACTOR