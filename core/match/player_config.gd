class_name PlayerConfig
extends Resource
## Who plays: name, team, General and deck. Players with the same `team` are allies.

@export var display_name: String = "Player"
@export var team: int = 0
@export var color: Color = Color.CORNFLOWER_BLUE
## The card summoned as this player's General when the match starts.
@export var general: CardData
@export var deck: DeckData
