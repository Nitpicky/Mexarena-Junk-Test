extends Node
## Headless smoke test. Instantiates the menu and every sandbox for a few
## frames, runs every logic test in res://tools/tests/test_*.gd, then quits
## with exit code 1 if any scene failed to load or any check failed.
##
## Run from the repo root:
##   godot --headless --path . --import
##   godot --headless --path . res://tools/smoke_test.tscn
## Script errors during the run are printed by Godot as "SCRIPT ERROR" lines;
## treat any of those as a failure too.

const MENU_SCENE := "res://scenes/main/main.tscn"
const FRAMES_PER_SCENE := 5
const TESTS_DIR := "res://tools/tests"


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

	var checks := await _run_tests()
	failures += checks

	print("Smoke test: %d scene(s), %d failure(s)" % [paths.size(), failures])
	get_tree().quit(1 if failures > 0 else 0)


## Runs every res://tools/tests/test_*.gd. Each one is a RefCounted script with
## `func run(host: Node) -> Array[String]` returning failure messages.
## Optional: delete tools/tests/ and nothing else changes.
func _run_tests() -> int:
	if not DirAccess.dir_exists_absolute(TESTS_DIR):
		return 0
	var failures := 0
	for file: String in DirAccess.get_files_at(TESTS_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var path := TESTS_DIR.path_join(file)
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			printerr("FAIL  could not load ", path)
			failures += 1
			continue
		var test: Object = script.new()
		var results: Array = await test.call(&"run", self)
		for message: Variant in results:
			printerr("FAIL  ", file, ": ", message)
		failures += results.size()
		print("%s    %s (%d failure(s))" % ["ok  " if results.is_empty() else "FAIL", path, results.size()])
	return failures
