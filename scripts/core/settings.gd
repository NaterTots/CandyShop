class_name CandySettings
extends RefCounted

const PATH: String = "user://settings.cfg"
const DEFAULTS: Dictionary = {"mouse": 0.0025, "stick": 2.2, "deadzone": 0.2, "invert_y": false, "master": 0.8, "music": 0.3, "effects": 0.7, "fullscreen": false, "fov": 75.0}
const RANGES: Dictionary = {"mouse": Vector2(0.0005, 0.008), "stick": Vector2(0.5, 5.0), "deadzone": Vector2(0.1, 0.4), "master": Vector2(0, 1), "music": Vector2(0, 1), "effects": Vector2(0, 1), "fov": Vector2(60, 100)}
var values: Dictionary = DEFAULTS.duplicate()

func read(path: String = PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for key in DEFAULTS:
		var value: Variant = config.get_value("settings", key, DEFAULTS[key])
		if DEFAULTS[key] is bool:
			if value is bool:
				values[key] = value
		elif (value is float or value is int) and is_finite(float(value)):
			values[key] = clampf(float(value), RANGES[key].x, RANGES[key].y)

func write(path: String = PATH) -> bool:
	var config := ConfigFile.new()
	for key in values:
		config.set_value("settings", key, values[key])
	if config.save(path + ".tmp") != OK:
		return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK
