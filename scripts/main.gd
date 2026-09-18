extends Node3D

const Session = preload("res://scripts/core/session.gd")
const Save = preload("res://scripts/core/save_service.gd")
const Catalog = preload("res://resources/candy/catalog.gd")
const Layout = preload("res://scripts/core/shop_layout.gd")
const Art = preload("res://scripts/candy_art.gd")
const Room = preload("res://scripts/shop_room.gd")
const Settings = preload("res://scripts/core/settings.gd")
const Sounds = preload("res://scripts/sweet_audio.gd")
var session: CandySession = Session.new()
var player: CharacterBody3D
var camera: Camera3D
var views: Node3D
var preview: Node3D
var hud: Label
var upgrade_label: Label
var upgrade_bar: ProgressBar
var prompt: Label
var crosshair: Label
var toast: Label
var menu: PanelContainer
var menu_box: VBoxContainer
var paused: bool = true
var target: Dictionary = {}
var joy_mode: bool = false
var trigger_down: Array[bool] = [false, false]
var toast_time: float = 0.0
var save_delay: float = -1.0
var ready_to_save: bool = false
var quitting: bool = false
var rims: Array[MeshInstance3D] = []
var solids: Array[Rect2] = []
var mouse_sensitivity: float = 0.0025
var stick_sensitivity: float = 2.2
var deadzone: float = 0.2
var settings: CandySettings = Settings.new()
var sounds: SweetAudio
var view_nodes: Dictionary = {}
var preview_id: int = -2
var menu_page: String = "pause"
var finder_point: Vector3 = Vector3.ZERO
var finder_time: float = 0.0
var finder_description: String = ""
var test_mode: bool = false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	settings.read()
	_setup_input()
	_build_room()
	_build_player()
	_build_ui()
	DisplayServer.window_set_title("Candy Shop")
	sounds = Sounds.new()
	add_child(sounds)
	_apply_settings()
	Input.joy_connection_changed.connect(_controller_changed)
	var data := Save.read()
	var recovery: String = ""
	if data.is_empty() and (FileAccess.file_exists(Save.PATH) or FileAccess.file_exists(Save.PATH + ".bak")):
		data = Save.read(Save.PATH + ".bak")
		recovery = "Recovered backup save." if not data.is_empty() else "Save could not be read. Start a new run to replace it."
	if not data.is_empty():
		session.restore(data)
		_restore_player(data.get("player", {}))
		ready_to_save = true
	else:
		session.fresh(randi())
		ready_to_save = recovery.is_empty()
		if ready_to_save:
			_save()
	_rebuild_views()
	if recovery.is_empty() and data.is_empty() and FileAccess.file_exists("user://slice_save.json"):
		recovery = "Welcome to the full shop. Your accepted slice save is preserved separately."
	_show_menu("Candy Shop", true, recovery)

func _setup_input() -> void:
	var keys: Dictionary = {"forward": KEY_W, "backward": KEY_S, "left": KEY_A, "right": KEY_D, "previous": KEY_Q, "next": KEY_E, "drop": KEY_G, "pause_game": KEY_ESCAPE, "find": KEY_F}
	for action: String in keys:
		InputMap.add_action(action, deadzone)
		var key := InputEventKey.new()
		key.physical_keycode = keys[action]
		InputMap.action_add_event(action, key)
	for definition: Array in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["forward", JOY_AXIS_LEFT_Y, -1.0], ["backward", JOY_AXIS_LEFT_Y, 1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = definition[1]
		axis.axis_value = definition[2]
		InputMap.action_add_event(definition[0], axis)
	for definition: Array in [["previous", JOY_BUTTON_LEFT_SHOULDER], ["next", JOY_BUTTON_RIGHT_SHOULDER], ["drop", JOY_BUTTON_B], ["pause_game", JOY_BUTTON_START], ["find", JOY_BUTTON_Y]]:
		var button := InputEventJoypadButton.new()
		button.button_index = definition[1]
		InputMap.action_add_event(definition[0], button)
	for definition: Array in [["primary", MOUSE_BUTTON_LEFT], ["retrieve", MOUSE_BUTTON_RIGHT], ["previous", MOUSE_BUTTON_WHEEL_UP], ["next", MOUSE_BUTTON_WHEEL_DOWN]]:
		if not InputMap.has_action(definition[0]):
			InputMap.add_action(definition[0])
		var mouse := InputEventMouseButton.new()
		mouse.button_index = definition[1]
		InputMap.action_add_event(definition[0], mouse)
	for definition: Array in [["primary", JOY_AXIS_TRIGGER_RIGHT], ["retrieve", JOY_AXIS_TRIGGER_LEFT]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = definition[1]
		axis.axis_value = 1.0
		InputMap.action_add_event(definition[0], axis)

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
	return Art.material(color, glow)

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = pos
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		collision.shape = box
		body.add_child(collision)
		mesh.add_child(body)
		if size.y > 0.3:
			solids.append(Rect2(Vector2(pos.x - size.x / 2.0, pos.z - size.z / 2.0), Vector2(size.x, size.z)))
	return mesh

func _label3d(parent: Node3D, title: String, pos: Vector3, font_size: int = 40) -> void:
	var label := Label3D.new()
	label.text = title
	label.position = pos
	label.font_size = font_size
	label.pixel_size = 0.005
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)

func _build_room() -> void:
	Room.build(self)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Layout.SPAWN
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.7
	collision.shape = capsule
	collision.position.y = 0.85
	player.add_child(collision)
	add_child(player)
	camera = Camera3D.new()
	camera.position.y = 1.6
	camera.fov = 75
	camera.current = true
	player.add_child(camera)
	preview = Node3D.new()
	preview.position = Vector3(0.48, -0.32, -0.85)
	preview.scale = Vector3.ONE * 0.6
	camera.add_child(preview)

func _candy(parent: Node3D, variant: int) -> Node3D:
	return Art.candy(parent, variant)

func _slot_position(bin: int, slot: int) -> Vector3:
	return Layout.slot_position(bin, slot)

func _rebuild_views(animated_id: int = -1) -> void:
	if not is_instance_valid(views):
		views = Node3D.new()
		add_child(views)
	var owners: Dictionary = {}
	for bin in session.bins.size():
		for slot in Session.SLOTS:
			var id: int = session.bins[bin][slot]
			if id >= 0:
				owners[id] = Vector2i(bin, slot)
	for id in session.items.size():
		var item: Dictionary = session.items[id]
		if item.owner == "inventory":
			if view_nodes.has(id):
				views.remove_child(view_nodes[id])
				view_nodes[id].queue_free()
				view_nodes.erase(id)
			continue
		var variant: int = item.variant
		var bin: int = owners[id].x if owners.has(id) else -1
		var slot: int = owners[id].y if owners.has(id) else -1
		var pos := Vector3(item.position[0], item.position[1], item.position[2]) if bin < 0 else _slot_position(bin, slot)
		var rotation: Array = item.get("rotation", [-1.134464, 0.0, 0.0])
		var signature := str([bin, slot, pos, rotation])
		if view_nodes.has(id) and view_nodes[id].get_meta("signature", "") == signature:
			continue
		var candy: Node3D
		if view_nodes.has(id):
			candy = view_nodes[id]
		else:
			candy = _candy(views, variant)
			view_nodes[id] = candy
			var area := Area3D.new()
			area.name = "Target"
			area.collision_layer = 2
			area.collision_mask = 0
			area.set_meta("item", id)
			var collision := CollisionShape3D.new()
			var shape := SphereShape3D.new()
			shape.radius = 0.19 if Catalog.family(variant) == 0 else 0.18
			collision.shape = shape
			collision.position = Art.center(variant)
			area.add_child(collision)
			candy.add_child(area)
		candy.set_meta("signature", signature)
		var area: Area3D = candy.get_node("Target")
		area.set_meta("bin", bin)
		area.set_meta("slot", slot)
		candy.position = pos
		candy.rotation = Vector3(rotation[0], rotation[1], rotation[2]) if bin < 0 else Vector3(0, Layout.destination_yaw(bin), 0)
		var size: float = (0.8 if Catalog.family(variant) == 1 else 1.0) if bin < 0 else (0.43 if bin < 8 and bin >= 4 else 0.65)
		candy.scale = Vector3.ONE * size
		if id == animated_id:
			candy.scale *= 0.6
			create_tween().tween_property(candy, "scale", Vector3.ONE * size, 0.16)
	if preview_id != session.selected_id():
		preview_id = session.selected_id()
		for child in preview.get_children():
			preview.remove_child(child)
			child.queue_free()
		if preview_id >= 0:
			var candy := _candy(preview, int(session.items[preview_id].variant))
			for mesh in candy.get_children():
				if mesh is MeshInstance3D:
					mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			candy.rotation_degrees.z = -18
			candy.scale = Vector3.ONE * 0.65
			create_tween().tween_property(candy, "scale", Vector3.ONE, 0.15)
	for bin in session.bins.size():
		rims[bin].material_override = _material(Color("78ecc6") if session.complete(bin) else Color("fff2d1"), session.complete(bin))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 23)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(hud)
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color("242c3bdc")
	hud_style.set_content_margin_all(12)
	hud.add_theme_stylebox_override("normal", hud_style)
	upgrade_label = Label.new()
	upgrade_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	upgrade_label.position = Vector2(-350, 20)
	upgrade_label.size = Vector2(326, 138)
	upgrade_label.add_theme_font_size_override("font_size", 19)
	upgrade_label.add_theme_stylebox_override("normal", hud_style)
	root.add_child(upgrade_label)
	upgrade_bar = ProgressBar.new()
	upgrade_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	upgrade_bar.position = Vector2(-338, 136)
	upgrade_bar.size = Vector2(302, 10)
	upgrade_bar.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("242c3b")
	track.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ffcf59")
	fill.set_corner_radius_all(5)
	upgrade_bar.add_theme_stylebox_override("background", track)
	upgrade_bar.add_theme_stylebox_override("fill", fill)
	upgrade_bar.size.y = 10
	root.add_child(upgrade_bar)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(7, 15)
	crosshair.add_theme_font_size_override("font_size", 26)
	crosshair.add_theme_color_override("font_outline_color", Color("242c3b"))
	crosshair.add_theme_constant_override("outline_size", 5)
	root.add_child(crosshair)
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-550, -135)
	prompt.size = Vector2(1100, 110)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 2)
	prompt.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(prompt)
	prompt.add_theme_stylebox_override("normal", hud_style)
	toast = Label.new()
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2(-500, 185)
	toast.size.x = 1000
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 25)
	toast.add_theme_color_override("font_outline_color", Color("242c3b"))
	toast.add_theme_constant_override("outline_size", 6)
	root.add_child(toast)
	menu = PanelContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.position = Vector2(-330, -340)
	menu.custom_minimum_size = Vector2(660, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("242c3bf5")
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	menu.add_theme_stylebox_override("panel", style)
	root.add_child(menu)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 9)
	menu.add_child(menu_box)

func _menu_label(text: String, size: int = 22) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 550
	menu_box.add_child(label)

func _button(title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 44
	button.add_theme_font_size_override("font_size", 22)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color("405778")
	focus.border_color = Color("ffe076")
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	menu_box.add_child(button)
	return button

func _clear_menu() -> void:
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	paused = true
	menu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _show_menu(title: String = "Paused", initial: bool = false, note: String = "") -> void:
	_clear_menu()
	menu_page = "pause"
	_menu_label(title, 30)
	_menu_label("320 sweets. Four families. Choose each display's flavor yourself. Full matching displays glow; mixtures are always reversible.", 19)
	_menu_label("WASD / left stick: walk · mouse / right stick: look\nClick / RT: pick up or place · right click / LT: retrieve\nQ/E, wheel / LB/RB: select · G / B: safe drop\nF / Y: find candy · Esc / Start: pause", 17)
	if not note.is_empty():
		_menu_label(note, 17)
	var first: Button
	if ready_to_save:
		first = _button("Continue" if initial else "Resume", _resume)
	else:
		first = _button("Start new run", _confirm_restart)
	_button("Find mode: " + ("remaining (at 32 or fewer)" if session.find_remaining else "matching flavor"), _toggle_finder)
	_button("Settings…", func() -> void: _show_settings(0))
	_button("Restart…", _confirm_restart)
	_button("Save and quit" if ready_to_save else "Quit", _quit)
	first.grab_focus()
	if not initial:
		_save()

func _resume() -> void:
	paused = false
	menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _confirm_restart() -> void:
	_clear_menu()
	menu_page = "restart"
	_menu_label("Restart this shop?", 30)
	_menu_label("This replaces the current run with 320 freshly shuffled pieces. All displays, held pieces, and upgrades reset. Your settings stay the same.")
	_button("Cancel", func() -> void: _show_menu()).grab_focus()
	_button("Restart with 320 pieces", _restart)

func _restart() -> void:
	for effect in get_tree().get_nodes_in_group("transient_feedback"):
		effect.queue_free()
	session.fresh(randi())
	finder_time = 0.0
	preview_id = -2
	player.position = Layout.SPAWN
	player.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	ready_to_save = true
	_rebuild_views()
	_save()
	_resume()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		joy_mode = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.35:
		joy_mode = true
	elif event is InputEventMouseMotion and event.relative.length() > 2.0 or event is InputEventKey:
		joy_mode = false
	if event.is_action_pressed("pause_game"):
		if paused and menu_page in ["settings", "restart"]:
			_show_menu()
		elif paused and ready_to_save:
			_resume()
		elif not paused:
			_show_menu()
		get_viewport().set_input_as_handled()
		return
	if paused:
		if event.is_action_pressed("ui_cancel"):
			_show_menu()
		return
	if event is InputEventMouseMotion:
		player.rotation.y -= event.relative.x * mouse_sensitivity
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * mouse_sensitivity * (-1.0 if settings.values.invert_y else 1.0), -1.35, 1.35)
	if event is InputEventJoypadMotion:
		# Trigger edges are sampled with hysteresis in physics; no repeated jitter actions.
		return
	if event.is_action_pressed("primary"):
		_interact(false)
	elif event.is_action_pressed("retrieve"):
		_interact(true)
	elif event.is_action_pressed("previous"):
		_select(-1)
	elif event.is_action_pressed("next"):
		_select(1)
	elif event.is_action_pressed("drop"):
		_drop()
	elif event.is_action_pressed("find"):
		_find()

func _physics_process(delta: float) -> void:
	var devices := Input.get_connected_joypads()
	for index in 2:
		var amount: float = 0.0
		for device in devices:
			amount = maxf(amount, Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT if index == 0 else JOY_AXIS_TRIGGER_LEFT))
		_trigger(index, amount)
	if paused:
		return
	var look := Vector2.ZERO
	for device in devices:
		look += Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
	if look.length() > deadzone:
		look = look.limit_length() * ((minf(look.length(), 1.0) - deadzone) / (1.0 - deadzone))
		player.rotation.y -= look.x * stick_sensitivity * delta
		camera.rotation.x = clampf(camera.rotation.x - look.y * stick_sensitivity * delta * (-1.0 if settings.values.invert_y else 1.0), -1.35, 1.35)
	var movement := Input.get_vector("left", "right", "forward", "backward")
	var velocity := player.basis * Vector3(movement.x, 0, movement.y) * 3.5
	player.velocity.x = velocity.x
	player.velocity.z = velocity.z
	player.velocity.y = -2.0
	player.move_and_slide()
	_target()
	_update_hud()
	finder_time = maxf(0.0, finder_time - delta)
	if save_delay >= 0.0:
		save_delay -= delta
		if save_delay < 0.0:
			_save()
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast.text = ""

func _trigger(index: int, amount: float) -> void:
	if amount > 0.65 and not trigger_down[index]:
		trigger_down[index] = true
		if not paused:
			_interact(index == 1)
	elif amount < 0.25:
		trigger_down[index] = false

func _target() -> void:
	target = {}
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * session.reach(), 3, [player.get_rid()])
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is Area3D:
		var area: Area3D = hit.collider
		target = {"item": area.get_meta("item", -1), "bin": area.get_meta("bin", -1), "slot": area.get_meta("slot", -1)}

func _update_hud() -> void:
	# A neutral target cue confirms reach without judging a player's flavor choice.
	crosshair.text = "◇" if not target.is_empty() else "+"
	crosshair.modulate = Color("ffe076") if not target.is_empty() else Color.WHITE
	var next := session.next_upgrade()
	upgrade_label.text = "Next: " + next.label + "\n%d more complete %s\nBest: %d / %d" % [next.remaining, "display" if next.remaining == 1 else "displays", session.high_water, next.threshold] if next.remaining > 0 else "All upgrades unlocked\nCarry 12 · Reach 3 m\nMatching finder ready"
	upgrade_bar.max_value = next.threshold
	upgrade_bar.value = mini(session.high_water, next.threshold)
	var strip: String = ""
	for index in session.inventory.size():
		var variant: int = session.items[session.inventory[index]].variant
		var symbol: String = Catalog.SHORT[variant] + Catalog.ICONS[variant % 4]
		strip += (" [" + symbol + "] " if index == session.selected else " " + symbol + " ")
	hud.text = "CANDY SHOP\nHeld %d / %d   Displays %d / 16   Sorted %d / 320\n%s" % [session.inventory.size(), session.capacity(), session.progress(), session.progress() * 20, strip]
	if session.selected_id() >= 0:
		hud.text += "\n" + Catalog.describe(int(session.items[session.selected_id()].variant))
	if finder_time > 0.0:
		var direction := finder_point - player.position
		var angle := player.global_basis.z.signed_angle_to(-Vector3(direction.x, 0, direction.z).normalized(), Vector3.UP)
		var arrow: String = "Ahead" if absf(angle) < 0.3 else ("Turn around" if absf(angle) > 2.2 else ("← Left" if angle > 0 else "Right →"))
		hud.text += "\nFind: %s · %s · %.1f m" % [finder_description, arrow, direction.length()]
	var primary: String = "RT" if joy_mode else "Left click"
	var retrieve: String = "LT" if joy_mode else "Right click"
	var help: String = "LB/RB select · B safe drop · Y find · Start menu" if joy_mode else "Q/E or wheel select · G safe drop · F find · Esc menu"
	prompt.text = "Aim at candy or a family display · Reach %.0f m\n" % session.reach() + help
	if session.outside_count() <= 32 and session.progress() < 16:
		prompt.text = "Find remaining available · " + ("Y" if joy_mode else "F") + "\n" + help
	if target.is_empty():
		return
	var bin: int = target.bin
	var id: int = target.item
	var identity: String = Catalog.describe(int(session.items[id].variant)) if id >= 0 else Catalog.FAMILIES[bin / 4] + " · Any flavor"
	if bin >= 0:
		var status: String = "Complete!" if session.complete(bin) else ("Mixed varieties" if session.count(bin) == 20 else "Choose any flavor")
		prompt.text = "%s · %d/20 · %s\n%s place one · %s retrieve %s\n%s" % [identity, session.count(bin), status, primary, retrieve, "aimed piece" if id >= 0 else "latest piece", help]
	else:
		prompt.text = identity + "\n" + primary + " pick up one\n" + help

func _select(direction: int) -> void:
	session.select_inventory_item(session.selected + direction)
	_rebuild_views()
	save_delay = 0.3

func _interact(retrieve: bool) -> void:
	_target()
	if target.is_empty():
		_notify("Move closer and aim at a piece or display.")
		return
	var before: int = session.progress()
	var before_high: int = session.high_water
	var first_completion: bool = target.bin >= 0 and not target.bin in session.completed_once
	var id: int = session.selected_id()
	var result: String
	if retrieve:
		result = session.try_retrieve(target.bin, target.slot)
	elif target.bin >= 0:
		result = session.try_deposit(target.bin)
	else:
		id = target.item
		result = session.try_pickup(id)
	if not result.is_empty():
		_notify(result)
		return
	_rebuild_views(id)
	sounds.play("pickup" if retrieve or target.bin < 0 else "place")
	save_delay = 0.25
	finder_time = 0.0
	if session.progress() > before:
		_notify("Lovely! A full matching display.")
		if first_completion:
			sounds.play("complete")
			_celebrate(Layout.destination_position(target.bin), false)
	for threshold in [2, 4, 6, 10]:
		if before_high < threshold and session.high_water >= threshold:
			var messages: Dictionary = {2: "Roomier hands! Carry up to 8 pieces.", 4: "Longer reach! Interact from 3 meters.", 6: "Find matching candy unlocked! Press F / Y.", 10: "Roomier hands! Carry up to 12 pieces."}
			_notify(messages[threshold])
	if session.progress() == 16 and not session.celebrated:
		session.celebrated = true
		_save()
		sounds.play("finish")
		_celebrate(Vector3(0, 2.5, 0), true)
		_clear_menu()
		menu_page = "completion"
		_menu_label("A sweet little shop!", 34)
		_menu_label("All 320 pieces are organized. You chose the flavors. Enjoy your colorful shop, rearrange it, or start fresh.")
		_button("Keep admiring", _resume).grab_focus()
		_button("Restart…", _confirm_restart)

func _drop_clear(pos: Vector3) -> bool:
	if not Layout.floor_clear(pos):
		return false
	for item in session.items:
		if item.owner == "world" and absf(item.position[1] - pos.y) < 0.5:
			var point := Vector3(item.position[0], item.position[1], item.position[2])
			if Vector2(point.x - pos.x, point.z - pos.z).length() < 0.50:
				return false
	return true

func _drop() -> void:
	if session.selected_id() < 0:
		_notify("Your hands are empty.")
		return
	var forward: Vector3 = -player.global_basis.z
	var candidates: Array[Vector3] = []
	for offset: float in [0.0, -0.5, 0.5]:
		var pos := player.position + forward * 0.8 + player.global_basis.x * offset
		pos.y = 0.12
		# Local drops must also be visible, so they cannot cross furniture.
		var ray := PhysicsRayQueryParameters3D.create(camera.global_position, pos + Vector3(0, 0.15, 0), 1, [player.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			candidates.append(pos)
	var local_count := candidates.size()
	candidates.append_array(Layout.recovery_slots())
	for i in candidates.size():
		if _drop_clear(candidates[i]):
			var id := session.selected_id()
			session.try_drop_selected(candidates[i])
			_rebuild_views(id)
			save_delay = 0.25
			_notify("Placed in the entrance recovery area." if i >= local_count else "Placed safely on the floor.")
			return
	_notify("No space here.")

func _notify(message: String) -> void:
	toast.text = message
	toast_time = 3.5

func _save() -> bool:
	if not ready_to_save or test_mode:
		return true
	var pos := player.position
	if not Save.write(session, {"position": [pos.x, pos.y, pos.z], "yaw": player.rotation.y, "pitch": camera.rotation.x}):
		_notify("Save failed. Please check available disk space.")
		return false
	return true

func _restore_player(data: Dictionary) -> void:
	var pos: Variant = data.get("position", [])
	if pos is Array and pos.size() == 3:
		var valid: bool = true
		for axis in pos:
			valid = valid and (axis is float or axis is int) and is_finite(float(axis))
		if valid and Layout.floor_clear(Vector3(pos[0], 0.02, pos[2]), 0.27):
			player.position = Vector3(pos[0], 0.02, pos[2])
	var yaw: float = float(data.get("yaw", 0.0))
	var pitch: float = float(data.get("pitch", 0.0))
	player.rotation.y = yaw if is_finite(yaw) else 0.0
	camera.rotation.x = clampf(pitch, -1.35, 1.35) if is_finite(pitch) else 0.0

func _controller_changed(_device: int, connected: bool) -> void:
	if not connected:
		_show_menu("Controller disconnected")

func _notification(what: int) -> void:
	if not is_instance_valid(menu):
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not quitting:
		_show_menu("Paused · focus lost")
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit()

func _quit() -> void:
	if not _save():
		_show_menu("Save failed · your run is still open")
		return
	quitting = true
	get_tree().quit()

func _apply_settings() -> void:
	mouse_sensitivity = settings.values.mouse
	stick_sensitivity = settings.values.stick
	deadzone = settings.values.deadzone
	camera.fov = settings.values.fov
	for action: String in ["forward", "backward", "left", "right"]:
		InputMap.action_set_deadzone(action, deadzone)
	sounds.apply(settings.values)
	if not test_mode and DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)

func _persist_settings() -> void:
	_apply_settings()
	if not test_mode and not settings.write():
		_notify("Settings could not be saved. Check available disk space.")

func _show_settings(page: int, focus_toggle: bool = false) -> void:
	_clear_menu()
	menu_page = "settings"
	_menu_label(["Look settings", "Sound settings", "Display settings"][page], 30)
	_menu_label("D-pad up/down: choose · left/right: adjust · B: back", 17)
	var first: Control
	var toggle: Button
	match page:
		0:
			first = _setting_slider("Mouse sensitivity", "mouse", 0.0005, 0.008, 0.00025)
			_setting_slider("Controller look speed", "stick", 0.5, 5.0, 0.1)
			_setting_slider("Controller deadzone", "deadzone", 0.1, 0.4, 0.01)
			toggle = _button("Invert Y: " + ("On" if settings.values.invert_y else "Off"), func() -> void:
				settings.values.invert_y = not settings.values.invert_y
				_persist_settings()
				_show_settings(0, true))
		1:
			first = _setting_slider("Master volume", "master", 0.0, 1.0, 0.05)
			_setting_slider("Music volume", "music", 0.0, 1.0, 0.05)
			_setting_slider("Effects volume", "effects", 0.0, 1.0, 0.05)
			_button("Play a sample chime", func() -> void: sounds.play("complete"))
		2:
			first = _setting_slider("Field of view", "fov", 60.0, 100.0, 1.0)
			toggle = _button("Display: " + ("Fullscreen" if settings.values.fullscreen else "Windowed"), func() -> void:
				settings.values.fullscreen = not settings.values.fullscreen
				_persist_settings()
				_show_settings(2, true))
	_button(["Sound settings →", "Display settings →", "Look settings →"][page], func() -> void: _show_settings((page + 1) % 3))
	_button("Back", func() -> void: _show_menu())
	if focus_toggle and is_instance_valid(toggle):
		toggle.grab_focus()
	else:
		first.grab_focus()

func _setting_slider(title: String, key: String, low: float, high: float, step: float) -> HSlider:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 19)
	label.text = _setting_label(title, key, settings.values[key])
	menu_box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = settings.values[key]
	slider.custom_minimum_size.y = 30
	slider.focus_mode = Control.FOCUS_ALL
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color("46677b")
	focus.border_color = Color("ffe076")
	focus.set_border_width_all(2)
	slider.add_theme_stylebox_override("grabber_area_highlight", focus)
	slider.add_theme_stylebox_override("slider", focus)
	slider.value_changed.connect(func(value: float) -> void:
		settings.values[key] = value
		label.text = _setting_label(title, key, value)
		_persist_settings())
	slider.focus_entered.connect(func() -> void: label.modulate = Color("ffe076"))
	slider.focus_exited.connect(func() -> void: label.modulate = Color.WHITE)
	menu_box.add_child(slider)
	return slider

func _setting_label(title: String, key: String, value: float) -> String:
	if key == "mouse":
		return "%s: %.1f×" % [title, value / 0.0025]
	if key in ["master", "music", "effects", "deadzone"]:
		return "%s: %d%%" % [title, roundi(value * 100.0)]
	if key == "fov":
		return "%s: %d°" % [title, roundi(value)]
	return "%s: %.1f" % [title, value]

func _toggle_finder() -> void:
	session.find_remaining = not session.find_remaining
	_show_menu()
	# Keep focus on the toggled control for controller users.
	for child in menu_box.get_children():
		if child is Button and child.text.begins_with("Find mode:"):
			child.grab_focus()

func _find() -> void:
	var variant: int = -1
	var id := session.selected_id()
	if id < 0:
		_target()
		id = target.get("item", -1)
	if id >= 0:
		variant = int(session.items[id].variant)
	var answer := session.assistance(variant)
	match answer.mode:
		"remaining":
			var item: Dictionary = session.items[answer.item]
			finder_point = Vector3(item.position[0], item.position[1], item.position[2])
			finder_description = "Loose " + Catalog.NAMES[int(item.variant)]
			finder_time = 10.0
			_pulse([int(answer.item)])
		"mixed":
			finder_point = Layout.destination_position(answer.bin)
			finder_description = "Mixed " + Catalog.FAMILIES[answer.bin / 4] + " display"
			finder_time = 10.0
			_notify("All pieces are stored. Retrieve and rearrange this mixed display.")
		"carried": _notify("No loose pieces remain. Place the pieces in your hands.")
		"complete": _notify("Every display is complete. Enjoy your shop!")
		"locked": _notify("Matching finder unlocks at 6 complete displays. Remaining finder is always available at 32 or fewer outside displays.")
		"select": _notify("Select or aim at a candy flavor to find matching loose pieces.")
		"matching":
			_pulse(answer.items)
			_notify("%d loose pieces match %s." % [answer.items.size(), Catalog.NAMES[variant]])
			if not answer.items.is_empty():
				var item: Dictionary = session.items[answer.items[0]]
				finder_point = Vector3(item.position[0], item.position[1], item.position[2])
				finder_description = Catalog.NAMES[variant]
				finder_time = 6.0

func _pulse(ids: Array) -> void:
	for id in ids:
		var item: Dictionary = session.items[id]
		var marker := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.23
		ring.outer_radius = 0.27
		marker.mesh = ring
		marker.material_override = _material(Color("fff16a"), true)
		marker.position = Vector3(item.position[0], item.position[1] + 0.25, item.position[2])
		add_child(marker)
		marker.add_to_group("transient_feedback")
		var tween := create_tween().set_loops(3)
		tween.tween_property(marker, "scale", Vector3.ONE * 1.5, 0.4)
		tween.tween_property(marker, "scale", Vector3.ONE, 0.4)
		tween.finished.connect(marker.queue_free)

func _celebrate(pos: Vector3, whole_shop: bool) -> void:
	var particles := CPUParticles3D.new()
	particles.position = pos
	particles.amount = 180 if whole_shop else 28
	particles.lifetime = 3.0 if whole_shop else 1.4
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.direction = Vector3.UP
	particles.spread = 130.0
	particles.gravity = Vector3(0, -1.5, 0)
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 2.0
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(7.0, 0.3, 8.0) if whole_shop else Vector3(0.5, 0.1, 0.4)
	var shape := BoxMesh.new()
	shape.size = Vector3(0.06, 0.03, 0.09)
	particles.mesh = shape
	var confetti := StandardMaterial3D.new()
	confetti.albedo_color = Color.WHITE
	confetti.vertex_color_use_as_albedo = true
	confetti.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particles.material_override = confetti
	var gradient := Gradient.new()
	gradient.set_color(0, Color("ff468e"))
	gradient.set_color(1, Color("33d9ce"))
	gradient.add_point(0.5, Color("ffdc46"))
	particles.color_ramp = gradient
	add_child(particles)
	particles.add_to_group("transient_feedback")
	particles.emitting = true
	get_tree().create_timer(4.5).timeout.connect(particles.queue_free)
