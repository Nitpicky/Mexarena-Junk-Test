extends CanvasLayer
## PROTOTYPE: debug overlay for iterating in sandboxes. Replace or delete freely.
##
## Optional autoload (DebugHud). Shows the sandbox name, hotkeys, FPS and any
## live values pushed with watch(), only while a sandbox scene is running.
## Nothing depends on it. From a sandbox, use it only if present:
##   var hud := get_node_or_null(^"/root/DebugHud")
##   if hud: hud.watch("selected", unit_name)
## To remove: delete core/debug/ and the DebugHud line in project.godot.

const SANDBOX_ROOT := "res://sandboxes/"

var _label: Label
var _watched: Dictionary[String, Variant] = {}


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	visible = scene != null and scene.scene_file_path.begins_with(SANDBOX_ROOT)
	if not visible:
		if not _watched.is_empty():
			_watched.clear()
		return
	var lines := PackedStringArray()
	lines.append("%s  |  Esc: menu  F5: reload  |  %d FPS" % [scene.name, Engine.get_frames_per_second()])
	for key: String in _watched:
		lines.append("%s: %s" % [key, str(_watched[key])])
	_label.text = "\n".join(lines)


## Show a live value on the overlay. Cleared when you leave the sandbox.
func watch(key: String, value: Variant) -> void:
	_watched[key] = value


func unwatch(key: String) -> void:
	_watched.erase(key)
