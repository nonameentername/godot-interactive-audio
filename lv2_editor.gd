extends Node2D
class_name Lv2Editor

var lv2: Lv2Instance
var slider_scene
var dropdown_scene
var container: VBoxContainer


func _ready():
	slider_scene = preload("res://lv2_control_slider.tscn")
	dropdown_scene = preload("res://lv2_control_dropdown.tscn")
	container = $ScrollContainer/VBoxContainer


func initialize(lv2_instance: Lv2Instance):
	lv2 = lv2_instance
	for input_control in lv2_instance.get_input_controls():
		var value = lv2_instance.get_input_control_channel(input_control.index)

		if input_control.get_choices().size() > 0:
			var dropdown: Lv2ControlDropdown = dropdown_scene.instantiate()
			dropdown.call_deferred("initialize", input_control, value)
			dropdown.value_changed.connect(_on_value_changed)
			container.add_child(dropdown)
		else:
			var slider: Lv2ControlSlider = slider_scene.instantiate()
			slider.call_deferred("initialize", input_control, value)
			slider.value_changed.connect(_on_value_changed)
			container.add_child(slider)


func update(lv2_instance: Lv2Instance):
	lv2 = lv2_instance
	for input_control in lv2_instance.get_input_controls():
		var value = lv2_instance.get_input_control_channel(input_control.index)
		if input_control.get_choices().size() > 0:
			var dropdown: Lv2ControlDropdown = container.get_child(input_control.index)
			dropdown.dropdown.selected = int(value)
		else:
			var slider: Lv2ControlSlider = container.get_child(input_control.index)
			slider.line_edit.text = slider._format_value(value)


func _on_value_changed(control: int, value: float):
	lv2.send_input_control_channel(control, value)
