extends Node2D

var random = RandomNumberGenerator.new()

@export
var brain_scene: PackedScene

@onready
var brain_spawn_timer: Timer = $SpawnTimer

@onready
var glitch_cooldown_timer: Timer = $GlitchTimer

@onready
var spawn_location: PathFollow2D = $SpawnPath/SpawnLocation

@onready
var shader: ColorRect = $Shader

var number_of_brains = 0
var allow_glitch: bool = true

var water_eq_tween: Tween
var reverb_current_value: int = 0

var tempo_tween: Tween
var current_tempo = 120

var csound: CsoundInstance

var guitar_synth: Lv2Instance
var bass1_synth: Lv2Instance
var dirty_bass_synth: Lv2Instance
var atmosphere_synth: Lv2Instance
var ambience_synth: Lv2Instance
var space_synth: Lv2Instance
var bass2_synth: Lv2Instance
var reverb_effect: Lv2Instance
var crusher: Lv2Instance
var equalizer: Lv2Instance

const REVERB_TIME_INPUT_CONTROL = 0

const CRUSHER_DC_INPUT_CONTROL = 6
const CRUSHER_BIT_REDUCTION_INPUT_CONTROL = 3
const CRUSHER_ANTI_ALIASING_INPUT_CONTROL = 7

const EQUALIZER_HS_ACTIVE_INPUT_CONTROL = 7
const EQUALIZER_LEVEL_H_INPUT_CONTROL = 8
const EQUALIZER_FREQ_H_INPUT_CONTROL = 9

func _ready():
	CsoundServer.csound_layout_changed.connect(csound_layout_changed)
	Lv2Server.lv2_ready.connect(_on_lv2_ready)


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

	if name == "reverb":
		reverb_effect = Lv2Server.get_instance(name)
		reverb_effect.load_preset("Cathedral 1")
		reverb_effect.send_input_control_channel(REVERB_TIME_INPUT_CONTROL, 0)

		#for input_control in reverb_effect.get_input_controls():
		#	print (input_control.name, input_control.index)

		#for preset in reverb_effect.get_presets():
		#	print(preset)

	if name == "crusher":
		crusher = Lv2Server.get_instance(name)
		crusher.send_input_control_channel(CRUSHER_DC_INPUT_CONTROL, 4)
		crusher.send_input_control_channel(CRUSHER_BIT_REDUCTION_INPUT_CONTROL , 16)
		crusher.send_input_control_channel(CRUSHER_ANTI_ALIASING_INPUT_CONTROL , 0)

	if name == "equalizer":
		equalizer = Lv2Server.get_instance(name)
		equalizer.send_input_control_channel(EQUALIZER_HS_ACTIVE_INPUT_CONTROL, 1)
		equalizer.send_input_control_channel(EQUALIZER_LEVEL_H_INPUT_CONTROL, 1)
		equalizer.send_input_control_channel(EQUALIZER_FREQ_H_INPUT_CONTROL, 1024)

		#for input_control in equalizer.get_input_controls():
		#	print (input_control.name, " ", input_control.index)


func _on_midi_note_on(channel, note, velocity):
	#print("Note On: channel: ", channel, " note: ", note, " velocity: ", velocity)

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
	#print("Note Off: channel: ", channel, " note: ", note)

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
	if number_of_brains > 200:
		brain_spawn_timer.stop()
		return

	spawn_location.progress_ratio = random.randf()
	
	var brain: Node2D = brain_scene.instantiate()
	
	add_child(brain)
	move_child(brain, 7)

	number_of_brains += 1

	brain.global_position = spawn_location.global_position


func tween_control_channel(audio_plugin: Lv2Instance, control: int, from_value: float, to_value: float) -> void:
	if not audio_plugin:
		return

	if water_eq_tween:
		water_eq_tween.kill()

	water_eq_tween = get_tree().create_tween()
	water_eq_tween.tween_method(
		func(value): audio_plugin.send_input_control_channel(control, value),
		from_value,
		to_value,
		0.2
	)


func update_tempo(value):
	if tempo_tween:
		tempo_tween.kill()

	tempo_tween = get_tree().create_tween()
	tempo_tween.tween_method(
		func(value): csound.event_string('i "update_tempo" 0 -1 %d' % value),
		current_tempo,
		value,
		2.0
	)

	current_tempo = value


func _on_water_area_2d_body_entered(body: Node2D) -> void:
	tween_control_channel(equalizer, EQUALIZER_LEVEL_H_INPUT_CONTROL, 1.0, 0.2)


func _on_water_area_2d_body_exited(body: Node2D) -> void:
	tween_control_channel(equalizer, EQUALIZER_LEVEL_H_INPUT_CONTROL, 0.2, 1.0)


func _on_outside_area_2d_body_entered(body: Node2D) -> void:
	tween_control_channel(reverb_effect, REVERB_TIME_INPUT_CONTROL, reverb_current_value, 0.0)
	reverb_current_value = 0.0


func _on_small_room_area_2d_body_entered(body: Node2D) -> void:
	tween_control_channel(reverb_effect, REVERB_TIME_INPUT_CONTROL, reverb_current_value, 16.0)
	reverb_current_value = 16.0


func _on_medium_room_area_2d_body_entered(body: Node2D) -> void:
	tween_control_channel(reverb_effect, REVERB_TIME_INPUT_CONTROL, reverb_current_value, 32.0)
	reverb_current_value = 32.0

	#update_tempo(120)


func _on_large_room_area_2d_body_entered(body: Node2D) -> void:
	tween_control_channel(reverb_effect, REVERB_TIME_INPUT_CONTROL, reverb_current_value, 64.0)
	reverb_current_value = 64.0



func _on_enemy_area_2d_body_entered(body: Node2D) -> void:
	brain_spawn_timer.start()

	update_tempo(360)


func _on_player_brain_collision() -> void:
	if not allow_glitch:
		return

	allow_glitch = false

	var audio_tween = get_tree().create_tween()

	audio_tween.tween_method(
		func(value): crusher.send_input_control_channel(CRUSHER_BIT_REDUCTION_INPUT_CONTROL , value),
		2.0,
		1.0,
		0.3
	)

	audio_tween.tween_method(
		func(value): crusher.send_input_control_channel(CRUSHER_BIT_REDUCTION_INPUT_CONTROL , value),
		1.0,
		16.0,
		0.1
	)

	glitch_cooldown_timer.start()

	var pixelation_tween = get_tree().create_tween()

	pixelation_tween.tween_method(
		func(value): shader.material.set_shader_parameter("pixelation", value),
		0.1,
		0.001,
		0.2
	)


func _on_glitch_timer_timeout() -> void:
	allow_glitch = true
