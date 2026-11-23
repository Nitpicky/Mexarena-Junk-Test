extends Control
## Sandbox picker. Lists every sandbox SceneRouter finds and opens it on click.

@onready var _list: VBoxContainer = %SandboxList


func _ready() -> void:
	var names := SceneRouter.list_sandboxes()
	if names.is_empty():
		var empty := Label.new()
		empty.text = "No sandboxes yet. Duplicate sandboxes/blank_2d to start one."
		_list.add_child(empty)
		return
	for sandbox_name: String in names:
		var button := Button.new()
		button.text = sandbox_name.capitalize()
		button.pressed.connect(SceneRouter.open_sandbox.bind(sandbox_name))
		_list.add_child(button)
	(_list.get_child(0) as Button).grab_focus()
