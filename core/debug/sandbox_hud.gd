class_name SandboxHud
extends CanvasLayer
## On-screen overlay for sandboxes: sandbox name, hotkeys, FPS, and any live
## values pushed with watch(). Add a CanvasLayer with this script to a sandbox.

var _label: Label
var _watched: Dictionary[String, Variant] = {}


func _ready() -> void:
	layer = 100
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var scene_name := String(scene.name) if scene else "?"
	var lines := PackedStringArray()
	lines.append("%s  |  Esc: menu  F5: reload  |  %d FPS" % [scene_name, Engine.get_frames_per_second()])
	for key: String in _watched:
		lines.append("%s: %s" % [key, str(_watched[key])])
	_label.text = "\n".join(lines)


## Show a live value on the overlay, for example hud.watch("selected", unit_name).
func watch(key: String, value: Variant) -> void:
	_watched[key] = value


func unwatch(key: String) -> void:
	_watched.erase(key)
