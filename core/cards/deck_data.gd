class_name DeckData
extends Resource
## A list of cards to build a deck zone from.
## PROTOTYPE: placeholder deck sourcing. How players get cards (draft, prebuilt,
## buy during the match) is a future swappable core.

@export var display_name: String
@export var cards: Array[CardData] = []


func build_zone(owner_index: int) -> CardZone:
	var zone := CardZone.new("deck", owner_index)
	for card: CardData in cards:
		if card:
			zone.cards.append(card)
	return zone
