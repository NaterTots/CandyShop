class_name ShopLayout
extends RefCounted

# Wider tuning of the same one-room sketch: clear aisles for 320 chunky pieces.
const WIDTH: float = 18.0
const DEPTH: float = 22.0
const SPAWN: Vector3 = Vector3(0, 0.02, 8.7)
const KIOSKS: Array[Vector3] = [Vector3(-2.4, 0, 2.0), Vector3(2.4, 0, -2.8)]
const COUNTER: Rect2 = Rect2(-7.8, -8.6, 13.4, 1.2)
const KIOSK_YAW: float = PI / 4.0
const BIN_SIZE: float = 1.84

static func destination_position(bin: int) -> Vector3:
	if bin < 8:
		var center := KIOSKS[bin / 4]
		var local_index := bin % 4
		var local := Vector3(-0.96 if local_index % 2 == 0 else 0.96, 0.87, -0.96 if local_index < 2 else 0.96)
		return center + Basis(Vector3.UP, KIOSK_YAW) * local
	var index := bin % 4
	return Vector3(-8.15 if bin < 12 else 8.15, 0.5, 5.0 - index * 3.4)

static func destination_yaw(bin: int) -> float:
	if bin < 8:
		return KIOSK_YAW + (PI if bin % 4 < 2 else 0.0)
	return PI / 2.0 if bin < 12 else -PI / 2.0

static func slot_position(bin: int, slot: int) -> Vector3:
	var local: Vector3
	if bin < 8:
		local = Vector3((slot % 5 - 2) * 0.34, 0.08 + (slot / 5) * 0.045, 0.54 - (slot / 5) * 0.36)
	else:
		# Four open shelf levels, five face-out pieces per level.
		local = Vector3((slot % 5 - 2) * 0.30, (slot / 5) * 0.32, 0.07)
	return destination_position(bin) + Basis(Vector3.UP, destination_yaw(bin)) * local

static func slot_approach(bin: int, slot: int) -> Vector3:
	var pos := slot_position(bin, slot)
	var forward := Basis(Vector3.UP, destination_yaw(bin)) * Vector3.BACK
	var distance: float = 1.1 if bin < 8 else 0.95
	return Vector3(pos.x, 0.02, pos.z) + forward * distance

static func floor_clear(pos: Vector3, margin: float = 0.3) -> bool:
	if absf(pos.x) > 8.65 - margin or absf(pos.z) > 10.65 - margin:
		return false
	if COUNTER.grow(margin).has_point(Vector2(pos.x, pos.z)):
		return false
	for center in KIOSKS:
		# Rotated 4 m square. L1 distance models its actual footprint.
		if absf(pos.x - center.x) + absf(pos.z - center.z) < 2.83 + margin * 1.4143:
			return false
	for bin in range(8, 16):
		var center := destination_position(bin)
		if Rect2(Vector2(center.x - 0.45, center.z - 0.95), Vector2(0.9, 1.9)).grow(margin).has_point(Vector2(pos.x, pos.z)):
			return false
	return true

static func spawn_slots(seed_value: int = 42) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var heaps: Array[Vector2] = [Vector2(-5.6, 4.5), Vector2(5.7, 4.6), Vector2(-5.7, -1.7), Vector2(5.6, -5.5), Vector2(-2.9, 6.5), Vector2(3.1, 6.5), Vector2(-3.9, -5.8), Vector2(0.1, -5.8)]
	# Irregular shallow heaps plus isolated spill trails. Never shelves or counters.
	for attempt in 100000:
		if result.size() == 320:
			break
		var piled: bool = result.size() < 240 and attempt < 30000
		var point: Vector2
		var height: float = 0.12
		if piled:
			var center := heaps[rng.randi_range(0, heaps.size() - 1)]
			var radius := rng.randf_range(0.0, 1.8)
			point = center + Vector2.from_angle(rng.randf_range(-PI, PI)) * radius
			height += 0.34 * pow(1.0 - radius / 1.8, 1.6) + rng.randf_range(0.0, 0.06)
		else:
			point = Vector2(rng.randf_range(-7.4, 7.4), rng.randf_range(-6.8, 8.3))
		var pos := Vector3(point.x, height, point.y)
		if not floor_clear(pos, 0.65) or (pos.z > 6.0 and absf(pos.x) < 0.95):
			continue
		var clear: bool = true
		for other in result:
			if Vector2(other.x - pos.x, other.z - pos.z).length() < (0.40 if piled else 0.62):
				clear = false
				break
		if clear:
			result.append(pos)
	assert(result.size() == 320, "Could not populate the floor spill")
	return result

static func recovery_slots() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for row in 3:
		for col in 15:
			result.append(Vector3(-3.71 + col * 0.53, 0.12, 9.05 + row * 0.53))
	return result

static func valid_loose_pose(pos: Vector3) -> bool:
	if not pos.is_finite():
		return false
	if pos.y >= 0.1 and pos.y <= 0.56:
		return floor_clear(pos, 0.1)
	return absf(pos.y - 1.02) < 0.01 and COUNTER.grow(-0.15).has_point(Vector2(pos.x, pos.z))
