class_name TurnCore
extends Node
## Base for a turn core: decides who may act and when.
##
## Swappable: the match and the UI only use this interface. A turn core emits
## the turn events on the match bus (PLAYER_TURN_STARTED/ENDED with
## data.player, TURN_STARTED/ENDED with the unit as target); everything else
## (movement lock, card draw, poison...) reacts to those events.

## Turn state changed (UI refresh hint).
signal changed

var game: TacticsMatch


func setup(p_game: TacticsMatch) -> void:
	game = p_game
	game.bus.subscribe(GameEvents.UNIT_SUMMONED, _on_unit_summoned)
	game.bus.subscribe(GameEvents.UNIT_DIED, _on_unit_died)


## Override: begin the first turn.
func start() -> void:
	pass


## The unit currently taking its turn, or null.
func active_unit() -> Unit:
	return null


## The player whose turn it is (whose hand is shown), or -1.
func current_player() -> int:
	return -1


func can_play_card(player_index: int) -> bool:
	return not game.is_over() and player_index == current_player()


## True if the player may pick `unit` now (to make it the active unit).
func can_select(_unit: Unit) -> bool:
	return false


## Picks a unit to act. Returns true if it is now the active unit.
func select_unit(_unit: Unit) -> bool:
	return false


## Ends the current turn (what a "turn" is depends on the core).
func end_turn() -> void:
	pass


## Label for the end-turn button.
func end_turn_label() -> String:
	return "End turn"


## Units that will act next, in order (for a turn order bar). Empty if the
## core has no fixed order.
func upcoming(_count: int) -> Array[Unit]:
	return []


## One line describing the turn state.
func status_text() -> String:
	return ""


func _on_unit_summoned(_event: GameEvent) -> void:
	pass


func _on_unit_died(_event: GameEvent) -> void:
	pass


func _start_unit_turn(unit: Unit) -> void:
	game.bus.emit_new(GameEvents.TURN_STARTED, null, unit)


func _end_unit_turn(unit: Unit) -> void:
	if unit.alive:
		game.bus.emit_new(GameEvents.TURN_ENDED, null, unit)


func _start_player_turn(player_index: int) -> void:
	game.bus.emit_new(GameEvents.PLAYER_TURN_STARTED, null, null, {"player": player_index})


func _end_player_turn(player_index: int) -> void:
	game.bus.emit_new(GameEvents.PLAYER_TURN_ENDED, null, null, {"player": player_index})
