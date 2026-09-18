class_name CandySave
extends RefCounted

const PATH: String = "user://shop_save.json"

static func write(session: CandySession, player: Dictionary, path: String = PATH) -> bool:
	var data := session.snapshot()
	var probe := CandySession.new()
	if not probe.restore(data):
		return false
	data.player = player
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "", true, true))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		var prior := read(path)
		if not prior.is_empty():
			if DirAccess.copy_absolute(path, path + ".bak") != OK:
				return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

static func read(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return {}
	var probe := CandySession.new()
	if not probe.restore(parsed):
		return {}
	if parsed.has("player"):
		var player: Variant = parsed.player
		if not player is Dictionary:
			return {}
		for axis: String in ["yaw", "pitch"]:
			var value: Variant = player.get(axis, 0.0)
			if not (value is int or value is float) or not is_finite(float(value)):
				return {}
		if player.has("position"):
			if not player.position is Array or player.position.size() != 3:
				return {}
			for value in player.position:
				if not (value is int or value is float) or not is_finite(float(value)):
					return {}
	return parsed
