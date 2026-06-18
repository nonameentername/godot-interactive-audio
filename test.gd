extends Node2D

var amsynth1
var amsynth2
var amsynth3

var vitalium

func _ready():
	Lv2Server.lv2_ready.connect(_on_lv2_ready)
	Vst3Server.vst3_ready.connect(_on_vst3_ready)


func _on_lv2_ready(name):
	if name == 'Main':
		amsynth1 = Lv2Server.get_instance(name)
		amsynth1.load_preset('BriansBank01: 021: SuperSweep2')
	elif name == 'amsynth2':
		amsynth2 = Lv2Server.get_instance(name)
		amsynth2.load_preset('BriansBank19: 028: OrganB')
	elif name == 'amsynth3':
		amsynth3 = Lv2Server.get_instance(name)

	var presets = amsynth1.get_presets()

	#for preset in presets:
	#	print (preset)

	if amsynth1 and amsynth2:
		amsynth1.note_on(0, 0, 64, 64)
		amsynth2.note_on(0, 0, 64, 64)

		await get_tree().create_timer(4.0).timeout

		amsynth1.note_off(0, 0, 64)
		amsynth2.note_off(0, 0, 64)

func _on_vst3_ready(name):
	if name == 'Main':
		vitalium = Vst3Server.get_instance(name)

	#vitalium.note_on(0, 0, 64, 64)
	#await get_tree().create_timer(4.0).timeout
	#vitalium.note_off(0, 0, 64)
