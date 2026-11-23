class_name EventBus
extends RefCounted
## Per-match event bus. Anything can subscribe to an event type and react.
##
## Not an autoload on purpose: each match owns its own bus, so several matches
## (or tests) never hear each other. Event type names are open StringNames;
## the common ones are listed in GameEvents, but any module may invent its own.
##
## Listeners run in priority order (higher first). Subscribe to ANY to hear
## every event. A listener may set `event.cancelled`, which stops the rest.

## Emitted before any listener runs, so in the order things happen
## (a death is reported before the win it causes). Handy for logs.
signal dispatching(event: GameEvent)
## Emitted after every listener ran. Handy for UI refresh.
signal emitted(event: GameEvent)

const ANY := &"*"
## Guards against two behaviors triggering each other forever.
const MAX_DEPTH := 32

var _listeners: Dictionary = {} # StringName -> Array of {callable, priority}
var _depth: int = 0


func subscribe(type: StringName, callable: Callable, priority: int = 0) -> void:
	var list: Array = _listeners.get(type, [])
	for entry: Dictionary in list:
		if entry["callable"] == callable:
			return
	list.append({"callable": callable, "priority": priority})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["priority"] > b["priority"])
	_listeners[type] = list


func unsubscribe(type: StringName, callable: Callable) -> void:
	var list: Array = _listeners.get(type, [])
	for i: int in range(list.size() - 1, -1, -1):
		if list[i]["callable"] == callable:
			list.remove_at(i)


## Removes every listener whose callable belongs to `object`.
func unsubscribe_object(object: Object) -> void:
	for type: StringName in _listeners:
		var list: Array = _listeners[type]
		for i: int in range(list.size() - 1, -1, -1):
			var callable: Callable = list[i]["callable"]
			if callable.get_object() == object:
				list.remove_at(i)


func emit(event: GameEvent) -> GameEvent:
	if _depth >= MAX_DEPTH:
		push_warning("EventBus: chain too deep, dropped '%s'" % event.type)
		return event
	_depth += 1
	dispatching.emit(event)
	var queue: Array = (_listeners.get(event.type, []) as Array).duplicate()
	queue.append_array(_listeners.get(ANY, []) as Array)
	for entry: Dictionary in queue:
		var callable: Callable = entry["callable"]
		if not callable.is_valid():
			continue
		callable.call(event)
		if event.cancelled:
			break
	_depth -= 1
	emitted.emit(event)
	return event


## Shortcut: builds the GameEvent and emits it.
func emit_new(type: StringName, source: Object = null, target: Object = null, data: Dictionary = {}) -> GameEvent:
	return emit(GameEvent.new(type, source, target, data))
