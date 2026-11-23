class_name TacticsMatch
extends Node
## One match: players, units, the event bus, and the plugged-in cores.
##
## The match knows the common frame only: summoning from cards, killing,
## card zones, teams. The map core (MapCore) decides where things can go, the
## turn core (TurnCore) decides who acts, and rule modules (MatchRule) add the
## rest (win condition, card draw...) through the event bus.
##
## Usage: var game := TacticsMatch.new(); add_child(game); game.setup(config); game.start()

signal unit_added(unit: Unit)
signal unit_removed(unit: Unit)
## Something visible changed (hand, active unit, values...). UI refresh hint.
signal state_changed
signal match_ended(winning_team: int)

## The attribute id that marks a General.
const GENERAL_ID := &"general"

var config: MatchConfig
var bus := EventBus.new()
var board: MapCore
var turns: TurnCore
var players: Array[PlayerState] = []
var units: Array[Unit] = []
var rules: Array[MatchRule] = []
var rng := RandomNumberGenerator.new()
## -2 = still running, -1 = draw, otherwise the winning team.
var winning_team: int = -2

var _next_unit_id: int = 1


## Builds players, cores and rules. `board_parent` is where the map node goes
## (defaults to this node).
func setup(p_config: MatchConfig, board_parent: Node = null) -> void:
	config = p_config
	if config.random_seed != 0:
		rng.seed = config.random_seed
	else:
		rng.randomize()
	for i: int in config.players.size():
		players.append(PlayerState.new(i, config.players[i], rng))
	bus.subscribe(GameEvents.TURN_STARTED, _on_turn_started, 100)
	bus.emitted.connect(_on_bus_emitted)

	board = config.map_scene.instantiate() as MapCore
	board.name = "Board"
	(board_parent if board_parent else self).add_child(board)
	board.setup(self)

	turns = config.turn_scene.instantiate() as TurnCore
	turns.name = "Turns"
	add_child(turns)
	turns.setup(self)

	for template: MatchRule in config.rules:
		if template == null:
			continue
		var rule := template.duplicate(true) as MatchRule
		rules.append(rule)
		rule.setup(self)


## Summons every General, deals starting hands, then starts the turn core.
func start() -> void:
	for player: PlayerState in players:
		if player.general_card == null:
			push_warning("TacticsMatch: %s has no General" % player.display_name)
			continue
		var marker := Attribute.new()
		marker.id = GENERAL_ID
		marker.display_name = "General"
		marker.tags = PackedStringArray(["role"])
		var extras: Array[Attribute] = [marker]
		summon(player.general_card, player.index, board.general_spawn(player), extras)
	bus.emit_new(GameEvents.MATCH_STARTED)
	turns.start()
	state_changed.emit()


func is_over() -> bool:
	return winning_team != -2


func teams() -> Array[int]:
	var result: Array[int] = []
	for player: PlayerState in players:
		if not result.has(player.team):
			result.append(player.team)
	return result


## Living units, optionally only those of one team.
func living_units(team: int = -1) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit: Unit in units:
		if unit.alive and (team < 0 or unit.team == team):
			result.append(unit)
	return result


func draw_card(player_index: int) -> CardData:
	var card := players[player_index].draw_card()
	if card:
		bus.emit_new(GameEvents.CARD_DRAWN, null, null, {"player": player_index, "card": card})
		state_changed.emit()
	return card


## Why `player_index` cannot play `card` at `world_pos` right now, or "" if they can.
func card_play_problem(player_index: int, card: CardData, world_pos: Vector2) -> String:
	if is_over():
		return "The match is over."
	var player := players[player_index]
	if not player.hand.has(card):
		return "That card is not in hand."
	if not turns.can_play_card(player_index):
		return "Not this player's turn."
	if player.card_plays_left == 0:
		return "No card plays left this turn."
	if not board.can_summon_at(player_index, world_pos):
		return "Cannot summon there (stay near a friendly General, on a free spot)."
	return ""


## Plays a card from hand: summons its unit at `world_pos`.
func play_card(player_index: int, card: CardData, world_pos: Vector2) -> Unit:
	if not card_play_problem(player_index, card, world_pos).is_empty():
		return null
	var unit := summon(card, player_index, world_pos)
	if unit == null:
		return null
	var player := players[player_index]
	player.hand.remove(card)
	if player.card_plays_left > 0:
		player.card_plays_left -= 1
	bus.emit_new(GameEvents.CARD_PLAYED, null, unit, {"player": player_index, "card": card})
	state_changed.emit()
	return unit


## Creates a unit from a card for a player, with optional extra attributes.
## Returns null if the board refuses the spot.
func summon(card: CardData, player_index: int, world_pos: Vector2, extra: Array[Attribute] = []) -> Unit:
	var player := players[player_index]
	var unit := Unit.new()
	unit.unit_id = _next_unit_id
	_next_unit_id += 1
	unit.display_name = card.label()
	unit.name = "%s_%d" % [String(card.id) if card.id != &"" else "unit", unit.unit_id]
	unit.player_index = player_index
	unit.team = player.team
	unit.color = player.color
	unit.source_card = card
	unit.attributes.bind(bus, self)
	for attribute: Attribute in card.attributes:
		if attribute:
			unit.attributes.add(attribute)
	for attribute: Attribute in extra:
		unit.attributes.add(attribute)
	if not board.place_unit(unit, world_pos):
		unit.attributes.unbind()
		unit.free()
		return null
	units.append(unit)
	unit_added.emit(unit)
	bus.emit_new(GameEvents.UNIT_SUMMONED, null, unit, {"player": player_index, "card": card})
	state_changed.emit()
	return unit


## Removes a unit from play. Its card goes to its owner's discard pile.
func kill(unit: Unit, killer: Object = null) -> void:
	if unit == null or not unit.alive:
		return
	unit.alive = false
	units.erase(unit)
	board.remove_unit(unit)
	if unit.source_card is CardData and unit.player_index >= 0:
		players[unit.player_index].discard.add(unit.source_card as CardData)
	bus.emit_new(GameEvents.UNIT_DIED, killer, unit)
	unit.attributes.unbind()
	unit_removed.emit(unit)
	unit.queue_free()
	state_changed.emit()


func end_match(p_winning_team: int) -> void:
	if is_over():
		return
	winning_team = p_winning_team
	bus.emit_new(GameEvents.MATCH_ENDED, null, null, {"winning_team": winning_team})
	match_ended.emit(winning_team)
	state_changed.emit()


func team_name(team: int) -> String:
	return "Team %s" % char(65 + team) if team >= 0 else "Nobody"


func _on_turn_started(event: GameEvent) -> void:
	var unit := event.target as Unit
	if unit:
		unit.attacks_left = 1


func _on_bus_emitted(_event: GameEvent) -> void:
	state_changed.emit()
