class_name PlayerState
extends RefCounted
## A player during a match: zones and per-turn counters.

var index: int = 0
var team: int = 0
var display_name: String = ""
var color: Color = Color.WHITE
var general_card: CardData
var deck: CardZone
var hand: CardZone
var discard: CardZone
## Cards this player may still play this turn. -1 = no limit.
var card_plays_left: int = -1


func _init(p_index: int, config: PlayerConfig, rng: RandomNumberGenerator) -> void:
	index = p_index
	team = config.team
	display_name = config.display_name
	color = config.color
	general_card = config.general
	deck = config.deck.build_zone(index) if config.deck else CardZone.new("deck", index)
	deck.shuffle(rng)
	hand = CardZone.new("hand", index)
	discard = CardZone.new("discard", index)


## Moves the top deck card to the hand. Returns it, or null.
func draw_card() -> CardData:
	if deck.is_empty() or hand.is_full():
		return null
	var card := deck.draw_top()
	hand.add(card)
	return card
