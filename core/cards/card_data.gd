class_name CardData
extends Resource
## A card. Played from hand, it summons a unit that receives a copy of each
## attribute listed here. Non-unit cards (spells) are planned but not built.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var art: Texture2D
## PROTOTYPE: tint used for the placeholder card and unit look.
@export var color: Color = Color(0.75, 0.75, 0.75)
## Free labels: "general" marks cards that can be picked as a General.
@export var tags: PackedStringArray
@export var attributes: Array[Attribute] = []


func label() -> String:
	return display_name if not display_name.is_empty() else String(id).capitalize()


## Short stat line for UI, e.g. "hp 10  attack 3  movement 3".
func summary() -> String:
	var parts := PackedStringArray()
	for attribute: Attribute in attributes:
		if attribute and not attribute.hidden:
			if attribute.base_value != 0.0:
				parts.append("%s %s" % [attribute.label(), Attribute.format_number(attribute.base_value)])
			else:
				parts.append(attribute.label())
	return "  ".join(parts)
