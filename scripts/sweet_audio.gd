class_name SweetAudio
extends Node

var effects: AudioStreamPlayer
var music: AudioStreamPlayer
var celebration: AudioStreamPlayer
var tones: Dictionary = {}

func _ready() -> void:
	for name: String in ["Music", "Effects"]:
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, name)
	effects = AudioStreamPlayer.new()
	effects.bus = "Effects"
	add_child(effects)
	celebration = AudioStreamPlayer.new()
	celebration.bus = "Effects"
	add_child(celebration)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	tones["pickup"] = _tone([660.0], 0.1)
	tones["place"] = _tone([523.25], 0.12)
	tones["complete"] = _tone([523.25, 659.25, 783.99], 0.18)
	tones["finish"] = _tone([523.25, 659.25, 783.99, 1046.5], 0.3)
	var loop := _tone([261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 349.23], 1.2)
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = loop.data.size() / 2
	music.stream = loop
	music.volume_db = -18.0
	if DisplayServer.get_name() != "headless":
		music.play()

func play(kind: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Continue/retrieval must not cut off the reward chime halfway through.
	if kind in ["complete", "finish"]:
		celebration.stream = tones[kind]
		celebration.play()
		return
	effects.stream = tones[kind]
	effects.pitch_scale = randf_range(0.96, 1.04) if kind in ["pickup", "place"] else 1.0
	effects.play()

func _exit_tree() -> void:
	music.stop()
	effects.stop()
	celebration.stop()
	music.stream = null
	effects.stream = null
	celebration.stream = null
	tones.clear()

func apply(settings: Dictionary) -> void:
	for pair: Array in [["Master", "master"], ["Music", "music"], ["Effects", "effects"]]:
		var bus := AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.0001, settings[pair[1]])))
		AudioServer.set_bus_mute(bus, settings[pair[1]] <= 0.0)

func _tone(notes: Array, length: float) -> AudioStreamWAV:
	var rate: int = 22050
	var samples: int = int(rate * length * notes.size())
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var time := float(i) / rate
		var step := mini(int(time / length), notes.size() - 1)
		var local := fmod(time, length)
		var envelope := minf(local * 80.0, 1.0) * pow(1.0 - local / length, 2.5)
		var wave := sin(TAU * notes[step] * local) + 0.2 * sin(TAU * notes[step] * 2 * local)
		data.encode_s16(i * 2, int(wave * envelope * 6500))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = data
	return sound
