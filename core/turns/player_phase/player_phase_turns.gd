class_name PlayerPhaseTurns
extends TurnCore
## Turn core: Player Phase. Players take phases in order (MatchConfig.players
## order). During its phase a player picks one of its units and plays it.
## Picking another unit ends the previous unit's turn for good: it cannot be
## picked again this phase. "End phase" passes to the next player.

## When false, a unit summoned during a phase waits for its owner's next phase.
@export var summoned_units_act_immediately: bool = false

var phase_number: int = 0
var _player: int = -1
var _active: Unit
var _done: Dictionary = {} # unit_id -> true


func start() -> void:
	_begin_phase(0)


func active_unit() -> Unit:
	return _active if _active and _active.alive else null


func current_player() -> int:
	return _player


func can_select(unit: Unit) -> bool:
	return not game.is_over() and unit.alive and unit.player_index == _player and not _done.has(unit.unit_id)


func select_unit(unit: Unit) -> bool:
	if unit == active_unit():
		return true
	if not can_select(unit):
		return false
	_finish_active()
	_active = unit
	_start_unit_turn(unit)
	if not unit.alive:
		_active = null
	changed.emit()
	return _active != null


func end_turn() -> void:
	if game.is_over():
		return
	_finish_active()
	_end_player_turn(_player)
	if game.is_over():
		return
	_begin_phase((_player + 1) % game.players.size())


func end_turn_label() -> String:
	return "End phase"


func status_text() -> String:
	var name := game.players[_player].display_name if _player >= 0 else "-"
	return "Phase %d: %s. Pick a unit to play it; picking another ends the first." % [phase_number, name]


func _begin_phase(player_index: int) -> void:
	phase_number += 1
	_player = player_index
	_active = null
	_done.clear()
	_start_player_turn(_player)
	changed.emit()


func _finish_active() -> void:
	if _active == null:
		return
	var unit := _active
	_active = null
	_done[unit.unit_id] = true
	_end_unit_turn(unit)
	changed.emit()


func _on_unit_summoned(event: GameEvent) -> void:
	var unit := event.target as Unit
	if unit and not summoned_units_act_immediately:
		_done[unit.unit_id] = true


func _on_unit_died(event: GameEvent) -> void:
	if event.target == _active:
		_active = null
		changed.emit()
