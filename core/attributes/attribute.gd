class_name Attribute
extends Resource
## Anything a unit "has": a stat (hp, attack, movement, speed), a status
## (poison), a buff (frenzy), a role (general)...
##
## Units have no built-in stats; they only hold attributes, one per `id`
## ("a cat is a cat"): adding a second attribute with the same id merges it
## into the first, following `merge`.
##
## - `base_value` is the raw number. The effective number is
##   AttributeSet.value(id), which applies modifiers from other attributes.
## - Pools (`is_pool`, like hp) also have `current`, from 0 to the effective
##   value.
## - `modifiers` change OTHER attributes on the same holder (buffs, debuffs).
## - `behaviors` react to match events (poison ticking, thorns...).
## - `duration` counts down at the end of the holder's turn; at 0 it is removed.
##
## Templates live on cards (.tres); a unit always gets its own copy.

enum Merge {
	ADD_VALUE, ## base_value adds up (2 poisons = 1 stronger poison). Default.
	KEEP_HIGHEST, ## Keeps the higher base_value.
	REPLACE, ## The newcomer's numbers replace the old ones.
	KEEP_EXISTING, ## The newcomer is ignored (only duration may refresh).
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
## Free labels for grouping and UI: "stat", "status", "buff", "role"...
@export var tags: PackedStringArray
@export var base_value: float = 0.0
## A pool (like hp) has a current amount from 0 to its effective value.
@export var is_pool: bool = false
## Starting current amount for pools. -1 = start full.
@export var current: float = -1.0
## Turns left before it is removed. -1 = permanent.
@export var duration: int = -1
@export var merge: Merge = Merge.ADD_VALUE
## On merge, keep the longer of the two durations.
@export var refresh_duration_on_merge: bool = true
@export var modifiers: Array[AttributeModifier] = []
@export var behaviors: Array[AttributeBehavior] = []
## Hidden attributes are not listed in the UI.
@export var hidden: bool = false


func label() -> String:
	return display_name if not display_name.is_empty() else String(id).capitalize()


## Folds `other` (same id) into this attribute. Modifiers and behaviors stay
## those of the attribute already on the unit.
func merge_from(other: Attribute) -> void:
	var other_current := other.current if other.current >= 0.0 else other.base_value
	match merge:
		Merge.ADD_VALUE:
			base_value += other.base_value
			if is_pool:
				current += other_current
		Merge.KEEP_HIGHEST:
			base_value = maxf(base_value, other.base_value)
			if is_pool:
				current = maxf(current, other_current)
		Merge.REPLACE:
			base_value = other.base_value
			if is_pool:
				current = other_current
		Merge.KEEP_EXISTING:
			pass
	if refresh_duration_on_merge:
		if duration < 0 or other.duration < 0:
			duration = -1
		else:
			duration = maxi(duration, other.duration)


## "3" for whole numbers, "2.5" otherwise. GDScript has no %g.
static func format_number(number: float) -> String:
	if is_equal_approx(number, roundf(number)):
		return str(int(roundf(number)))
	return String.num(number, 2)
