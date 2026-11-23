class_name DamageOverTimeBehavior
extends AttributeBehavior
## Deals the attribute's effective value as damage to its holder when the
## holder's turn starts (poison, burn...). Put it on a status attribute with a
## duration; two poisons merge into one stronger poison.


func _default_events() -> Array[StringName]:
	return [GameEvents.TURN_STARTED]


func handle(_event: GameEvent, attribute: Attribute, holder: Object, context: Object) -> void:
	var unit := holder as Unit
	if unit == null:
		return
	var amount := unit.attributes.value(attribute.id)
	Combat.deal_damage(context as TacticsMatch, null, unit, amount, PackedStringArray(["status", String(attribute.id)]))


func describe() -> String:
	return "Takes damage at turn start"
