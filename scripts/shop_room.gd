class_name ShopRoom
extends RefCounted

const Layout = preload("res://scripts/core/shop_layout.gd")
const Art = preload("res://scripts/candy_art.gd")
const Catalog = preload("res://resources/candy/catalog.gd")

static func build(game: Node3D) -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("cde7e7")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff8ed")
	env.ambient_light_energy = 0.55
	environment.environment = env
	game.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 0.15
	light.shadow_enabled = true
	game.add_child(light)
	game._box(game, Vector3(18, 0.2, 22), Vector3(0, -0.1, 0), Color("f5e6cb"), true)
	for x in 18:
		for z in 22:
			if (x + z) % 2 == 0:
				game._box(game, Vector3(0.99, 0.008, 0.99), Vector3(x - 8.5, 0.004, z - 10.5), Color("e3eeDF"))
	for x: float in [-9.0, 9.0]:
		game._box(game, Vector3(0.2, 3.8, 22), Vector3(x, 1.9, 0), Color("fce7d9"), true)
		game._box(game, Vector3(0.24, 0.78, 22), Vector3(x, 0.39, 0), Color("43bbb6"))
		game._box(game, Vector3(0.26, 0.08, 22), Vector3(x, 0.82, 0), Color("ffcf4d"))
	for z: float in [-11.0, 11.0]:
		game._box(game, Vector3(18, 3.8, 0.2), Vector3(0, 1.9, z), Color("fce7d9"), true)
		game._box(game, Vector3(18, 0.8, 0.24), Vector3(0, 0.4, z), Color("43bbb6"))
	var ceiling: MeshInstance3D = game._box(game, Vector3(18, 0.1, 22), Vector3(0, 3.8, 0), Color("fff1d8"))
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for z: float in [-8.0, -3.0, 2.0, 7.0]:
		game._box(game, Vector3(17.8, 0.12, 0.15), Vector3(0, 3.64, z), Color("ffc957"))
		for x: float in [-4.5, 4.5]:
			var shade := CylinderMesh.new()
			shade.top_radius = 0.25
			shade.bottom_radius = 0.45
			shade.height = 0.28
			Art.mesh(game, shade, Vector3(x, 3.35, z), Art.material(Color("ffda82"), true))
	# Locked front door and decorative window panels.
	game._box(game, Vector3(1.8, 2.6, 0.13), Vector3(0, 1.3, 10.85), Color("236e84"))
	game._box(game, Vector3(1.48, 1.6, 0.04), Vector3(0, 1.65, 10.76), Color("9ce3e1"))
	game._box(game, Vector3(0.08, 0.4, 0.12), Vector3(0.56, 1.0, 10.68), Color("ffd448"))
	game._label3d(game, "CLOSED · MAKE YOURSELF AT HOME", Vector3(0, 2.95, 10.65), 30)
	for x: float in [-5.4, 5.4]:
		game._box(game, Vector3(4.0, 1.75, 0.08), Vector3(x, 2.0, 10.83), Color("81d3de"))
		for offset: float in [-1.9, 0.0, 1.9]:
			game._box(game, Vector3(0.09, 1.85, 0.1), Vector3(x + offset, 2.0, 10.75), Color("fff5d9"))
	# Long rear counter and accessible employee aisle.
	game._box(game, Vector3(13.4, 0.93, 1.2), Vector3(-1.1, 0.465, -8.0), Color("35b9b1"), true)
	game._box(game, Vector3(13.6, 0.10, 1.32), Vector3(-1.1, 0.98, -8.0), Color("fff2ce"))
	for x: float in [-6.0, -3.0, 0.0, 3.0]:
		game._box(game, Vector3(2.4, 0.57, 0.035), Vector3(x, 0.46, -7.38), Color("8bdad0"))
	game._box(game, Vector3(7.0, 1.1, 0.08), Vector3(-1.0, 2.5, -10.82), Color("c7437e"))
	game._label3d(game, "C A N D Y   S H O P", Vector3(-1, 2.65, -10.66), 80)
	game._label3d(game, "a little color, a little order", Vector3(-1, 2.2, -10.64), 34)
	for index in 14:
		game._box(game, Vector3(0.49, 0.25, 0.52), Vector3(-4.25 + index * 0.5, 3.25, -10.65), Color("fff1d3") if index % 2 else Color("e95691"))
	# Two diamond kiosks; all four family destinations remain flavor-neutral.
	for family in 2:
		var center := Layout.KIOSKS[family]
		var base: MeshInstance3D = game._box(game, Vector3(4.0, 0.78, 4.0), center + Vector3(0, 0.39, 0), Color("43bdb7") if family == 0 else Color("da6b9b"), true)
		base.rotation.y = Layout.KIOSK_YAW
		var top: MeshInstance3D = game._box(game, Vector3(4.04, 0.08, 4.04), center + Vector3(0, 0.82, 0), Color("fff2d1"))
		top.rotation.y = Layout.KIOSK_YAW
		var sculpture := Art.candy(game, family * 4)
		sculpture.position = center + Vector3(0, 1.8, 0)
		sculpture.scale = Vector3.ONE * 1.7
		# Sculpture is one family sign, never a requested flavor destination.
		game._label3d(game, Catalog.FAMILIES[family].to_upper(), center + Vector3(0, 2.85, 0), 40)
	for bin in 16:
		_build_display(game, bin)
	game._box(game, Vector3(8.2, 0.012, 1.8), Vector3(0, 0.014, 9.65), Color("b4ded8"))
	game._label3d(game, "RECOVERY MAT · SAFE DROPS", Vector3(0, 0.25, 10.6), 28)

static func _build_display(game: Node3D, bin: int) -> void:
	var pos := Layout.destination_position(bin)
	var yaw := Layout.destination_yaw(bin)
	var frame := Node3D.new()
	frame.position = pos
	frame.rotation.y = yaw
	game.add_child(frame)
	var rim: MeshInstance3D
	if bin < 8:
		var width: float = Layout.BIN_SIZE
		rim = game._box(frame, Vector3(width, 0.045, width), Vector3.ZERO, Color("fff2d1"))
		for side: float in [-1.0, 1.0]:
			game._box(frame, Vector3(0.035, 0.12, width), Vector3(side * width / 2.0, 0.045, 0), Color("f2c676"))
		game._box(frame, Vector3(width, 0.10, 0.035), Vector3(0, 0.035, width / 2.0), Color("f2c676"))
		for slot in 20:
			var local := Basis(Vector3.UP, -yaw) * (Layout.slot_position(bin, slot) - pos)
			game._box(frame, Vector3(0.13, 0.018, 0.13), local - Vector3(0, 0.015, 0), Color("9eb4b1"))
	else:
		game._box(game, Vector3(0.75, 0.44, 1.86), Vector3(pos.x, 0.22, pos.z), Color("49bab6"), true)
		var back: MeshInstance3D = game._box(frame, Vector3(1.86, 1.7, 0.1), Vector3(0, 0.67, -0.32), Color("ffdba6"), true)
		back.name = "ShelfBack"
		for side: float in [-1.0, 1.0]:
			game._box(frame, Vector3(0.075, 1.7, 0.8), Vector3(side * 0.9, 0.67, 0.02), Color("fff2d1"))
		for row in 4:
			game._box(frame, Vector3(1.83, 0.035, 0.74), Vector3(0, row * 0.32 - 0.025, 0), Color("fff2d1"))
		rim = game._box(frame, Vector3(1.86, 0.13, 0.8), Vector3(0, 1.52, 0), Color("fff2d1"))
		game._label3d(game, Catalog.FAMILIES[bin / 4].to_upper(), pos + Vector3(0, 1.83, 0), 24)
	game.rims.append(rim)
	var area := Area3D.new()
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta("bin", bin)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(Layout.BIN_SIZE, 0.09, Layout.BIN_SIZE) if bin < 8 else Vector3(1.75, 1.5, 0.05)
	collision.shape = shape
	area.position = Vector3.ZERO if bin < 8 else Vector3(0, 0.65, -0.22)
	area.add_child(collision)
	frame.add_child(area)
