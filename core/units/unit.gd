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
## Set by a visual module (core/visuals/) that draws the body with a sprite.
## When false, the placeholder disc is drawn.
var has_sprite: bool = false

## Drawn above any sprite child: hp bar, status badge.
var _overlay: Node2D


func _init() -> void:
	attributes = AttributeSet.new(self)
	attributes.changed.connect(_redraw_all)
	_overlay = Node2D.new()
	_overlay.name = "Overlay"
	_overlay.z_index = 1
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)


## Adds a body visual (a sprite) under the overlay.
func add_body_visual(node: Node2D) -> void:
	add_child(node)
	move_child(node, 0)
	has_sprite = true
	_redraw_all()


func _redraw_all() -> void:
	queue_redraw()
	if _overlay:
		_overlay.queue_redraw()


func is_general() -> bool:
	return attributes.has(&"general")


func stat(id: StringName, default: float = 0.0) -> float:
	return attributes.value(id, default)


func radius() -> float:
	return attributes.value(&"size", DEFAULT_RADIUS)


func set_active(value: bool) -> void:
	is_active = value
	_redraw_all()


func set_highlighted(value: bool) -> void:
	is_highlighted = value
	_redraw_all()


# PROTOTYPE: placeholder look. Below children: ground ring, or the whole
# disc body when there is no sprite.
func _draw() -> void:
	var r := radius()
	if is_active:
		draw_circle(Vector2.ZERO, r + 7.0, Color(1, 1, 0.4, 0.35))
	if has_sprite:
		_draw_ellipse(Vector2(0, r * 0.45), Vector2(r, r * 0.45), Color(color, 0.35))
		_draw_ellipse_outline(Vector2(0, r * 0.45), Vector2(r, r * 0.45), color, 2.0)
		if is_general():
			_draw_ellipse_outline(Vector2(0, r * 0.45), Vector2(r - 4.0, r * 0.45 - 3.0), Color.GOLD, 2.0)
	else:
		draw_circle(Vector2.ZERO, r, color.darkened(0.35))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, color, 3.0, true)
		if is_general():
			draw_arc(Vector2.ZERO, r - 5.0, 0.0, TAU, 32, Color.GOLD, 2.0, true)
		var initials := display_name.substr(0, 2)
		draw_string(ThemeDB.fallback_font, Vector2(-r, 5), initials, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 14, Color.WHITE)
	if is_highlighted:
		draw_arc(Vector2.ZERO, r + 3.0, 0.0, TAU, 32, Color.WHITE, 2.0, true)


# PROTOTYPE: above children: hp bar, hp number, status count.
func _draw_overlay() -> void:
	var r := radius()
	var font := ThemeDB.fallback_font
	if attributes.has(&"hp"):
		var max_hp := maxf(attributes.value(&"hp"), 1.0)
		var ratio := clampf(attributes.current(&"hp") / max_hp, 0.0, 1.0)
		var bar := Rect2(Vector2(-r, r + 3.0), Vector2(r * 2.0, 5.0))
		_overlay.draw_rect(bar, Color(0, 0, 0, 0.7))
		_overlay.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.3, 0.9, 0.3).lerp(Color(0.95, 0.25, 0.2), 1.0 - ratio))
		_overlay.draw_string(font, Vector2(-r, r + 20.0), "%d" % ceili(attributes.current(&"hp")), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 11, Color.WHITE)
	var statuses := 0
	for attribute: Attribute in attributes.all():
		if attribute.tags.has("status") or attribute.tags.has("buff"):
			statuses += 1
	if statuses > 0:
		var badge := Vector2(r * 0.85, r * 0.3)
		_overlay.draw_circle(badge, 7.0, Color(0.7, 0.3, 0.9))
		_overlay.draw_string(font, badge + Vector2(-7.0, 4.0), str(statuses), HORIZONTAL_ALIGNMENT_CENTER, 14.0, 10, Color.WHITE)


func _ellipse_points(center: Vector2, size: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 25:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	return points


func _draw_ellipse(center: Vector2, size: Vector2, fill: Color) -> void:
	var points := _ellipse_points(center, size)
	points.remove_at(points.size() - 1)
	draw_colored_polygon(points, fill)


func _draw_ellipse_outline(center: Vector2, size: Vector2, line: Color, width: float) -> void:
	draw_polyline(_ellipse_points(center, size), line, width, true)
