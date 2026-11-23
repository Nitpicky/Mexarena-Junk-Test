class_name CtbTurns
extends TurnCore
## Turn core: CTB (charge time battle). Every unit has a gauge that fills at
## its "speed" attribute per tick. The first unit to reach gauge_size takes a
## turn; when it ends, gauge_size is taken off its gauge. The owner of the
## active unit is the current player (they may also play cards).
## upcoming() simulates the order for the on-screen turn order bar.

@export var gauge_size: float = 100.0
## Speed used for units without a "speed" attribute.
@export var default_speed: float = 10.0

var _gauges: Dictionary = {} # unit_id -> float
var _active: Unit
var _advance_pending: bool = false
var _starting: bool = false


func start() -> void:
	for unit: Unit in game.living_units():
		_gauges[unit.unit_id] = 0.0
	_advance()


func active_unit() -> Unit:
	return _active if _active and _active.alive else null


func current_player() -> int:
	return _active.player_index if active_unit() else -1


func can_select(unit: Unit) -> bool:
	return unit == active_unit()


func select_unit(unit: Unit) -> bool:
	return unit == active_unit()


func end_turn() -> void:
	if game.is_over() or _active == null:
		return
	var unit := _active
	_active = null
	_gauges[unit.unit_id] = float(_gauges.get(unit.unit_id, 0.0)) - gauge_size
	_end_unit_turn(unit)
	_end_player_turn(unit.player_index)
	_advance()


func end_turn_label() -> String:
	return "End unit turn"


func status_text() -> String:
	var unit := active_unit()
	if unit == null:
		return "Waiting..."
	return "%s's turn: %s (%s)" % [game.players[unit.player_index].display_name, unit.display_name, "speed %s" % Attribute.format_number(speed_of(unit))]


func gauge_of(unit: Unit) -> float:
	return float(_gauges.get(unit.unit_id, 0.0))


func speed_of(unit: Unit) -> float:
	return unit.stat(&"speed", default_speed) if unit.attributes.has(&"speed") else default_speed


func upcoming(count: int) -> Array[Unit]:
	var result: Array[Unit] = []
	var gauges := _gauges.duplicate()
	var active := active_unit()
	if active:
		gauges[active.unit_id] = float(gauges.get(active.unit_id, 0.0)) - gauge_size
	var candidates := game.living_units()
	for i: int in count:
		var next := _next_in(candidates, gauges)
		if next == null:
			break
		result.append(next)
		gauges[next.unit_id] = float(gauges[next.unit_id]) - gauge_size
	return result


## Picks the unit that fills its gauge first and advances every gauge to that
## moment (in `gauges`). Ties: fuller gauge first, then older unit.
func _next_in(candidates: Array[Unit], gauges: Dictionary) -> Unit:
	var best: Unit = null
	var best_time := INF
	for unit: Unit in candidates:
		var speed := speed_of(unit)
		if speed <= 0.0:
			continue
		var time := maxf(0.0, (gauge_size - float(gauges.get(unit.unit_id, 0.0))) / speed)
		if best == null or time < best_time - 0.00001 or (is_equal_approx(time, best_time) and _tie_wins(unit, best, gauges)):
			best = unit
			best_time = time
	if best == null:
		return null
	for unit: Unit in candidates:
		gauges[unit.unit_id] = float(gauges.get(unit.unit_id, 0.0)) + speed_of(unit) * best_time
	return best


func _tie_wins(a: Unit, b: Unit, gauges: Dictionary) -> bool:
	var ga := float(gauges.get(a.unit_id, 0.0))
	var gb := float(gauges.get(b.unit_id, 0.0))
	if not is_equal_approx(ga, gb):
		return ga > gb
	return a.unit_id < b.unit_id


func _advance() -> void:
	_advance_pending = false
	# A unit may die at the start of its own turn (poison): then try the next.
	for attempt: int in 64:
		if game.is_over():
			return
		var next := _next_in(game.living_units(), _gauges)
		if next == null:
			push_warning("CtbTurns: no unit can act (all speeds are 0?)")
			changed.emit()
			return
		_active = next
		_start_player_turn(next.player_index)
		_starting = true
		_start_unit_turn(next)
		_starting = false
		if next.alive:
			changed.emit()
			return
		_active = null
		_end_player_turn(next.player_index)


func _on_unit_summoned(event: GameEvent) -> void:
	var unit := event.target as Unit
	if unit:
		_gauges[unit.unit_id] = 0.0
		changed.emit()


func _on_unit_died(event: GameEvent) -> void:
	var unit := event.target as Unit
	if unit == null:
		return
	_gauges.erase(unit.unit_id)
	if unit == _active and not _advance_pending and not _starting:
		# The active unit died during its own turn: pass the turn once the
		# current event chain is done.
		_active = null
		_advance_pending = true
		_end_player_turn(unit.player_index)
		_advance.call_deferred()
	changed.emit()
