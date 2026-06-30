extends Node2D


@onready
var tab_container: TabContainer = $CanvasLayer/TabContainer

@onready
var ui: CanvasLayer = $CanvasLayer

var lv2_editor_scene
var ui_visible


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

	var tab_bar: TabBar = TabBar.new()
	tab_bar.name = name
	tab_bar.add_child(dropdown)
	tab_bar.add_child(lv2_editor)

	tab_container.add_child(tab_bar)
	tab_container.set_tab_metadata(tab_container.get_tab_count() - 1, lv2_plugin)

	lv2_editor.call_deferred("initialize", lv2_plugin)


func _on_item_selected(index: int, dropdown: OptionButton, lv2_plugin: Lv2Instance, lv2_editor: Lv2Editor):
	var preset = dropdown.get_item_text(index)
	lv2_plugin.load_preset(preset)
	lv2_editor.update(lv2_plugin)
