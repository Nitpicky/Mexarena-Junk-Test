class_name AttributeModifier
extends Resource
## A change one attribute applies to another attribute on the same unit.
## Example: a "Frenzy" status carries a modifier {target_id = attack, ADD, 2}.
## How several modifiers combine is decided in ModifierStack.

enum Op {
	ADD, ## Flat bonus (or malus with a negative amount).
	PERCENT, ## Percent bonus: 50 means +50%.
	OVERRIDE, ## Forces the value. The last one found wins.
}

## Id of the attribute this modifies (hp, attack, movement...).
@export var target_id: StringName
@export var op: Op = Op.ADD
@export var amount: float = 0.0


func describe() -> String:
	match op:
		Op.ADD:
			return "%s%s %s" % ["+" if amount >= 0.0 else "", Attribute.format_number(amount), target_id]
		Op.PERCENT:
			return "%s%s%% %s" % ["+" if amount >= 0.0 else "", Attribute.format_number(amount), target_id]
		_:
			return "%s = %s" % [target_id, Attribute.format_number(amount)]
