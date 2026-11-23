class_name MapCore
extends Node2D
## Base for a map core: where units stand, how they move, how far apart they are.
##
## Swappable: the match and the UI only talk to this interface, using world
## positions, so a hex grid and a free-space arena plug in the same way.
## Units are added as children of `units_root`.
##
## Distances are in "movement points": tiles on a grid, a fixed number of
## pixels per point in free space. The "movement" attribute is read and locked
## when a unit's turn starts (into unit.moves_left).

## How far from a friendly General a card may summon, in movement points.
@export var summon_range: float = 2.0

var game: TacticsMatch
## Node that holds the unit nodes, drawn above the map.
var units_root: Node2D
## Node drawn between the map and the units, for range highlights.
var overlay: Node2D

## PROTOTYPE: what the overlay shows. Set by the UI.
var focus_unit: Unit
var summon_player: int = -1
var hover_position: Vector2 = Vector2.INF


func setup(p_game: TacticsMatch) -> void:
	game = p_game
	overlay = Node2D.new()
	overlay.name = "Overlay"
	add_child(overlay)
	overlay.draw.connect(_draw_overlay)
	units_root = Node2D.new()
	units_root.name = "Units"
	units_root.y_sort_enabled = true
	add_child(units_root)
	game.bus.subscribe(GameEvents.TURN_STARTED, _on_turn_started, 90)
	_setup_map()


## Area the map covers, in this node's local space. Used to frame the camera.
func get_bounds() -> Rect2:
	return Rect2()


## Where `player`'s General starts.
func general_spawn(_player: PlayerState) -> Vector2:
	return Vector2.ZERO


func can_summon_at(_player_index: int, _world_pos: Vector2) -> bool:
	return false


## Puts a new unit on the map. Returns false if the spot is not valid.
func place_unit(_unit: Unit, _world_pos: Vector2) -> bool:
	return false


func remove_unit(unit: Unit) -> void:
	if unit.get_parent() == units_root:
		units_root.remove_child(unit)
	refresh()


## Moves `unit` toward `world_pos` if allowed, spending movement. True on success.
func move_unit(_unit: Unit, _world_pos: Vector2) -> bool:
	return false


func can_move_to(_unit: Unit, _world_pos: Vector2) -> bool:
	return false


## Distance between two units in movement points (used for attack range).
func distance(_a: Unit, _b: Unit) -> float:
	return INF


func unit_at(world_pos: Vector2) -> Unit:
	var local := to_local(world_pos)
	for unit: Unit in game.living_units():
		if unit.position.distance_to(local) <= unit.radius():
			return unit
	return null


## Redraws highlights.
func refresh() -> void:
	if overlay:
		overlay.queue_redraw()


## Override: build the map.
func _setup_map() -> void:
	pass


## Override: lock movement for the unit whose turn starts.
func _begin_unit_turn(unit: Unit) -> void:
	unit.moves_left = unit.stat(&"movement")
	unit.move_origin = unit.position


## Override: draw highlights on `overlay` (use overlay.draw_* calls).
func _draw_overlay() -> void:
	pass


func _on_turn_started(event: GameEvent) -> void:
	var unit := event.target as Unit
	if unit and unit.alive:
		_begin_unit_turn(unit)
		refresh()


func _emit_moved(unit: Unit, from: Vector2) -> void:
	game.bus.emit_new(GameEvents.UNIT_MOVED, null, unit, {"from": from, "to": unit.position})
	refresh()


## Friendly (same team) living Generals of `player_index`.
func _friendly_generals(player_index: int) -> Array[Unit]:
	var result: Array[Unit] = []
	var team := game.players[player_index].team
	for unit: Unit in game.living_units(team):
		if unit.is_general():
			result.append(unit)
	return result


## Where a player's General should start, as fractions (0..1) of the map:
## each team gets a column spread left to right, allies spread top to bottom.
func _spawn_fraction(player: PlayerState) -> Vector2:
	var teams := game.teams()
	var team_index := teams.find(player.team)
	var fx := 0.5 if teams.size() <= 1 else float(team_index) / float(teams.size() - 1)
	var mates: Array[PlayerState] = []
	for other: PlayerState in game.players:
		if other.team == player.team:
			mates.append(other)
	var fy := float(mates.find(player) + 1) / float(mates.size() + 1)
	return Vector2(fx, fy)
