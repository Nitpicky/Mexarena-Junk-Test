class_name HealOverTimeBehavior
extends AttributeBehavior
## Heals the holder by the attribute's effective value when its turn ends
## (regeneration...).


func _default_events() -> Array[StringName]:
	return [GameEvents.TURN_ENDED]


func handle(_event: GameEvent, attribute: Attribute, holder: Object, context: Object) -> void:
	var unit := holder as Unit
	if unit:
		Combat.heal(context as TacticsMatch, null, unit, unit.attributes.value(attribute.id), PackedStringArray(["status"]))


func describe() -> String:
	return "Heals at turn end"
