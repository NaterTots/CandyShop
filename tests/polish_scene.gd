extends SceneTree

# Real viewport checks and short desktop frame samples; never writes player saves.
var game: Node3D
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(title)

func capture(title: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.get_size() == root.size, "rendered image fills requested resolution")
		image.save_png("res://docs/" + title + ".png")

func check_menu() -> void:
	await process_frame
	await process_frame
	var bounds := root.get_visible_rect()
	check(bounds.encloses(game.menu.get_global_rect()), "menu fits viewport")
	var controls: Array[Control] = []
	for child in game.menu_box.get_children():
		if child is Control and child.focus_mode == Control.FOCUS_ALL:
			controls.append(child)
	var first: Control = root.gui_get_focus_owner()
	check(first in controls, "visible menu owns focus")
	var visited: Array[Control] = []
	var current := first
	for i in controls.size():
		if current == null:
			break
		visited.append(current)
		current = current.find_next_valid_focus()
	check(visited.size() == controls.size() and current == first, "focus cycle stays inside menu")
	for control in controls:
		check(control in visited, "each menu control reachable")

func sample(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in 30:
		await process_frame
	var times: Array[float] = []
	var previous := Time.get_ticks_usec()
	for i in 180:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - previous) / 1000.0)
		previous = now
	var total: float = 0
	for value in times:
		total += value
	times.sort()
	print("FRAME SAMPLE %s: 180 frames, mean %.2f ms, p95 %.2f ms, max %.2f ms; draw calls %d" % [label, total / times.size(), times[170], times[-1], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	await process_frame
	game.settings.values = game.settings.DEFAULTS.duplicate()
	game._apply_settings()
	for resolution in [Vector2i(1280, 800), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		check(root.size == resolution, "requested physical viewport size")
		var suffix := "%dx%d" % [resolution.x, resolution.y]
		game.session.fresh(42)
		game._rebuild_views()
		game.player.position = game.Layout.SPAWN
		game.player.rotation = Vector3.ZERO
		game.camera.rotation = Vector3(-0.14, 0, 0)
		game._resume()
		game.toast.text = ""
		await capture("m3-floor-" + suffix)
		await sample("floor " + suffix)
		game._show_menu()
		await check_menu()
		await capture("m3-menu-" + suffix)
		for page in 3:
			game._show_settings(page)
			await check_menu()
			await capture("m3-settings-%d-" % page + suffix)
			if page != 1:
				var prefix: String = "Invert Y:" if page == 0 else "Display:"
				for child in game.menu_box.get_children():
					if child is Button and child.text.begins_with(prefix):
						child.pressed.emit()
						break
				check(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner().text.begins_with(prefix), "toggle retains focus")
		game._confirm_restart()
		await check_menu()
		await capture("m3-restart-" + suffix)
		game._resume()
		for id in 320:
			game.session.try_pickup(id)
			game.session.try_deposit(id / 20)
		game._rebuild_views()
		game._celebrate(Vector3(0, 2.5, 0), true)
		await capture("m3-celebration-" + suffix)
		await sample("filled + celebration " + suffix)
		for bin in 12:
			game.session.try_retrieve(bin, 0)
		game._rebuild_views()
		game._update_hud()
		await capture("m3-inventory-" + suffix)
		check(not game.hud.get_global_rect().intersects(game.upgrade_label.get_global_rect()), "maximum inventory clears upgrade panel")
		check(game.upgrade_bar.position.y >= game.upgrade_label.position.y + 110, "upgrade bar clears three text lines")
		check(root.get_visible_rect().encloses(game.prompt.get_global_rect()), "prompt fits viewport")
		game.target = {"item": 0, "bin": -1, "slot": -1}
		game._update_hud()
		check(game.crosshair.text == "◇", "reachable target has neutral aim cue")
		game.target = {}
		game._update_hud()
		check(game.crosshair.text == "+", "empty aim has default cue")
	print("POLISH SCENE: %d checks, %d failures; controller devices: %s" % [checks, failures, Input.get_connected_joypads()])
	game.quitting = true
	quit(1 if failures else 0)
