class_name HexMap
extends MapCore
## Map core: hex grid, movement per tile.
##
## Author maps in the editor: open hex_map.tscn (or a copy), select the Tiles
## node and paint with the TileMap editor. What each tile does (move cost,
## blocked) is set in `terrains`, matched by the tile's atlas coordinates.
## Painted cells are the map; unpainted cells are off the map.
## If nothing is painted, a default board is generated (PROTOTYPE).
##
## Units cannot pass through other units. Movement points are locked at turn
## start and spent per tile entered (tile move_cost).

@export var terrains: Array[HexTerrain] = []
## Size of the generated board when Tiles is empty.
@export var default_size: Vector2i = Vector2i(13, 9)

var tiles: TileMapLayer
var _occupied: Dictionary = {} # Vector2i -> Unit


func _setup_map() -> void:
	tiles = get_node_or_null(^"Tiles") as TileMapLayer
	if tiles == null:
		push_error("HexMap: needs a TileMapLayer child named Tiles")
		tiles = TileMapLayer.new()
		tiles.name = "Tiles"
		add_child(tiles)
		move_child(tiles, 0)
	if tiles.get_used_cells().is_empty():
		_generate_default_map()


func get_bounds() -> Rect2:
	var used := tiles.get_used_rect()
	var size := Vector2(tiles.tile_set.tile_size)
	var top_left := _cell_to_local(used.position) - size / 2.0
	var bottom_right := _cell_to_local(used.end - Vector2i.ONE) + size / 2.0
	return Rect2(top_left, Vector2.ZERO).expand(bottom_right).grow(size.x * 0.5)


func general_spawn(player: PlayerState) -> Vector2:
	var used := tiles.get_used_rect()
	var fraction := _spawn_fraction(player)
	var wanted := Vector2i(
		used.position.x + 1 + roundi(fraction.x * (used.size.x - 3)),
		used.position.y + roundi(fraction.y * (used.size.y - 1)))
	return to_global(_cell_to_local(_nearest_free_cell(wanted)))


func can_summon_at(player_index: int, world_pos: Vector2) -> bool:
	var cell := world_to_cell(world_pos)
	if not is_free(cell):
		return false
	for general: Unit in _friendly_generals(player_index):
		if hex_distance(general.cell, cell) <= summon_range:
			return true
	return false


func place_unit(unit: Unit, world_pos: Vector2) -> bool:
	var cell := world_to_cell(world_pos)
	if not is_free(cell):
		return false
	unit.cell = cell
	unit.position = _cell_to_local(cell)
	_occupied[cell] = unit
	units_root.add_child(unit)
	refresh()
	return true


func remove_unit(unit: Unit) -> void:
	if _occupied.get(unit.cell) == unit:
		_occupied.erase(unit.cell)
	super.remove_unit(unit)


func can_move_to(unit: Unit, world_pos: Vector2) -> bool:
	var cell := world_to_cell(world_pos)
	return cell != unit.cell and reachable_cells(unit).has(cell)


func move_unit(unit: Unit, world_pos: Vector2) -> bool:
	var cell := world_to_cell(world_pos)
	if cell == unit.cell:
		return false
	var reach := reachable_cells(unit)
	if not reach.has(cell):
		return false
	var from := unit.position
	unit.moves_left -= float(reach[cell])
	_occupied.erase(unit.cell)
	_occupied[cell] = unit
	unit.cell = cell
	unit.position = _cell_to_local(cell)
	_emit_moved(unit, from)
	return true


func distance(a: Unit, b: Unit) -> float:
	return float(hex_distance(a.cell, b.cell))


func unit_at(world_pos: Vector2) -> Unit:
	var unit: Unit = _occupied.get(world_to_cell(world_pos))
	return unit if unit and unit.alive else null


func world_to_cell(world_pos: Vector2) -> Vector2i:
	return tiles.local_to_map(tiles.to_local(world_pos))


func terrain_at(cell: Vector2i) -> HexTerrain:
	if tiles.get_cell_source_id(cell) == -1:
		return null
	var coords := tiles.get_cell_atlas_coords(cell)
	for terrain: HexTerrain in terrains:
		if terrain and terrain.atlas_coords == coords:
			return terrain
	return _fallback_terrain()


func is_walkable(cell: Vector2i) -> bool:
	var terrain := terrain_at(cell)
	return terrain != null and not terrain.blocked


func is_free(cell: Vector2i) -> bool:
	return is_walkable(cell) and not _occupied.has(cell)


## Cells `unit` can reach this turn, mapped to their movement cost.
func reachable_cells(unit: Unit) -> Dictionary:
	var costs: Dictionary = {unit.cell: 0.0}
	var frontier: Array[Vector2i] = [unit.cell]
	while not frontier.is_empty():
		var best := 0
		for i: int in frontier.size():
			if costs[frontier[i]] < costs[frontier[best]]:
				best = i
		var cell: Vector2i = frontier[best]
		frontier.remove_at(best)
		for next: Vector2i in tiles.get_surrounding_cells(cell):
			if not is_walkable(next) or (_occupied.has(next) and _occupied[next] != unit):
				continue
			var cost: float = costs[cell] + float(terrain_at(next).move_cost)
			if cost > unit.moves_left + 0.001:
				continue
			if not costs.has(next) or cost < costs[next]:
				costs[next] = cost
				frontier.append(next)
	return costs


## Tile distance between two cells, ignoring terrain. The default TileSet uses
## pointy-top hexes with odd rows shifted right ("odd-r" offset layout).
@warning_ignore("integer_division")
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var aq := a.x - (a.y - (a.y & 1)) / 2
	var bq := b.x - (b.y - (b.y & 1)) / 2
	var dq := aq - bq
	var dr := a.y - b.y
	return (absi(dq) + absi(dr) + absi(dq + dr)) / 2


func _cell_to_local(cell: Vector2i) -> Vector2:
	return to_local(tiles.to_global(tiles.map_to_local(cell)))


func _nearest_free_cell(start: Vector2i) -> Vector2i:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if is_free(cell):
			return cell
		for next: Vector2i in tiles.get_surrounding_cells(cell):
			if not seen.has(next) and seen.size() < 4096:
				seen[next] = true
				queue.append(next)
	return start


func _fallback_terrain() -> HexTerrain:
	var terrain := HexTerrain.new()
	terrain.display_name = "Unknown"
	return terrain


# PROTOTYPE: default board so the sandbox works before anyone paints a map.
# Point-symmetric so both sides get the same layout.
@warning_ignore("integer_division")
func _generate_default_map() -> void:
	var w := default_size.x
	var h := default_size.y
	for y: int in h:
		for x: int in w:
			tiles.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	var rough: Array[Vector2i] = [Vector2i(3, 2), Vector2i(5, 6), Vector2i(w / 2, h / 2), Vector2i(4, 5)]
	var walls: Array[Vector2i] = [Vector2i(w / 2, 2), Vector2i(4, 4), Vector2i(w / 2 - 1, 1)]
	for cell: Vector2i in rough:
		tiles.set_cell(cell, 0, Vector2i(1, 0))
		tiles.set_cell(Vector2i(w - 1 - cell.x, h - 1 - cell.y), 0, Vector2i(1, 0))
	for cell: Vector2i in walls:
		tiles.set_cell(cell, 0, Vector2i(2, 0))
		tiles.set_cell(Vector2i(w - 1 - cell.x, h - 1 - cell.y), 0, Vector2i(2, 0))


func _hex_points(center: Vector2, shrink: float = 2.0) -> PackedVector2Array:
	var size := Vector2(tiles.tile_set.tile_size) / 2.0 - Vector2(shrink, shrink)
	return PackedVector2Array([
		center + Vector2(0, -size.y), center + Vector2(size.x, -size.y * 0.5),
		center + Vector2(size.x, size.y * 0.5), center + Vector2(0, size.y),
		center + Vector2(-size.x, size.y * 0.5), center + Vector2(-size.x, -size.y * 0.5)])


func _outline(center: Vector2, color: Color, width: float = 2.0) -> void:
	var points := _hex_points(center)
	points.append(points[0])
	overlay.draw_polyline(points, color, width, true)


# PROTOTYPE: range highlights.
func _draw_overlay() -> void:
	if game == null:
		return
	if summon_player >= 0:
		for cell: Vector2i in tiles.get_used_cells():
			if can_summon_at(summon_player, to_global(_cell_to_local(cell))):
				overlay.draw_colored_polygon(_hex_points(_cell_to_local(cell)), Color(0.3, 1.0, 0.4, 0.25))
	if focus_unit and focus_unit.alive:
		if focus_unit.moves_left > 0.0:
			var reach := reachable_cells(focus_unit)
			for cell: Vector2i in reach:
				if cell != focus_unit.cell:
					overlay.draw_colored_polygon(_hex_points(_cell_to_local(cell)), Color(0.3, 0.6, 1.0, 0.28))
		if focus_unit.attacks_left > 0:
			var attack_range := focus_unit.stat(&"range", 1.0)
			for unit: Unit in game.living_units():
				if unit.team != focus_unit.team and distance(focus_unit, unit) <= attack_range:
					_outline(unit.position, Color(1.0, 0.3, 0.25), 3.0)
	if hover_position != Vector2.INF:
		var cell := world_to_cell(hover_position)
		if tiles.get_cell_source_id(cell) != -1:
			_outline(_cell_to_local(cell), Color(1, 1, 1, 0.6))
