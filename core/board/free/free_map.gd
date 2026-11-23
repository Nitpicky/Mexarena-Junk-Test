class_name FreeMap
extends MapCore
## Map core: open space. At the start of its turn a unit's reach is locked to a
## circle (radius = movement x pixels_per_point) around where it stands. During
## its turn it may move anywhere inside that circle, as often as it likes.
## Units have a round collision (the "size" attribute, else Unit.DEFAULT_RADIUS):
## they cannot overlap or move through each other.
##
## Open point (2026-11-23): the circle is locked at turn start even if movement
## changes mid-turn. Change _begin_unit_turn() / move_radius() to try otherwise.

@export var arena_size: Vector2 = Vector2(1100, 660)
## Pixels per movement point (and per range point).
@export var pixels_per_point: float = 40.0


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, arena_size)


func general_spawn(player: PlayerState) -> Vector2:
	var fraction := _spawn_fraction(player)
	var margin := 70.0
	var local := Vector2(lerpf(margin, arena_size.x - margin, fraction.x), arena_size.y * fraction.y)
	var step := Vector2(0, Unit.DEFAULT_RADIUS * 2.5)
	for i: int in 20:
		var candidate := local + step * (float(floori(i / 2.0) + 1) * (1.0 if i % 2 == 0 else -1.0)) if i > 0 else local
		if _is_open(candidate, Unit.DEFAULT_RADIUS, null):
			return to_global(candidate)
	return to_global(local)


func can_summon_at(player_index: int, world_pos: Vector2) -> bool:
	var local := to_local(world_pos)
	if not _is_open(local, Unit.DEFAULT_RADIUS, null):
		return false
	for general: Unit in _friendly_generals(player_index):
		if local.distance_to(general.position) - general.radius() <= summon_range * pixels_per_point:
			return true
	return false


func place_unit(unit: Unit, world_pos: Vector2) -> bool:
	var local := to_local(world_pos)
	if not _is_open(local, unit.radius(), unit):
		return false
	unit.position = local
	units_root.add_child(unit)
	refresh()
	return true


func move_radius(unit: Unit) -> float:
	return maxf(unit.moves_left, 0.0) * pixels_per_point


## Where a move order toward `world_pos` would end: clamped into the turn's
## circle and the arena.
func resolve_target(unit: Unit, world_pos: Vector2) -> Vector2:
	var local := to_local(world_pos)
	local = unit.move_origin + (local - unit.move_origin).limit_length(move_radius(unit))
	var r := unit.radius()
	local.x = clampf(local.x, r, arena_size.x - r)
	local.y = clampf(local.y, r, arena_size.y - r)
	return local


func can_move_to(unit: Unit, world_pos: Vector2) -> bool:
	if move_radius(unit) <= 0.0:
		return false
	var target := resolve_target(unit, world_pos)
	if target.distance_to(unit.position) < 1.0:
		return false
	return _is_open(target, unit.radius(), unit) and not _path_blocked(unit, unit.position, target)


func move_unit(unit: Unit, world_pos: Vector2) -> bool:
	if not can_move_to(unit, world_pos):
		return false
	var from := unit.position
	unit.position = resolve_target(unit, world_pos)
	_emit_moved(unit, from)
	return true


## Gap between the two collision circles, in points.
func distance(a: Unit, b: Unit) -> float:
	return maxf(0.0, a.position.distance_to(b.position) - a.radius() - b.radius()) / pixels_per_point


func _is_open(local: Vector2, r: float, ignore: Unit) -> bool:
	if local.x < r or local.y < r or local.x > arena_size.x - r or local.y > arena_size.y - r:
		return false
	for other: Unit in game.living_units():
		if other != ignore and other.position.distance_to(local) < r + other.radius():
			return false
	return true


func _path_blocked(unit: Unit, from: Vector2, to: Vector2) -> bool:
	for other: Unit in game.living_units():
		if other == unit:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(other.position, from, to)
		if closest.distance_to(other.position) < unit.radius() + other.radius() - 0.5:
			return true
	return false


# PROTOTYPE: arena look.
func _draw() -> void:
	draw_rect(get_bounds(), Color(0.2, 0.24, 0.2))
	var grid := pixels_per_point * 2.0
	var x := grid
	while x < arena_size.x:
		draw_line(Vector2(x, 0), Vector2(x, arena_size.y), Color(1, 1, 1, 0.04))
		x += grid
	var y := grid
	while y < arena_size.y:
		draw_line(Vector2(0, y), Vector2(arena_size.x, y), Color(1, 1, 1, 0.04))
		y += grid
	draw_rect(get_bounds(), Color(0.6, 0.65, 0.6), false, 3.0)


# PROTOTYPE: range highlights.
func _draw_overlay() -> void:
	if game == null:
		return
	if summon_player >= 0:
		for general: Unit in _friendly_generals(summon_player):
			var r := summon_range * pixels_per_point + general.radius()
			overlay.draw_circle(general.position, r, Color(0.3, 1.0, 0.4, 0.15))
			overlay.draw_arc(general.position, r, 0.0, TAU, 64, Color(0.3, 1.0, 0.4, 0.6), 2.0, true)
	if focus_unit and focus_unit.alive:
		var move_r := move_radius(focus_unit)
		if move_r > 0.0:
			overlay.draw_circle(focus_unit.move_origin, move_r, Color(0.3, 0.6, 1.0, 0.15))
			overlay.draw_arc(focus_unit.move_origin, move_r, 0.0, TAU, 64, Color(0.3, 0.6, 1.0, 0.7), 2.0, true)
		if focus_unit.attacks_left > 0:
			var reach := focus_unit.stat(&"range", 1.0) * pixels_per_point + focus_unit.radius()
			overlay.draw_arc(focus_unit.position, reach, 0.0, TAU, 64, Color(1.0, 0.35, 0.3, 0.7), 1.5, true)
		if hover_position != Vector2.INF and move_r > 0.0 and unit_at(hover_position) == null:
			var target := resolve_target(focus_unit, hover_position)
			var ok := can_move_to(focus_unit, hover_position)
			overlay.draw_line(focus_unit.position, target, Color(1, 1, 1, 0.4), 1.5)
			overlay.draw_arc(target, focus_unit.radius(), 0.0, TAU, 32, Color(0.5, 1, 0.5, 0.8) if ok else Color(1, 0.3, 0.3, 0.8), 2.0, true)
