extends Node
## Headless smoke test. Instantiates the menu and every sandbox for a few
## frames, then quits with exit code 1 if any scene failed to load.
##
## Run from the repo root:
##   godot --headless --path . --import
##   godot --headless --path . res://tools/smoke_test.tscn
## Script errors during the run are printed by Godot as "SCRIPT ERROR" lines;
## treat any of those as a failure too.

const MENU_SCENE := "res://scenes/main/main.tscn"
const FRAMES_PER_SCENE := 5


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var paths: Array[String] = [MENU_SCENE]
	for sandbox_name: String in SceneRouter.list_sandboxes():
		paths.append(SceneRouter.sandbox_path(sandbox_name))

	var failures := 0
	for path: String in paths:
		var packed := load(path) as PackedScene
		if packed == null:
			printerr("FAIL  could not load ", path)
			failures += 1
			continue
		var instance := packed.instantiate()
		if instance == null:
			printerr("FAIL  could not instantiate ", path)
			failures += 1
			continue
		add_child(instance)
		for i in FRAMES_PER_SCENE:
			await get_tree().process_frame
		instance.queue_free()
		await get_tree().process_frame
		print("ok    ", path)

	print("Smoke test: %d scene(s), %d failure(s)" % [paths.size(), failures])
	get_tree().quit(1 if failures > 0 else 0)
