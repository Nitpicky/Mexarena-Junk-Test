class_name GeneralsWinRule
extends MatchRule
## A team that has lost all its Generals is eliminated. The last team standing
## wins. Generals are units holding the "general" attribute.

var _game: TacticsMatch
var _eliminated: Array[int] = []


func setup(game: TacticsMatch) -> void:
	_game = game
	_eliminated.clear()
	game.bus.subscribe(GameEvents.UNIT_DIED, _on_unit_died)
	game.bus.subscribe(GameEvents.ATTRIBUTE_REMOVED, _on_attribute_removed)


func _on_unit_died(_event: GameEvent) -> void:
	_check()


func _on_attribute_removed(event: GameEvent) -> void:
	var attribute: Attribute = event.get_value("attribute")
	if attribute and attribute.id == TacticsMatch.GENERAL_ID:
		_check()


func _check() -> void:
	if _game.is_over():
		return
	var standing: Array[int] = []
	for team: int in _game.teams():
		if _eliminated.has(team):
			continue
		var has_general := false
		for unit: Unit in _game.living_units(team):
			if unit.is_general():
				has_general = true
				break
		if has_general:
			standing.append(team)
		else:
			_eliminated.append(team)
			_game.bus.emit_new(GameEvents.TEAM_ELIMINATED, null, null, {"team": team})
	if standing.size() <= 1:
		_game.end_match(standing[0] if standing.size() == 1 else -1)
