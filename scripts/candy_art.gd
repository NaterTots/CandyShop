class_name CandyArt
extends RefCounted

const Catalog = preload("res://resources/candy/catalog.gd")
static var prefabs: Dictionary = {}
static var materials: Dictionary = {}

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key := color.to_html() + str(glow)
	if materials.has(key):
		return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	mat.emission_enabled = glow
	mat.emission = color
	mat.emission_energy_multiplier = 0.45
	materials[key] = mat
	return mat

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = shape
	view.position = pos
	view.material_override = mat
	parent.add_child(view)
	return view

static func box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, pos, mat)

static func candy(parent: Node3D, variant: int) -> Node3D:
	if not prefabs.has(variant):
		var template := _build(variant)
		var pack := PackedScene.new()
		for child in template.get_children():
			child.owner = template
		pack.pack(template)
		template.free()
		prefabs[variant] = pack
	var root: Node3D = prefabs[variant].instantiate()
	parent.add_child(root)
	return root

static func center(variant: int) -> Vector3:
	return Vector3(0, 0.39 if Catalog.family(variant) == 0 else 0.22, 0)

static func _build(variant: int) -> Node3D:
	var root := Node3D.new()
	var family := Catalog.family(variant)
	var mat := material(Catalog.COLORS[variant])
	var cream := material(Color("fff3ce"))
	var label_size := Vector2(0.26, 0.26)
	var face_z: float = 0.079
	var center_y: float = 0.39
	match family:
		0:
			box(root, Vector3(0.043, 0.34, 0.043), Vector3(0, 0.13, 0), cream)
			var sphere := SphereMesh.new()
			sphere.radius = 0.17
			sphere.height = 0.34
			var head := mesh(root, sphere, Vector3(0, 0.39, 0), mat)
			head.scale.z = 0.46
		1:
			var sphere := SphereMesh.new()
			sphere.radius = 0.16
			sphere.height = 0.32
			var body := mesh(root, sphere, Vector3(0, 0.22, 0), mat)
			body.scale = Vector3(1.3, 0.8, 0.85)
			for side: float in [-1.0, 1.0]:
				var twist := CylinderMesh.new()
				twist.top_radius = 0.035
				twist.bottom_radius = 0.11
				twist.height = 0.16
				twist.radial_segments = 6
				var end := mesh(root, twist, Vector3(side * 0.245, 0.22, 0), mat)
				end.rotation.z = side * PI / 2.0
				box(root, Vector3(0.025, 0.13, 0.13), Vector3(side * 0.17, 0.22, 0), cream)
			label_size = Vector2(0.27, 0.20)
			center_y = 0.22
			face_z = 0.139
		2:
			# Long, thin wrapped chocolate slab with cocoa ends, unlike the chunky carton.
			box(root, Vector3(0.46, 0.13, 0.12), Vector3(0, 0.22, 0), material(Color("563329")))
			box(root, Vector3(0.37, 0.135, 0.125), Vector3(0, 0.22, 0), mat)
			label_size = Vector2(0.36, 0.12)
			center_y = 0.22
			face_z = 0.064
		3:
			# Six-sided gift carton: chunky silhouette and a flavor-colored lid/base.
			for section in [[0.185, 0.30, 0.22], [0.198, 0.035, 0.385], [0.198, 0.035, 0.055]]:
				var carton := CylinderMesh.new()
				carton.top_radius = section[0]
				carton.bottom_radius = section[0]
				carton.height = section[1]
				carton.radial_segments = 6
				var section_mesh := mesh(root, carton, Vector3(0, section[2], 0), mat)
				section_mesh.rotation.y = PI / 6.0
			label_size = Vector2(0.17, 0.23)
			center_y = 0.22
			face_z = 0.162
	var label_material := StandardMaterial3D.new()
	label_material.albedo_texture = _wrapper(variant)
	label_material.roughness = 0.8
	label_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if family == 0:
		label_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	for side: float in [-1.0, 1.0]:
		var quad := QuadMesh.new()
		quad.size = label_size
		var face := mesh(root, quad, Vector3(0, center_y, face_z * side), label_material)
		face.rotation.y = 0.0 if side > 0.0 else PI
	if family >= 2:
		for side: float in [-1.0, 1.0]:
			var cap := QuadMesh.new()
			cap.size = Vector2(0.36, 0.12) if family == 2 else Vector2(0.22, 0.22)
			var height: float = (0.289 if side > 0 else 0.151) if family == 2 else (0.404 if side > 0 else 0.036)
			var face := mesh(root, cap, Vector3(0, height, 0), label_material)
			face.rotation.x = -side * PI / 2.0
	return root

static func _wrapper(variant: int) -> ImageTexture:
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var color := Catalog.COLORS[variant]
	var ink := Color("392c4b")
	var cream := Color("fff7df")
	var pattern := variant % 4
	for y in 96:
		for x in 96:
			var base := color
			var mark: bool = false
			match pattern:
				0: mark = (x + y) % 24 < 6
				1: mark = Vector2(x % 24 - 12, y % 24 - 12).length() < 4.5
				2: mark = ((x / 14) + (y / 14)) % 2 == 0
				3: mark = posmod(y - absi(x % 32 - 16), 22) < 6
			if mark:
				base = color.lightened(0.55)
			var p := Vector2(x - 47.5, y - 47.5) / 27.0
			if p.length() < 1.05:
				base = cream
			var icon: bool = false
			match pattern:
				0:
					var h := Vector2(p.x * 1.5, -p.y * 1.5 + 0.25)
					icon = pow(h.x * h.x + h.y * h.y - 0.55, 3) - h.x * h.x * h.y * h.y * h.y < 0.0
				1: icon = p.length() < 0.4 or (p.length() < 0.78 and p.length() > 0.52 and absf(sin(p.angle() * 6)) > 0.7)
				2: icon = absf(p.x) + absf(p.y) < 0.82
				3: icon = p.length() < 0.55 + 0.22 * cos(p.angle() * 5.0 - PI / 2.0)
			if icon and p.length() < 0.95:
				base = ink
			if Catalog.family(variant) == 0 and Vector2(x - 47.5, y - 47.5).length() > 47.0:
				base.a = 0.0
			img.set_pixel(x, y, base)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
