extends Node2D


@onready
var tab_container: TabContainer = $CanvasLayer/Control/TabContainer

@onready
var ui: CanvasLayer = $CanvasLayer

@onready
var world: World = $SubViewportContainer/SubViewport/Node2D

@onready
var slider: HSlider = $CanvasLayer/Control/Panel/HSlider

var lv2_editor_scene
var ui_visible
var current_tempo = 120
var slider_drag = false
var csound_playing = true
var current_position: int = 0


func _ready() -> void:
	lv2_editor_scene = preload("res://lv2_editor.tscn")

	OS.open_midi_inputs()
	print(OS.get_connected_midi_inputs())


func _input(input_event):
	if input_event is InputEventMIDI:
		var midi_event: InputEventMIDI = input_event
		var lv2_plugin: Lv2Instance = tab_container.get_tab_metadata(tab_container.current_tab)

		if midi_event.message == MIDI_MESSAGE_NOTE_ON:
			lv2_plugin.note_on(0, 0, midi_event.pitch, midi_event.velocity)
		if midi_event.message == MIDI_MESSAGE_NOTE_OFF:
			lv2_plugin.note_off(0, 0, midi_event.pitch)


func _physics_process(delta):
	if Input.is_action_just_pressed("toggle_ui"):
		ui_visible = not ui_visible
		ui.visible = ui_visible

	if not slider_drag and csound_playing:
		var csound = CsoundServer.get_csound("Main")
		if csound:
			var time = csound.get_control_channel("time")
			slider.value = time
			current_position = time


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
		lv2_plugin.control_change(0, 0, 123, 0)


func _on_play_button_pressed() -> void:
	var saved_current_position = current_position
	world.playback_start()
	world.set_score_position(saved_current_position)
	csound_playing = true


func _on_stop_button_pressed() -> void:
	world.playback_stop()
	csound_playing = false


func _on_h_slider_drag_started() -> void:
	if not csound_playing:
		slider_drag = true


func _on_h_slider_drag_ended(value_changed: bool) -> void:
	if not csound_playing:
		current_position = slider.value
		world.set_score_position(current_position)
	slider_drag = false
