class_name MatchConfig
extends Resource
## Everything a match needs: players, the map core, the turn core and the rules.
## Swapping a core = pointing to another scene here.

## In turn order. For 2v2, alternate teams: A1, B1, A2, B2.
@export var players: Array[PlayerConfig] = []
## A scene whose root extends MapCore (hex grid, free space...).
@export var map_scene: PackedScene
## A scene whose root extends TurnCore (player phase, CTB...).
@export var turn_scene: PackedScene
## Optional rule modules (win condition, card draw...). Each is copied per match.
@export var rules: Array[MatchRule] = []
## 0 = random.
@export var random_seed: int = 0
