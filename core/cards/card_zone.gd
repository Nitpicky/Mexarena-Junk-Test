class_name CardZone
extends RefCounted
## An ordered pile of cards: a deck, a hand, a discard pile...
## The top of the pile is the end of the array.

signal changed

var zone_name: String
var owner_index: int = -1
## -1 = no limit.
var max_size: int = -1
var cards: Array[CardData] = []


func _init(p_name: String = "", p_owner: int = -1, p_max_size: int = -1) -> void:
	zone_name = p_name
	owner_index = p_owner
	max_size = p_max_size


func size() -> int:
	return cards.size()


func is_empty() -> bool:
	return cards.is_empty()


func is_full() -> bool:
	return max_size >= 0 and cards.size() >= max_size


func has(card: CardData) -> bool:
	return cards.has(card)


## Returns false when the zone is full.
func add(card: CardData) -> bool:
	if card == null or is_full():
		return false
	cards.append(card)
	changed.emit()
	return true


func remove(card: CardData) -> bool:
	var index := cards.find(card)
	if index < 0:
		return false
	cards.remove_at(index)
	changed.emit()
	return true


## Takes the top card, or null when empty.
func draw_top() -> CardData:
	if cards.is_empty():
		return null
	var card: CardData = cards.pop_back()
	changed.emit()
	return card


func shuffle(rng: RandomNumberGenerator) -> void:
	for i: int in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := cards[i]
		cards[i] = cards[j]
		cards[j] = swap
	changed.emit()
