extends SceneTree

const Session = preload("res://scripts/core/session.gd")
const Save = preload("res://scripts/core/save_service.gd")
const Layout = preload("res://scripts/core/shop_layout.gd")
const Settings = preload("res://scripts/core/settings.gd")
var checks: int = 0
var failures: int = 0

func check(condition: bool, title: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + title)

func invariant(s: CandySession) -> void:
	var copy := Session.new()
	check(copy.restore(s.snapshot()), "conservation, capacities, immutable variants, families and progress")

func fill_variant(s: CandySession, variant: int, destination: int) -> void:
	for id in range(variant * 20, variant * 20 + 20):
		check(s.try_pickup(id).is_empty(), "pickup")
		check(s.try_deposit(destination).is_empty(), "deposit")
	invariant(s)

func _initialize() -> void:
	var s := Session.new()
	s.fresh(12345)
	check(s.items.size() == 320 and s.bins.size() == 16, "exact catalog")
	check(s.capacity() == 5 and s.reach() == 2.0, "accepted starting capacity and reach")
	var same := Session.new()
	same.fresh(12345)
	check(s.snapshot() == same.snapshot(), "seed preserves actual spawn positions")
	var positions := Layout.spawn_slots()
	check(positions.size() >= 320, "enough validated scatter slots")
	for point in positions:
		check(Layout.valid_loose_pose(point), "spawn on reachable floor or countertop")
	for i in positions.size():
		for j in range(i + 1, positions.size()):
			check(Vector2(positions[i].x - positions[j].x, positions[i].z - positions[j].z).length() >= 0.399, "heap centers remain distinct")
	for id in [0, 20, 80, 160, 240]:
		check(s.try_pickup(id).is_empty(), "mixed families in inventory")
	check(s.selected_id() == 240, "newest selected")
	var before := s.snapshot()
	check(not s.try_pickup(1).is_empty() and s.snapshot() == before, "full inventory atomic rejection")
	check(not s.try_deposit(0).is_empty() and s.snapshot() == before, "wrong family atomic rejection")
	check(s.try_drop_selected(Layout.recovery_slots()[0]).is_empty(), "drop frees full inventory")
	s.select_inventory_item(0)
	check(s.selected_id() == 0, "mixed selection")
	check(s.try_deposit(0).is_empty() and s.count(0) == 1, "single selected deposit")
	check(s.try_retrieve(0, 0).is_empty() and s.selected_id() == 0, "specific retrieval selects item")
	invariant(s)
	# Any same-family destination assignment can finish; upgrades reflect simultaneous high water.
	for offset in [0, 3]:
		s.fresh(321)
		for variant in 16:
			var destination: int = (variant / 4) * 4 + posmod(variant + offset, 4)
			fill_variant(s, variant, destination)
			check(s.high_water == variant + 1, "simultaneous high-water progression")
			check(s.capacity() == (12 if variant >= 9 else (8 if variant >= 1 else 5)), "carry thresholds")
			check(s.reach() == (3.0 if variant >= 3 else 2.0), "reach threshold")
		check(s.progress() == 16, "player-chosen assignments finish")
		s.try_retrieve(0, 3)
		check(s.progress() == 15 and s.high_water == 16 and s.capacity() == 12, "removal reverses only current completion")
		var removed := s.selected_id()
		s.try_deposit(0)
		check(s.bins[0][3] == removed and s.progress() == 16, "earliest-free slot recompletion")
	# Repeating one bin cannot farm a second unlock.
	s.fresh(42)
	fill_variant(s, 0, 0)
	for repeat in 15:
		s.try_retrieve(0, 0)
		s.try_deposit(0)
	check(s.high_water == 1 and s.capacity() == 5, "no upgrade farming")
	fill_variant(s, 1, 1)
	s.try_retrieve(0, 19)
	s.try_retrieve(1, 19)
	s.try_deposit(0)
	s.try_deposit(1)
	check(s.progress() == 0 and s.count(0) == 20, "19 matching plus one different remains incomplete")
	s.try_retrieve(0, 19)
	s.try_retrieve(1, 19)
	s.try_deposit(0)
	s.try_deposit(1)
	check(s.progress() == 2, "correcting mistakes restores completion")
	s.fresh(42)
	for id in 3:
		s.try_pickup(id)
		s.try_deposit(0)
	s.try_retrieve(0, 0)
	s.try_deposit(0)
	s.try_retrieve(0)
	check(s.selected_id() == 0, "container retrieval still chooses newest deposit after a hole refill")
	# All candy stored in mixtures, with no matching finder unlock, remains solvable.
	s.fresh(76)
	for id in 320:
		s.try_pickup(id)
		s.try_deposit((id / 80) * 4 + id % 4)
	check(s.progress() == 0 and s.high_water == 0 and s.outside_count() == 0, "all full mixed displays")
	check(s.assistance().mode == "mixed", "remaining finder bypasses upgrade gate for full mixtures")
	for slot in 5:
		s.try_retrieve(0, slot)
	before = s.snapshot()
	check(not s.try_retrieve(1).is_empty() and before == s.snapshot(), "retrieval with full hands is atomic")
	check(not s.try_deposit(1).is_empty() and before == s.snapshot(), "full display rejection")
	check(s.assistance().mode == "carried", "finder reminds player to place carried pieces")
	s.try_drop_selected(Layout.recovery_slots()[0])
	check(s.assistance().mode == "remaining", "finder points at last loose piece")
	s.select_inventory_item(2)
	var path: String = "user://shop_rule_test.json"
	check(Save.write(s, {"position": [0, 0.02, 8.7], "yaw": 0.5, "pitch": -0.2}, path), "save mixed session")
	var restored := Session.new()
	check(restored.restore(Save.read(path)), "load validated snapshot")
	var normalized := restored.snapshot()
	for id in 320:
		for axis in 3:
			check(absf(s.items[id].position[axis] - restored.items[id].position[axis]) < 0.000001, "pose round trip within a micrometer")
			check(absf(s.items[id].rotation[axis] - restored.items[id].rotation[axis]) < 0.000001, "scatter orientation survives save")
		normalized.items[id].position = s.items[id].position.duplicate()
		normalized.items[id].rotation = s.items[id].rotation.duplicate()
	check(normalized == s.snapshot(), "discrete snapshot round trip exact")
	check(Save.write(s, {}, path), "atomic replacement")
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string("{broken save")
	corrupt.close()
	check(Save.read(path).is_empty() and not Save.read(path + ".bak").is_empty(), "corrupt primary retains valid backup")
	var invalid := s.snapshot()
	invalid.inventory.append(invalid.inventory[0])
	before = restored.snapshot()
	check(not restored.restore(invalid) and before == restored.snapshot(), "duplicate rejection is atomic")
	invalid = s.snapshot()
	invalid.items[0].variant = 1
	check(not restored.restore(invalid), "variant membership immutable")
	invalid = s.snapshot()
	invalid.high_water = 20
	check(not restored.restore(invalid), "invalid progression rejected")
	invalid = s.snapshot()
	invalid.items[0].position = [999, 0.12, 999]
	check(not restored.restore(invalid), "unreachable saved pose rejected")
	# Finder matching selected or aimed flavor, including no loose matches.
	s.fresh(9)
	for variant in 6:
		fill_variant(s, variant, variant)
	s.find_remaining = false
	check(s.assistance().mode == "select", "matching needs a selected or aimed variant")
	check(s.assistance(6).items.size() == 20, "matching finds all loose copies")
	check(s.assistance(0).items.is_empty(), "matching excludes stored copies")
	# Random transfer stream and selection preserve all contracts.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for step in 2000:
		match rng.randi_range(0, 4):
			0: s.try_pickup(rng.randi_range(0, 319))
			1: s.try_deposit(rng.randi_range(0, 15))
			2: s.try_retrieve(rng.randi_range(0, 15), rng.randi_range(-1, 19))
			3: s.try_drop_selected(Layout.recovery_slots()[0])
			4: s.select_inventory_item(rng.randi_range(-15, 15))
		invariant(s)
	# Settings independent of run restart and serialized via ConfigFile.
	var preferences := Settings.new()
	preferences.values.stick = 3.1
	preferences.values.invert_y = true
	preferences.values.master = 0.25
	var settings_path: String = "user://shop_settings_test.cfg"
	check(preferences.write(settings_path), "settings write")
	var loaded := Settings.new()
	loaded.read(settings_path)
	check(loaded.values == preferences.values, "settings persisted exactly")
	s.fresh(111)
	check(s.progress() == 0 and s.high_water == 0 and s.capacity() == 5 and not s.celebrated, "restart clears run and upgrades")
	check(s.next_upgrade().remaining == 2 and s.next_upgrade().threshold == 2, "next-upgrade goal at start")
	fill_variant(s, 0, 0)
	check(s.next_upgrade().remaining == 1, "next-upgrade remaining progress")
	s.try_retrieve(0, 0)
	check(s.next_upgrade().remaining == 1, "upgrade goal uses permanent high water")
	var legacy := s.snapshot()
	legacy.erase("layout_revision")
	for item in legacy.items:
		item.erase("rotation")
	legacy.items[100].position = [2.87, 1.02, -7.72]
	var migrated := Session.new()
	check(migrated.restore(legacy), "prior full-shop save migrates")
	check(migrated.inventory == s.inventory and migrated.bins == s.bins and migrated.high_water == s.high_water, "migration preserves held/stored progress")
	check(migrated.items[100].position[1] < 0.56 and migrated.items[100].has("rotation"), "migration relocates countertop clutter into floor heaps")
	for seed_value in [1, 2, 99, 4567]:
		var spill := Session.new()
		spill.fresh(seed_value)
		invariant(spill)
		for item in spill.items:
			check(item.position[1] < 0.56, "initial candy is never scattered on shelves/counters")
	check(loaded.values == preferences.values, "restart retains settings")
	for file_path in [path, path + ".bak", path + ".tmp", settings_path]:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)
	print("RULE TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
