class_name AttributeBehavior
extends Resource
## Base class for behavior an attribute carries (poison ticking, thorns...).
##
## A behavior is a small Resource placed in Attribute.behaviors. While the
## attribute sits on a unit that is in a match, the behavior hears the events
## it listens to and reacts in handle(). Subclass it, override
## _default_events() and handle(). Keep behaviors stateless: put state on the
## attribute (value, current, duration) so merging two attributes stays simple.

enum Scope {
	HOLDER_IS_TARGET, ## Only events that happen to the holder (default).
	HOLDER_IS_SOURCE, ## Only events the holder caused (on-hit effects).
	ANY, ## Every event of the listened types.
}

## Event types to listen to. Leave empty to use the behavior's defaults.
@export var events: Array[StringName] = []
@export var scope: Scope = Scope.HOLDER_IS_TARGET
## Higher runs first among listeners of the same event.
@export var priority: int = 0


func listens_to() -> Array[StringName]:
	if not events.is_empty():
		return events
	return _default_events()


func applies(event: GameEvent, holder: Object) -> bool:
	match scope:
		Scope.HOLDER_IS_TARGET:
			return event.target == holder
		Scope.HOLDER_IS_SOURCE:
			return event.source == holder
	return true


## Override: the event types this behavior listens to by default.
func _default_events() -> Array[StringName]:
	return []


## Override: react to an event. `context` is whatever owns the bus (the match).
func handle(_event: GameEvent, _attribute: Attribute, _holder: Object, _context: Object) -> void:
	pass


## Override: called when the attribute lands on a holder.
func on_added(_attribute: Attribute, _holder: Object, _context: Object) -> void:
	pass


## Override: called when the attribute leaves a holder.
func on_removed(_attribute: Attribute, _holder: Object, _context: Object) -> void:
	pass


## One line for tooltips. Override for something nicer.
func describe() -> String:
	return resource_name if not resource_name.is_empty() else (get_script() as Script).resource_path.get_file().get_basename().capitalize()
