extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://docs/GODOT-NOTICES.txt", FileAccess.WRITE)
	file.store_string(Engine.get_license_text() + "\n\nTHIRD-PARTY COMPONENTS\n")
	for component in Engine.get_copyright_info():
		file.store_string("\n" + component.name + "\n")
		for part in component.parts:
			file.store_string("Files: " + ", ".join(part.files) + "\n")
			file.store_string("Copyright: " + "; ".join(part.copyright) + "\nLicense: " + part.license + "\n")
	var licenses := Engine.get_license_info()
	for name in licenses:
		file.store_string("\n" + name + "\n" + licenses[name] + "\n")
	file.close()
	quit()
