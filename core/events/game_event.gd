class_name GameEvent
extends RefCounted
## One thing that happened, or is about to happen, in a match.
##
## `source` is who caused it, `target` is who it happened to. For unit-level
## events (turn_started, damaged, died...) the unit is always the `target`.
## `data` holds anything else (amounts, cards, tags...).
## Listeners of "before_*" events may edit `data` or set `cancelled = true`.

var type: StringName
var source: Object
var target: Object
var data: Dictionary
var cancelled: bool = false


func _init(p_type: StringName, p_source: Object = null, p_target: Object = null, p_data: Dictionary = {}) -> void:
	type = p_type
	source = p_source
	target = p_target
	data = p_data.duplicate()


func get_value(key: String, default: Variant = null) -> Variant:
	return data.get(key, default)


## Tags are an optional PackedStringArray under data["tags"].
func has_tag(tag: String) -> bool:
	var tags: PackedStringArray = data.get("tags", PackedStringArray())
	return tags.has(tag)
