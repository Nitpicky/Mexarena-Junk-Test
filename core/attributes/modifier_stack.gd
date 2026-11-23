class_name ModifierStack
extends RefCounted
## How modifiers stack. This is the one place to change the stacking order.
##
## Default order (the person has not decided yet, 2026-11-23):
##   1. base + every ADD
##   2. x (1 + sum of every PERCENT / 100)   percents add up, not multiply
##   3. the last OVERRIDE, if any, replaces the result


static func compute(base: float, modifiers: Array[AttributeModifier]) -> float:
	var flat := 0.0
	var percent := 0.0
	var has_override := false
	var override_value := 0.0
	for modifier: AttributeModifier in modifiers:
		match modifier.op:
			AttributeModifier.Op.ADD:
				flat += modifier.amount
			AttributeModifier.Op.PERCENT:
				percent += modifier.amount
			AttributeModifier.Op.OVERRIDE:
				has_override = true
				override_value = modifier.amount
	var result := (base + flat) * (1.0 + percent / 100.0)
	if has_override:
		result = override_value
	return result
