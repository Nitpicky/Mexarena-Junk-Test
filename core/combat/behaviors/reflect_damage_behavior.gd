class_name ReflectDamageBehavior
extends AttributeBehavior
## When the holder is hit by an attack, deals the attribute's effective value
## back to the attacker (thorns). Reflected damage is never reflected again.


func _default_events() -> Array[StringName]:
	return [GameEvents.DAMAGED]


func handle(event: GameEvent, attribute: Attribute, holder: Object, context: Object) -> void:
	var unit := holder as Unit
	var attacker := event.source as Unit
	if unit == null or attacker == null or not event.has_tag("attack"):
		return
	Combat.deal_damage(context as TacticsMatch, unit, attacker, unit.attributes.value(attribute.id), PackedStringArray(["reflected"]))


func describe() -> String:
	return "Hurts attackers"
