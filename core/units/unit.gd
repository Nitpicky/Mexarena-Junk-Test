class_name Unit
extends Node2D
## A piece on the board. It has no stats of its own: everything it is lives in
## `attributes` (hp, attack, movement, speed, statuses, the general role...).
##
## Common attribute ids read by the core modules (all optional):
##   hp (pool), attack, range, movement, speed, size (collision radius),
##   general (marks a General, see TacticsMatch).
## A unit without hp cannot be damaged; without movement it cannot move.

## Collision radius when the unit has no "size" attribute.
const DEFAULT_RADIUS := 22.0

var unit_id: int = 0
var display_name: String = "Unit"
var player_index: int = -1
var team: int = -1
var color: Color = Color.WHITE
## The card this unit came from (a CardData), if any.
var source_card: Resource
var alive: bool = true
var attributes: AttributeSet

## Per-turn state, reset when the unit's turn starts.
var moves_left: float = 0.0
var move_origin: Vector2 = Vector2.ZERO
var attacks_left: int = 0
## Grid cell, used by grid map cores only.
var cell: Vector2i = Vector2i.ZERO

## PROTOTYPE: drawing flags set by the sandbox UI.
var is_active: bool = false
var is_highlighted: bool = false


func _init() -> void:
	attributes = AttributeSet.new(self)
	attributes.changed.connect(queue_redraw)


func is_general() -> bool:
	return attributes.has(&"general")


func stat(id: StringName, default: float = 0.0) -> float:
	return attributes.value(id, default)


func radius() -> float:
	return attributes.value(&"size", DEFAULT_RADIUS)


func set_active(value: bool) -> void:
	is_active = value
	queue_redraw()


func set_highlighted(value: bool) -> void:
	is_highlighted = value
	queue_redraw()


# PROTOTYPE: placeholder look (disc, team ring, hp bar, name, status count).
func _draw() -> void:
	var r := radius()
	var font := ThemeDB.fallback_font
	if is_active:
		draw_circle(Vector2.ZERO, r + 7.0, Color(1, 1, 0.4, 0.35))
	draw_circle(Vector2.ZERO, r, color.darkened(0.35))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, color, 3.0, true)
	if is_general():
		draw_arc(Vector2.ZERO, r - 5.0, 0.0, TAU, 32, Color.GOLD, 2.0, true)
	if is_highlighted:
		draw_arc(Vector2.ZERO, r + 3.0, 0.0, TAU, 32, Color.WHITE, 2.0, true)
	var initials := display_name.substr(0, 2)
	draw_string(font, Vector2(-r, 5), initials, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 14, Color.WHITE)
	if attributes.has(&"hp"):
		var max_hp := maxf(attributes.value(&"hp"), 1.0)
		var ratio := clampf(attributes.current(&"hp") / max_hp, 0.0, 1.0)
		var bar := Rect2(Vector2(-r, r + 3.0), Vector2(r * 2.0, 5.0))
		draw_rect(bar, Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.3, 0.9, 0.3).lerp(Color(0.95, 0.25, 0.2), 1.0 - ratio))
		draw_string(font, Vector2(-r, r + 20.0), "%d" % ceili(attributes.current(&"hp")), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 11, Color.WHITE)
	var statuses := 0
	for attribute: Attribute in attributes.all():
		if attribute.tags.has("status") or attribute.tags.has("buff"):
			statuses += 1
	if statuses > 0:
		draw_circle(Vector2(r * 0.75, -r * 0.75), 7.0, Color(0.7, 0.3, 0.9))
		draw_string(font, Vector2(r * 0.75 - 7.0, -r * 0.75 + 4.0), str(statuses), HORIZONTAL_ALIGNMENT_CENTER, 14.0, 10, Color.WHITE)
