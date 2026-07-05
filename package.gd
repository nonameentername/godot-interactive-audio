extends "res://addons/godot-package/package.gd"


func _requirements():
	dependency("nonameentername/godot-csound", {"tag": "v0.1.0-beta.152"})
	dependency("nonameentername/godot-lv2-host", {"tag": "v0.1.0-beta.9"})
	dependency("nonameentername/godot-vst3-host", {"tag": "v0.1.0-beta.10"})
