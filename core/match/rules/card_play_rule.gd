class_name CardPlayRule
extends MatchRule
## Starting hand, card draw and how many cards a player may play per turn.
## A player's "turn" is whatever the turn core calls a player turn: a whole
## phase in Player Phase, one unit's turn in CTB.
## Without this rule: no draws and unlimited plays.

@export var starting_hand: int = 3
@export var draw_per_turn: int = 1
## -1 = no limit.
@export var plays_per_turn: int = 1
## -1 = no limit.
@export var max_hand_size: int = 7

var _game: TacticsMatch


func setup(game: TacticsMatch) -> void:
	_game = game
	for player: PlayerState in game.players:
		player.hand.max_size = max_hand_size
	game.bus.subscribe(GameEvents.MATCH_STARTED, _on_match_started)
	game.bus.subscribe(GameEvents.PLAYER_TURN_STARTED, _on_player_turn_started)


func _on_match_started(_event: GameEvent) -> void:
	for player: PlayerState in _game.players:
		player.card_plays_left = 0
		for i: int in starting_hand:
			_game.draw_card(player.index)


func _on_player_turn_started(event: GameEvent) -> void:
	var index: int = event.get_value("player", -1)
	if index < 0 or index >= _game.players.size():
		return
	var player := _game.players[index]
	player.card_plays_left = plays_per_turn
	for i: int in draw_per_turn:
		_game.draw_card(index)
