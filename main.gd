extends Node2D


@onready
var tab_container: TabContainer = $CanvasLayer/Control/TabContainer

@onready
var ui: CanvasLayer = $CanvasLayer

@onready
var world: World = $SubViewportContainer/SubViewport/Node2D

@onready
var slider: HSlider = $CanvasLayer/Control/Panel/HSlider

@onready
var option_button: OptionButton = $CanvasLayer/Control/TabContainer/Csound/CsoundOptionButton

@onready
var amsynth: ASynth = $CanvasLayer/Control/TabContainer/Csound/amsynth

var csound_synth: CsoundInstance

var lv2_editor_scene
var ui_visible
var current_tempo = 120
var slider_drag = false
var csound_playing = true
var current_position: float = 0
var csound_parameters: Array[String]


func _ready() -> void:
	CsoundServer.csound_ready.connect(_on_csound_ready)

	lv2_editor_scene = preload("res://lv2_editor.tscn")

	OS.open_midi_inputs()
	print(OS.get_connected_midi_inputs())

	csound_parameters = [
		"ASynthOsc.1.osc_waveform",
		"ASynthOsc.1.osc_pulsewidth",
		"ASynthOsc.1.osc_sync",
		"ASynthDetune.1.osc_range",
		"ASynthDetune.1.osc_pitch",
		"ASynthDetune.1.osc_detune",
		"ASynthOsc.2.osc_waveform",
		"ASynthOsc.2.osc_pulsewidth",
		"ASynthOsc.2.osc_sync",
		"ASynthDetune.2.osc_range",
		"ASynthDetune.2.osc_pitch",
		"ASynthDetune.2.osc_detune",
		"ASynthAmp.1.amp_attack",
		"ASynthAmp.1.amp_decay",
		"ASynthAmp.1.amp_sustain",
		"ASynthAmp.1.amp_release",
		"ASynthMix.1.osc_mix",
		"ASynthMix.1.osc_mix_mode",
		"ASynthRender.1.master_vol",
		"ASynthOverDrive.1.distortion_crunch",
		"ASynthFilter.1.filter_type",
		"ASynthFilter.1.filter_resonance",
		"ASynthFilter.1.filter_cutoff",
		"ASynthFilter.1.filter_kbd_track",
		"ASynthFilter.1.filter_env_amount",
		"ASynthFilter.1.filter_attack",
		"ASynthFilter.1.filter_decay",
		"ASynthFilter.1.filter_sustain",
		"ASynthFilter.1.filter_release",
		"ASynthLfo.1.lfo_waveform",
		"ASynthLfo.1.lfo_freq",
		"ASynthLfoFreq.1.freq_mod_amount",
		"ASynthLfoFreq.2.freq_mod_amount",
		"ASynthFilter.1.filter_mod_amount",
		"ASynthAmp.1.amp_mod_amount",
		"ASynthReverb.1.reverb_wet",
		"ASynthReverb.1.reverb_roomsize",
		"ASynthReverb.1.reverb_width",
		"ASynthReverb.1.reverb_damp",
		"ASynthInput.1.portamento_time",
		"ASynthInput.1.portamento_mode",
		"ASynthInput.1.keyboard_mode"
	]

	var popup_menu: PopupMenu = option_button.get_popup()
	for i in popup_menu.get_item_count():
		if popup_menu.is_item_radio_checkable(i):
			popup_menu.set_item_as_radio_checkable(i, false)


func _on_csound_ready(name: String):
	if name == "amsynth":
		csound_synth = CsoundServer.get_csound(name)
		option_button.selected = 1
		amsynth.load_preset("presets/AndroidChatter.json")
		option_button.selected = 2
		amsynth.load_preset("presets/Aria.json")
		option_button.selected = 0


func _input(input_event):
	if input_event is InputEventMIDI:
		var midi_event: InputEventMIDI = input_event
		var lv2_plugin: Lv2Instance = tab_container.get_tab_metadata(tab_container.current_tab)

		if lv2_plugin:
			if midi_event.message == MIDI_MESSAGE_NOTE_ON:
				lv2_plugin.note_on(0, 0, midi_event.pitch, midi_event.velocity)
			if midi_event.message == MIDI_MESSAGE_NOTE_OFF:
				lv2_plugin.note_off(0, 0, midi_event.pitch)
		else:
			if midi_event.message == MIDI_MESSAGE_NOTE_ON:
				csound_synth.note_on(option_button.selected, midi_event.pitch, midi_event.velocity)
			if midi_event.message == MIDI_MESSAGE_NOTE_OFF:
				csound_synth.note_off(option_button.selected, midi_event.pitch)


func _physics_process(delta):
	if Input.is_action_just_pressed("toggle_ui"):
		ui_visible = not ui_visible
		ui.visible = ui_visible

	if not slider_drag and csound_playing:
		var csound = CsoundServer.get_csound("Main")
		if csound:
			var time = csound.get_control_channel("time")
			current_position = seconds_to_beat(time, current_tempo)
			slider.value = current_position


func _on_node_2d_lv_2_plugin_ready(name: String, default_preset: String) -> void:
	var lv2_plugin: Lv2Instance = Lv2Server.get_instance(name)
	var lv2_editor: Lv2Editor = lv2_editor_scene.instantiate()

	var dropdown: OptionButton = OptionButton.new()
	dropdown.item_selected.connect(_on_item_selected.bind(dropdown, lv2_plugin, lv2_editor))

	if len(default_preset) > 0:
		dropdown.add_item(default_preset)

	for preset in lv2_plugin.get_presets():
		dropdown.add_item(preset)

	var popup_menu: PopupMenu = dropdown.get_popup()
	popup_menu.search_bar_enabled = true

	for i in popup_menu.get_item_count():
		if popup_menu.is_item_radio_checkable(i):
			popup_menu.set_item_as_radio_checkable(i, false)

	var tab_page: HBoxContainer = HBoxContainer.new()
	tab_page.name = name
	tab_page.add_child(dropdown)
	tab_page.add_child(lv2_editor)

	dropdown.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dropdown.custom_minimum_size.y = 0

	tab_container.add_child(tab_page)
	tab_container.set_tab_metadata(tab_container.get_tab_count() - 1, lv2_plugin)

	lv2_editor.call_deferred("initialize", lv2_plugin)


func _on_item_selected(index: int, dropdown: OptionButton, lv2_plugin: Lv2Instance, lv2_editor: Lv2Editor):
	var preset = dropdown.get_item_text(index)
	lv2_plugin.load_preset(preset)
	lv2_editor.update(lv2_plugin)


func _on_tempo_spin_box_value_changed(value: float) -> void:
	current_tempo = value
	world.update_tempo(current_tempo)


func _on_panic_button_pressed() -> void:
	for index in tab_container.get_tab_count():
		var lv2_plugin: Lv2Instance = tab_container.get_tab_metadata(index)
		if lv2_plugin:
			lv2_plugin.control_change(0, 0, 123, 0)


func _on_play_button_pressed() -> void:
	world.playback_start()
	world.set_score_position(beat_to_seconds(current_position, current_tempo))
	csound_playing = true


func _on_stop_button_pressed() -> void:
	world.playback_stop()
	csound_playing = false


func _on_h_slider_drag_started() -> void:
	slider_drag = true


func _on_h_slider_drag_ended(value_changed: bool) -> void:
	current_position = slider.value
	world.set_score_position(beat_to_seconds(current_position, current_tempo))
	slider_drag = false


func beat_to_seconds(beat: float, bpm: float) -> float:
	return beat * 60.0 / bpm


func seconds_to_beat(seconds: float, bpm: float) -> float:
	return seconds * bpm / 60.0


func _on_amsynth_parameter_changed(parameter: int, value: float) -> void:
	var amsynth = CsoundServer.get_csound("amsynth")
	var parameter_name = get_parameter_name(option_button.text, parameter)
	amsynth.send_control_channel(parameter_name, value)


func get_parameter_name(instrument: String, parameter: int):
	return "%s.%s" % [instrument, csound_parameters[parameter]]


func get_parameter_values(instrument: String):
	var content = {}

	for parameter in range(0, len(csound_parameters)):
		var value = csound_synth.get_control_channel(get_parameter_name(instrument, parameter))
		content[str(parameter)] = str(value)

	return content


func _on_csound_option_button_item_selected(index: int) -> void:
	var content = get_parameter_values(option_button.text)

	amsynth.update_knobs(content)
	amsynth.update_waveforms()
