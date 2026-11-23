class_name ApplyOnHitBehavior
extends AttributeBehavior
## When the holder deals attack damage, adds `apply` (a copy) to the target.
## Example: Venom applies Poison; a second hit merges into the same Poison.


@export var apply: Attribute
## Only attacks count (not poison ticks or reflected damage).
@export var attacks_only: bool = true


func _init() -> void:
	scope = Scope.HOLDER_IS_SOURCE


func _default_events() -> Array[StringName]:
	return [GameEvents.DAMAGED]


func handle(event: GameEvent, _attribute: Attribute, _holder: Object, _context: Object) -> void:
	var target := event.target as Unit
	if apply == null or target == null or not target.alive:
		return
	if attacks_only and not event.has_tag("attack"):
		return
	target.attributes.add(apply)


func describe() -> String:
	return "On hit: applies %s" % (apply.label() if apply else "nothing")
