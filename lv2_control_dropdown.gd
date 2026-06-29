extends HBoxContainer
class_name Lv2ControlDropdown

signal value_changed(control_index: int, value: float)

@onready var label: Label = $Label
@onready var dropdown: OptionButton = $OptionButton

var control_index: int
var integer: bool


func initialize(lv2_control: Lv2Control, _value: float) -> void:
	control_index = lv2_control.index
	integer = lv2_control.integer

	label.text = lv2_control.name

	var choices = lv2_control.get_choices()
	for choice in choices:
		dropdown.add_item(choice, choices[choice])


func _on_option_button_item_selected(index: int) -> void:
	var value = dropdown.get_item_id(index)
	emit_signal("value_changed", control_index, float(value))
