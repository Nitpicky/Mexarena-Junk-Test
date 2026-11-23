extends Node
## Playground navigation (autoload: SceneRouter).
##
## Finds sandboxes, switches between them and the menu, and owns the global
## iteration hotkeys: Esc goes back to the menu, F5 reloads the current sandbox.
## The hotkeys also work when a sandbox scene is launched directly with F6.
##
## Part of the required frame (with scenes/main/). It has no hard dependencies:
## the Events autoload is used only if it exists.

const MENU_SCENE := "res://scenes/main/main.tscn"
const SANDBOX_ROOT := "res://sandboxes"

const ACTION_BACK := &"playground_back"
const ACTION_RELOAD := &"playground_reload"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_key_action(ACTION_BACK, KEY_ESCAPE)
	_register_key_action(ACTION_RELOAD, KEY_F5)


func _unhandled_input(event: InputEvent) -> void:
	var current := current_sandbox()
	if current.is_empty():
		return
	if event.is_action_pressed(ACTION_BACK):
		get_viewport().set_input_as_handled()
		go_to_menu()
	elif event.is_action_pressed(ACTION_RELOAD):
		get_viewport().set_input_as_handled()
		open_sandbox(current)


## Every folder in res://sandboxes that contains <name>/<name>.tscn, sorted.
## Folders starting with "_" are skipped (use them for shared sandbox helpers).
func list_sandboxes() -> PackedStringArray:
	var result := PackedStringArray()
	for dir_name: String in DirAccess.get_directories_at(SANDBOX_ROOT):
		if dir_name.begins_with("_"):
			continue
		if ResourceLoader.exists(sandbox_path(dir_name)):
			result.append(dir_name)
	result.sort()
	return result


func sandbox_path(sandbox_name: String) -> String:
	return "%s/%s/%s.tscn" % [SANDBOX_ROOT, sandbox_name, sandbox_name]


## Name of the sandbox currently running, or "" when on the menu.
func current_sandbox() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return ""
	var path := scene.scene_file_path
	if not path.begins_with(SANDBOX_ROOT + "/"):
		return ""
	return path.get_file().get_basename()


func open_sandbox(sandbox_name: String) -> void:
	var path := sandbox_path(sandbox_name)
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: no sandbox scene at %s" % path)
		return
	get_tree().paused = false
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.emit_signal(&"sandbox_opened", sandbox_name)
	get_tree().change_scene_to_file(path)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _register_key_action(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
