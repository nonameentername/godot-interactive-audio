extends Node2D

var random = RandomNumberGenerator.new()

@export
var brain_scene: PackedScene

@onready
var timer: Timer = $Timer

@onready
var spawn_location: PathFollow2D = $SpawnPath/SpawnLocation

var csound: CsoundInstance

var guitar_synth: Lv2Instance
var bass1_synth: Lv2Instance
var dirty_bass_synth: Lv2Instance
var atmosphere_synth: Lv2Instance
var ambience_synth: Lv2Instance
var space_synth: Lv2Instance
var bass2_synth: Lv2Instance

func _ready():
	CsoundServer.csound_layout_changed.connect(csound_layout_changed)
	Lv2Server.lv2_ready.connect(_on_lv2_ready)

	timer.start()


func csound_layout_changed():
	csound = CsoundServer.get_csound("Main")
	csound.midi_note_on.connect(_on_midi_note_on)
	csound.midi_note_off.connect(_on_midi_note_off)


func _on_lv2_ready(name: String):
	if name == "guitar":
		guitar_synth = Lv2Server.get_instance(name)
		guitar_synth.load_preset("BriansBank03: 055: Magic1")

	if name == "bass1":
		bass1_synth = Lv2Server.get_instance(name)
		bass1_synth.load_preset("BriansBank01: 103: Peavey1")

	if name == "dirty_bass":
		dirty_bass_synth = Lv2Server.get_instance(name)
		dirty_bass_synth.load_preset("BriansBank05: 125: Oberbass3")

	if name == "atmosphere":
		atmosphere_synth = Lv2Server.get_instance(name)
		atmosphere_synth.load_preset("Fantasy: 0011-Space Choir1.xiz")

	if name == "ambience":
		ambience_synth = Lv2Server.get_instance(name)
		ambience_synth.load_preset("BriansBank01: 081: LFO")

	if name == "space":
		space_synth = Lv2Server.get_instance(name)
		space_synth.load_preset("BriansBank01: 079: EPtremolo")

	if name == "bass2":
		bass2_synth = Lv2Server.get_instance(name)
		bass2_synth.load_preset("BriansBank01: 032: basic")

	#for preset in guitar_synth.get_presets():
	#	print(preset)


func _on_midi_note_on(channel, note, velocity):
	print("Note On: channel: ", channel, " note: ", note, " velocity: ", velocity)

	if guitar_synth and channel == 1:
		guitar_synth.note_on(0, 0, note, velocity)

	if bass1_synth and channel == 2:
		bass1_synth.note_on(0, 0, note, velocity)

	if dirty_bass_synth and channel == 3:
		dirty_bass_synth.note_on(0, 0, note, velocity)

	if atmosphere_synth and channel == 4:
		atmosphere_synth.note_on(0, 0, note, velocity)

	if ambience_synth and channel == 5:
		ambience_synth.note_on(0, 0, note, velocity)

	if space_synth and channel == 6:
		space_synth.note_on(0, 0, note, velocity)

	if bass2_synth and channel == 8:
		bass2_synth.note_on(0, 0, note, velocity)


func _on_midi_note_off(channel, note):
	print("Note Off: channel: ", channel, " note: ", note)

	if guitar_synth and channel == 1:
		guitar_synth.note_off(0, 0, note)

	if bass1_synth and channel == 2:
		bass1_synth.note_off(0, 0, note)

	if dirty_bass_synth and channel == 3:
		dirty_bass_synth.note_off(0, 0, note)

	if atmosphere_synth and channel == 4:
		atmosphere_synth.note_off(0, 0, note)

	if ambience_synth and channel == 5:
		ambience_synth.note_off(0, 0, note)

	if space_synth and channel == 6:
		space_synth.note_off(0, 0, note)

	if bass2_synth and channel == 8:
		bass2_synth.note_off(0, 0, note)


func _on_timer_timeout() -> void:
	spawn_location.progress_ratio = random.randf()
	
	var brain: Node2D = brain_scene.instantiate()
	
	add_child(brain)
	move_child(brain, 7)

	brain.global_position = spawn_location.global_position
