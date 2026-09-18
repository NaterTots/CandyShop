extends SceneTree

const Layout = preload("res://scripts/core/shop_layout.gd")
const Art = preload("res://scripts/candy_art.gd")
const Catalog = preload("res://resources/candy/catalog.gd")
var failures: int = 0
var checks: int = 0
var game: Node3D

func check(condition: bool, title: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		if failures <= 30:
			push_error("FAIL: " + title)

func _initialize() -> void:
	call_deferred("run")

func aim(id: int, candidate: Vector3) -> bool:
	if not Layout.floor_clear(candidate, 0.27):
		return false
	game.player.position = candidate
	game.player.rotation = Vector3.ZERO
	var candy: Node3D = game.view_nodes[id]
	var point := candy.global_transform * Art.center(int(game.session.items[id].variant))
	game.camera.look_at(point)
	await physics_frame
	game._target()
	return game.target.get("item", -1) == id

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + name + ".png")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	await process_frame
	game.session.fresh(42)
	game._rebuild_views()
	game._resume()
	game.paused = true
	await physics_frame
	check(game.views.get_child_count() == 320, "320 live candy views")
	check(game.rims.size() == 16, "16 family destinations")
	var pose := Transform3D(Basis.IDENTITY, Vector3(6.5, 0.02, -6.0))
	check(not game.player.test_move(pose, Vector3(0, 0, -3.7)), "right counter gap walkable")
	pose.origin = Vector3(6.5, 0.02, -9.7)
	check(not game.player.test_move(pose, Vector3(-13.0, 0, 0)), "employee aisle walkable")
	pose.origin = Vector3(0, 0.02, 10.0)
	check(game.player.test_move(pose, Vector3(0, 0, 2)), "locked front boundary")
	# Every initial item must be individually targetable within the accepted 2 m reach.
	var loose_reached: int = 0
	for id in 320:
		var item: Dictionary = game.session.items[id]
		var pos := Vector3(item.position[0], item.position[1], item.position[2])
		var reached: bool = false
		var approaches: Array[Vector3] = []
		for direction in [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]:
			approaches.append(Vector3(pos.x, 0.02, pos.z) + direction * (1.45 if pos.y > 0.5 else 0.75))
		# A sideways step in the employee aisle can see past a taller neighboring sweet.
		for side: float in [-1.0, 1.0]:
			for offset: float in [-0.4, 0.4]:
				approaches.append(Vector3(pos.x + offset, 0.02, pos.z + side * (1.45 if pos.y > 0.5 else 0.65)))
		for candidate in approaches:
			if await aim(id, candidate):
				reached = true
				break
		loose_reached += int(reached)
		check(reached, "loose piece %d reachable at %s" % [id, str(pos)])
	print("Loose pieces targetable at 2 m: %d/320" % loose_reached)
	# Place everything through the authoritative API, then inspect all occupied slots.
	for id in 320:
		game.session.try_pickup(id)
		game.session.try_deposit(id / 20)
	game._rebuild_views()
	await physics_frame
	check(game.session.progress() == 16, "full shop completes through existing transfers")
	game.session.high_water = 0 # Reach-only test override; no save is written.
	var slots_reached: int = 0
	for bin in 16:
		for slot in 20:
			var id: int = game.session.bins[bin][slot]
			var candidates: Array[Vector3] = [Layout.slot_approach(bin, slot)]
			if bin < 8:
				var center: Vector3 = Layout.KIOSKS[bin / 4]
				for side: float in [-1.0, 1.0]:
					for step in 25:
						var x: float = -3.12 + step * 0.26
						candidates.append(center + Vector3(x, 0.02, side * (3.24 - absf(x))))
			var reached: bool = false
			for candidate in candidates:
				var point: Vector3 = game.view_nodes[id].global_transform * Art.center(id / 20)
				if (candidate + Vector3(0, 1.6, 0)).distance_to(point) > 2.2:
					continue
				if await aim(id, candidate):
					reached = true
					break
			slots_reached += int(reached)
			check(reached, "stored slot %d/%d targetable at 2 m" % [bin, slot])
	print("Stored slots targetable at 2 m: %d/320" % slots_reached)
	game.session.high_water = 16
	# Last real placement invokes completion UI, particles, and the persisted one-shot flag.
	game.session.try_retrieve(0, 19)
	game._rebuild_views()
	game.player.position = Layout.destination_position(0) + Basis(Vector3.UP, Layout.destination_yaw(0)) * Vector3(0, 0, 1.4)
	game.player.position.y = 0.02
	game.player.rotation = Vector3.ZERO
	game.camera.look_at(Layout.destination_position(0))
	await physics_frame
	game._interact(false)
	check(game.session.celebrated and game.menu_page == "completion" and game.menu.visible, "last placement opens real completion panel")
	game._resume()
	game.paused = true
	game.session.try_retrieve(0, 19)
	game._rebuild_views()
	await physics_frame
	game._interact(false)
	check(not game.menu.visible and game.session.progress() == 16, "recompletion does not repeat final celebration")
	# Synthetic triggers verify accepted press/release behavior; not hardware testing.
	game.session.fresh(42)
	for id in 5:
		game.session.try_pickup(id)
	game._rebuild_views()
	game.player.position = Layout.destination_position(0) + Basis(Vector3.UP, Layout.destination_yaw(0)) * Vector3(0, 0, 1.4)
	game.player.position.y = 0.02
	game.player.rotation = Vector3.ZERO
	game.camera.look_at(Layout.destination_position(0))
	await physics_frame
	game.paused = false
	game.trigger_down.assign([false, false])
	for amount: float in [0.7, 0.62, 0.68, 0.4, 0.8, 1.0]:
		game._trigger(0, amount)
	check(game.session.count(0) == 1, "trigger jitter deposits once")
	game._trigger(0, 0.1)
	game._trigger(0, 0.9)
	check(game.session.count(0) == 2, "rearmed trigger deposits once more")
	game.paused = true
	game._trigger(0, 0.0)
	game._trigger(0, 1.0)
	game.paused = false
	game._trigger(0, 1.0)
	check(game.session.count(0) == 2, "held trigger cannot leak through pause")
	game.paused = true
	game.player.position = Vector3(0, 0.02, 10.5)
	game.player.rotation.y = PI
	var dropped: int = game.session.selected_id()
	game._drop()
	check(game.session.items[dropped].owner == "world" and game.session.items[dropped].position[2] >= 9.0, "entrance safe-drop fallback")
	game._show_menu()
	check(root.gui_get_focus_owner() is Button, "menu has explicit focus")
	var before: Dictionary = game.session.snapshot()
	var drop_event := InputEventJoypadButton.new()
	drop_event.button_index = JOY_BUTTON_B
	drop_event.pressed = true
	game._unhandled_input(drop_event)
	check(game.session.snapshot() == before, "menu B cannot leak safe drop")
	game._resume()
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and game.menu.visible, "focus loss pauses")
	game._resume()
	game._controller_changed(0, false)
	check(game.paused and game.menu.visible, "disconnect signal pauses")
	game._confirm_restart()
	check(root.gui_get_focus_owner().text == "Cancel", "restart defaults to cancel")
	game._show_settings(0)
	check(root.gui_get_focus_owner() is HSlider, "controller-focusable settings slider")
	var slider: HSlider = root.gui_get_focus_owner()
	slider.value = 0.004
	check(is_equal_approx(game.mouse_sensitivity, 0.004), "settings apply to live controller")
	game._restart()
	check(game.session.items.size() == 320 and game.session.high_water == 0 and is_equal_approx(game.mouse_sensitivity, 0.004), "real restart retains settings and resets run")
	game.settings.values = game.settings.DEFAULTS.duplicate()
	game._apply_settings()
	# Fresh and complete rendered screenshots, plus the shared variant models.
	game.session.fresh(42)
	game._rebuild_views()
	game.player.position = Layout.SPAWN
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3(-0.14, 0, 0)
	game._resume()
	game.paused = true
	game.toast.text = ""
	await physics_frame
	game._target()
	game._update_hud()
	await capture("shop-gameplay")
	game._show_menu()
	await capture("shop-menu")
	game._show_settings(0)
	await capture("shop-settings")
	game.menu.hide()
	for id in 320:
		game.session.try_pickup(id)
		game.session.try_deposit(id / 20)
	game._rebuild_views()
	game._update_hud()
	game._celebrate(Vector3(0, 2.5, 0), true)
	await capture("shop-complete")
	for bin in 12:
		game.session.try_retrieve(bin, 0)
	game._rebuild_views()
	game._update_hud()
	await capture("shop-inventory")
	check(game.session.inventory.size() == 12, "maximum mixed inventory integrates with HUD")
	# Finder must work in a fully mixed shop even with zero upgrades.
	game.session.fresh(42)
	for id in 320:
		game.session.try_pickup(id)
		game.session.try_deposit((id / 80) * 4 + id % 4)
	game._rebuild_views()
	game._find()
	check(game.finder_time > 0 and game.finder_description.begins_with("Mixed"), "mixed-display remaining assistance integrated")
	game.toast.hide()
	var gallery := Node3D.new()
	gallery.position.y = 5.0
	game.add_child(gallery)
	for variant in 16:
		var candy := Art.candy(gallery, variant)
		candy.position = Vector3(-1.35 + (variant % 4) * 0.9, 2.35 - (variant / 4) * 0.7, 30)
		game._label3d(gallery, Catalog.NAMES[variant], candy.position + Vector3(0, -0.07, 0), 23)
	game.player.position = Vector3(0, 5.02, 32.8)
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3.ZERO
	game.hud.hide()
	game.prompt.hide()
	game.hud.get_parent().hide()
	for child in game.get_children():
		if child is Node3D and not child is Light3D and child != gallery and child != game.player:
			child.hide()
	await capture("candy-variants")
	print("SCENE SMOKE: %d checks, %d failures; controller devices: %s" % [checks, failures, str(Input.get_connected_joypads())])
	game.quitting = true
	quit(1 if failures else 0)
