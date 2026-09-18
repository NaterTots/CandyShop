class_name CandySession
extends RefCounted

const Catalog = preload("res://resources/candy/catalog.gd")
const Layout = preload("res://scripts/core/shop_layout.gd")
const TOTAL: int = 320
const CAPACITY: int = 5
const SLOTS: int = 20
var items: Array[Dictionary] = []
var inventory: Array[int] = []
var bins: Array = []
var selected: int = 0
var run_seed: int = 0
var celebrated: bool = false
var high_water: int = 0
var completed_once: Array[int] = []
var find_remaining: bool = true

func fresh(seed_value: int) -> void:
	run_seed = seed_value
	items.clear()
	inventory.clear()
	bins = []
	for destination in Catalog.DESTINATION_COUNT:
		var bin: Array = []
		bin.resize(SLOTS)
		bin.fill(-1)
		bins.append(bin)
	selected = 0
	celebrated = false
	high_water = 0
	completed_once.clear()
	find_remaining = true
	var positions := Layout.spawn_slots(run_seed)
	assert(positions.size() >= TOTAL, "Layout needs at least 320 validated positions")
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	for i in range(positions.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var old := positions[i]
		positions[i] = positions[j]
		positions[j] = old
	for i in TOTAL:
		var pos := positions[i]
		var rotation := Vector3(rng.randf_range(-1.5, -1.1), rng.randf_range(-PI, PI), rng.randf_range(-0.08, 0.08))
		var offset := Basis.from_euler(rotation) * Vector3(0, 0.39 if i < 80 else 0.22, 0)
		pos -= Vector3(offset.x, 0, offset.z)
		items.append({"variant": i / SLOTS, "owner": "world", "order": 0, "position": [pos.x, pos.y, pos.z], "rotation": [rotation.x, rotation.y, rotation.z]})

func selected_id() -> int:
	return -1 if inventory.is_empty() else inventory[selected]

func select_inventory_item(index: int) -> void:
	selected = 0 if inventory.is_empty() else posmod(index, inventory.size())

func try_pickup(id: int) -> String:
	if id < 0 or id >= items.size() or items[id].owner != "world":
		return "That piece is no longer loose."
	if inventory.size() >= capacity():
		return "Hands full — place a piece or safe drop."
	items[id].owner = "inventory"
	inventory.append(id)
	selected = inventory.size() - 1
	return ""

func try_deposit(destination: int) -> String:
	if destination < 0 or destination >= bins.size():
		return "Aim at a display."
	var id := selected_id()
	if id < 0:
		return "Pick up a piece first."
	if Catalog.family(int(items[id].variant)) != destination / 4:
		return Catalog.FAMILIES[destination / 4] + " go here."
	var slot: int = bins[destination].find(-1)
	if slot < 0:
		return "Full display — retrieve a piece to rearrange."
	bins[destination][slot] = id
	items[id].owner = "bin"
	var order: int = 0
	for item in items:
		order = maxi(order, int(item.get("order", 0)))
	items[id].order = order + 1
	_remove_selected()
	_update_progress()
	return ""

func try_retrieve(destination: int, slot: int = -1) -> String:
	if inventory.size() >= capacity():
		return "Hands full — place a piece or safe drop."
	if destination < 0 or destination >= bins.size():
		return "No display here."
	if slot < 0:
		# Last deposited remaining piece, independent of its physical slot.
		var latest: int = -1
		for s in SLOTS:
			var candidate: int = bins[destination][s]
			if candidate >= 0 and int(items[candidate].get("order", 0)) >= latest:
				latest = int(items[candidate].get("order", 0))
				slot = s
	if slot < 0 or slot >= SLOTS or bins[destination][slot] < 0:
		return "This slot is empty."
	var id: int = bins[destination][slot]
	bins[destination][slot] = -1
	items[id].owner = "inventory"
	inventory.append(id)
	selected = inventory.size() - 1
	return ""

func try_drop_selected(position: Vector3) -> String:
	var id := selected_id()
	if id < 0:
		return "Your hands are empty."
	if not Layout.valid_loose_pose(position):
		return "No space here."
	items[id].owner = "world"
	items[id].position = [position.x, position.y, position.z]
	items[id]["rotation"] = [-1.3, items[id].get("rotation", [0, 0, 0])[1], 0.0]
	_remove_selected()
	return ""

func _remove_selected() -> void:
	inventory.remove_at(selected)
	selected = clampi(selected, 0, maxi(0, inventory.size() - 1))

func count(destination: int) -> int:
	return SLOTS - bins[destination].count(-1)

func complete(destination: int) -> bool:
	if count(destination) != SLOTS:
		return false
	var variant: int = items[bins[destination][0]].variant
	for id in bins[destination]:
		if items[id].variant != variant:
			return false
	return true

func progress() -> int:
	var result: int = 0
	for bin in bins.size():
		result += int(complete(bin))
	return result

func _update_progress() -> void:
	high_water = maxi(high_water, progress())
	for bin in bins.size():
		if complete(bin) and not bin in completed_once:
			completed_once.append(bin)

func capacity() -> int:
	return 12 if high_water >= 10 else (8 if high_water >= 2 else 5)

func next_upgrade() -> Dictionary:
	for entry in [[2, "Carry 8 candies"], [4, "Reach 3 meters"], [6, "Find matching candy"], [10, "Carry 12 candies"]]:
		if high_water < entry[0]:
			return {"label": entry[1], "threshold": entry[0], "remaining": entry[0] - high_water}
	return {"label": "All upgrades unlocked", "threshold": 10, "remaining": 0}

func reach() -> float:
	return 3.0 if high_water >= 4 else 2.0

func unlocks() -> Dictionary:
	return {"capacity": capacity(), "reach": reach(), "matching": high_water >= 6}

func outside_count() -> int:
	var result: int = 0
	for item in items:
		result += int(item.owner != "bin")
	return result

func assistance(variant: int = -1) -> Dictionary:
	if find_remaining and outside_count() <= 32:
		for id in items.size():
			if items[id].owner == "world":
				return {"mode": "remaining", "item": id}
		if not inventory.is_empty():
			return {"mode": "carried"}
		for bin in bins.size():
			if not complete(bin):
				return {"mode": "mixed", "bin": bin}
		return {"mode": "complete"}
	if high_water < 6:
		return {"mode": "locked"}
	if variant < 0 or variant >= Catalog.VARIANT_COUNT:
		return {"mode": "select"}
	var matches: Array[int] = []
	for id in items.size():
		if items[id].owner == "world" and items[id].variant == variant:
			matches.append(id)
	return {"mode": "matching", "items": matches}

func snapshot() -> Dictionary:
	return {"schema": 2, "content": "shop-320-v1", "layout_revision": 2, "seed": run_seed, "items": items.duplicate(true), "inventory": inventory.duplicate(), "bins": bins.duplicate(true), "selected": selected, "celebrated": celebrated, "high_water": high_water, "unlocks": unlocks(), "completed_once": completed_once.duplicate(), "find_remaining": find_remaining}

func restore(data: Dictionary) -> bool:
	if data.get("schema") != 2 or data.get("content") != "shop-320-v1":
		return false
	if not data.get("items") is Array or not data.get("bins") is Array or not data.get("inventory") is Array:
		return false
	var raw: Array = data.items
	var slots: Array = data.bins
	var held: Array = data.inventory
	if not _whole(data.get("high_water"), 0, 16) or not _whole(data.get("seed"), 0, 9223372036854775807):
		return false
	var saved_high: int = int(data.high_water)
	var saved_capacity: int = 12 if saved_high >= 10 else (8 if saved_high >= 2 else 5)
	if raw.size() != TOTAL or slots.size() != 16 or held.size() > saved_capacity:
		return false
	if data.get("layout_revision", 1) == 1:
		# Relocate only loose pieces; preserve the player's inventory, slots and upgrades.
		var fresh_layout := CandySession.new()
		fresh_layout.fresh(int(data.seed))
		raw = raw.duplicate(true)
		for index in raw.size():
			if raw[index] is Dictionary and raw[index].get("owner") == "world":
				raw[index]["position"] = fresh_layout.items[index].position.duplicate()
				raw[index]["rotation"] = fresh_layout.items[index].rotation.duplicate()
	var seen: Array[int] = []
	var counts: Array[int] = []
	counts.resize(16)
	counts.fill(0)
	for index in raw.size():
		var item: Variant = raw[index]
		if not item is Dictionary or not _whole(item.get("variant"), 0, 15) or int(item.variant) != index / SLOTS or not item.get("owner") in ["world", "inventory", "bin"]:
			return false
		if not item.get("position") is Array or item.position.size() != 3:
			return false
		for axis in item.position:
			if not (axis is float or axis is int) or not is_finite(float(axis)):
				return false
		if absf(item.position[0]) > 8.7 or absf(item.position[2]) > 10.7 or item.position[1] < 0.0 or item.position[1] > 1.1:
			return false
		if item.owner == "world" and not Layout.valid_loose_pose(Vector3(item.position[0], item.position[1], item.position[2])):
			return false
		var rotation: Variant = item.get("rotation", [-1.134464, 0.0, 0.0])
		if not rotation is Array or rotation.size() != 3:
			return false
		for axis in rotation:
			if not (axis is float or axis is int) or not is_finite(float(axis)):
				return false
		var order: Variant = item.get("order", 0)
		if not _whole(order, 0, 9007199254740991):
			return false
		counts[int(item.variant)] += 1
	for id in held:
		if not _valid_id(id) or int(id) in seen or raw[int(id)].owner != "inventory":
			return false
		seen.append(int(id))
	for destination in slots.size():
		var bin: Variant = slots[destination]
		if not bin is Array or bin.size() != SLOTS:
			return false
		for id in bin:
			if id == -1:
				continue
			if not _valid_id(id) or int(id) in seen or raw[int(id)].owner != "bin":
				return false
			if Catalog.family(int(raw[int(id)].variant)) != destination / 4:
				return false
			seen.append(int(id))
	for id in TOTAL:
		if raw[id].owner == "world":
			if id in seen:
				return false
			seen.append(id)
	if seen.size() != TOTAL or counts.count(20) != 16:
		return false
	if not _whole(data.get("selected"), 0, maxi(0, held.size() - 1)):
		return false
	var selection: int = int(data.selected)
	if not data.get("completed_once") is Array or not data.get("celebrated") is bool or not data.get("find_remaining") is bool:
		return false
	var once: Array[int] = []
	for destination in data.completed_once:
		if not _whole(destination, 0, 15) or int(destination) in once:
			return false
		once.append(int(destination))
	var current: int = 0
	for destination in slots.size():
		var ids: Array = slots[destination]
		var full: bool = not ids.has(-1) and not ids.has(-1.0)
		if full:
			for id in ids:
				full = full and raw[int(id)].variant == raw[int(ids[0])].variant
		if full:
			current += 1
			if not destination in once:
				return false
	if saved_high < current or saved_high > once.size() or (data.celebrated and saved_high != 16):
		return false
	items.assign(raw.duplicate(true))
	for item in items:
		item.variant = int(item.variant)
		if item.has("order"):
			item.order = int(item.order)
	inventory.assign(held)
	bins = slots.duplicate(true)
	for bin in bins:
		for slot in bin.size():
			bin[slot] = int(bin[slot])
	selected = selection
	run_seed = int(data.get("seed", 0))
	celebrated = bool(data.get("celebrated", false))
	high_water = saved_high
	completed_once = once
	find_remaining = data.find_remaining
	return true

func _valid_id(id: Variant) -> bool:
	return _whole(id, 0, TOTAL - 1)

func _whole(value: Variant, low: int, high: int) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high
