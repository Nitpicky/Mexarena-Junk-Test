extends RefCounted
## Logic checks for the tactics core modules (attributes, events, cards,
## match, map cores, turn cores, combat). Run by tools/smoke_test.gd.
## Builds its own cards in code, so it depends on core/ only, never on a sandbox.

const MAP_SCENES := {
	"hex": "res://core/board/hex/hex_map.tscn",
	"free": "res://core/board/free/free_map.tscn",
}
const TURN_SCENES := {
	"phase": "res://core/turns/player_phase/player_phase_turns.tscn",
	"ctb": "res://core/turns/ctb/ctb_turns.tscn",
}

var _failures: Array[String] = []
var _checks: int = 0
var _context := ""


func run(host: Node) -> Array[String]:
	_test_event_bus()
	_test_attribute_merge_and_modifiers()
	_test_durations_and_behaviors()
	_test_hex_distance(host)
	for map_key: String in MAP_SCENES:
		for turn_key: String in TURN_SCENES:
			_context = "%s+%s: " % [map_key, turn_key]
			await _test_match(host, map_key, turn_key)
	_context = ""
	await _test_player_phase_rules(host)
	await _test_ctb_order(host)
	await _test_two_vs_two(host)
	print("      tactics core: %d checks" % _checks)
	return _failures


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(_context + message)


# --- helpers -----------------------------------------------------------------

static func stat(id: StringName, value: float, pool: bool = false) -> Attribute:
	var attribute := Attribute.new()
	attribute.id = id
	attribute.base_value = value
	attribute.is_pool = pool
	return attribute


static func card(card_name: String, hp: float, attack: float, movement: float, speed: float, attack_range: float = 1.0) -> CardData:
	var result := CardData.new()
	result.id = StringName(card_name.to_snake_case())
	result.display_name = card_name
	result.attributes = [stat(&"hp", hp, true), stat(&"attack", attack), stat(&"movement", movement), stat(&"speed", speed), stat(&"range", attack_range)]
	return result


func _config(map_key: String, turn_key: String, player_count: int = 2) -> MatchConfig:
	var config := MatchConfig.new()
	config.map_scene = load(MAP_SCENES[map_key])
	config.turn_scene = load(TURN_SCENES[turn_key])
	config.random_seed = 7
	var deck := DeckData.new()
	for i: int in 6:
		deck.cards.append(card("Soldier", 5, 2, 3, 10))
	for i: int in player_count:
		var player := PlayerConfig.new()
		player.display_name = "P%d" % (i + 1)
		player.team = i % 2
		player.general = card("General", 20, 3, 3, 12 - i)
		player.deck = deck
		config.players.append(player)
	config.rules = [GeneralsWinRule.new(), CardPlayRule.new()]
	return config


func _start(host: Node, config: MatchConfig) -> TacticsMatch:
	var game := TacticsMatch.new()
	host.add_child(game)
	game.setup(config)
	game.start()
	await host.get_tree().process_frame
	return game


# --- tests -------------------------------------------------------------------

func _test_event_bus() -> void:
	_context = "bus: "
	var bus := EventBus.new()
	var order: Array[String] = []
	bus.subscribe(&"ping", func(_e: GameEvent) -> void: order.append("low"), 0)
	bus.subscribe(&"ping", func(_e: GameEvent) -> void: order.append("high"), 10)
	bus.subscribe(EventBus.ANY, func(_e: GameEvent) -> void: order.append("any"))
	bus.emit_new(&"ping")
	_check(order == ["high", "low", "any"], "priority order, got %s" % [order])
	var stopper := func(e: GameEvent) -> void: e.cancelled = true
	bus.subscribe(&"pong", stopper, 5)
	bus.subscribe(&"pong", func(_e: GameEvent) -> void: order.append("late"))
	var event := bus.emit_new(&"pong")
	_check(event.cancelled and not order.has("late"), "cancel stops later listeners")
	bus.unsubscribe(&"pong", stopper)
	bus.emit_new(&"pong")
	_check(order.has("late"), "unsubscribe works")


func _test_attribute_merge_and_modifiers() -> void:
	_context = "attributes: "
	var set := AttributeSet.new()
	var poison := stat(&"poison", 2)
	poison.duration = 2
	set.add(poison)
	var second := stat(&"poison", 3)
	second.duration = 4
	set.add(second)
	_check(set.all().size() == 1, "two poisons merge into one")
	_check(is_equal_approx(set.value(&"poison"), 5.0), "merged poison adds values, got %s" % set.value(&"poison"))
	_check(set.get_attribute(&"poison").duration == 4, "merge keeps the longer duration")
	_check(poison.base_value == 2.0, "templates are never modified")

	set.add(stat(&"attack", 4))
	var frenzy := stat(&"frenzy", 0)
	var add := AttributeModifier.new()
	add.target_id = &"attack"
	add.amount = 2
	var pct := AttributeModifier.new()
	pct.target_id = &"attack"
	pct.op = AttributeModifier.Op.PERCENT
	pct.amount = 50
	frenzy.modifiers = [add, pct]
	set.add(frenzy)
	_check(is_equal_approx(set.value(&"attack"), 9.0), "(4 + 2) x 1.5 = 9, got %s" % set.value(&"attack"))
	set.remove(&"frenzy")
	_check(is_equal_approx(set.value(&"attack"), 4.0), "modifiers vanish with their attribute")
	_check(is_equal_approx(set.value(&"movement", -1.0), -1.0), "missing attribute gives the default")

	set.add(stat(&"hp", 10, true))
	_check(is_equal_approx(set.current(&"hp"), 10.0), "pools start full")
	set.add_current(&"hp", -15)
	_check(is_equal_approx(set.current(&"hp"), 0.0), "pools clamp at 0")


func _test_durations_and_behaviors() -> void:
	_context = "behaviors: "
	var bus := EventBus.new()
	var holder := RefCounted.new()
	var set := AttributeSet.new(holder)
	set.bind(bus, null)
	var buff := stat(&"shield", 1)
	buff.duration = 2
	set.add(buff)
	bus.emit_new(GameEvents.TURN_ENDED, null, holder)
	_check(set.has(&"shield"), "duration 2 survives one turn end")
	bus.emit_new(GameEvents.TURN_ENDED, null, RefCounted.new())
	_check(set.get_attribute(&"shield").duration == 1, "other holders' turn ends do not count")
	bus.emit_new(GameEvents.TURN_ENDED, null, holder)
	_check(not set.has(&"shield"), "expires after its duration")
	set.unbind()


func _test_hex_distance(host: Node) -> void:
	_context = "hex: "
	var map := (load(MAP_SCENES["hex"]) as PackedScene).instantiate() as HexMap
	host.add_child(map)
	var tiles := map.get_node(^"Tiles") as TileMapLayer
	# Compare hex_distance against a breadth-first walk over Godot's own neighbors.
	var start := Vector2i(4, 3)
	var dist: Dictionary = {start: 0}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if dist[cell] >= 5:
			continue
		for next: Vector2i in tiles.get_surrounding_cells(cell):
			if not dist.has(next):
				dist[next] = dist[cell] + 1
				queue.append(next)
	var wrong := 0
	for cell: Vector2i in dist:
		if HexMap.hex_distance(start, cell) != dist[cell]:
			wrong += 1
	_check(wrong == 0, "hex_distance disagrees with TileMapLayer neighbors on %d cells" % wrong)
	map.free()


func _test_match(host: Node, map_key: String, turn_key: String) -> void:
	var game := await _start(host, _config(map_key, turn_key))
	_check(game.units.size() == 2, "both Generals summoned")
	_check(game.units.all(func(u: Unit) -> bool: return u.is_general()), "Generals carry the general attribute")
	_check(game.players[0].hand.size() >= 3, "starting hand drawn")

	var active := game.turns.active_unit()
	var player := game.turns.current_player()
	if turn_key == "phase":
		_check(active == null, "no unit active before picking one")
		var mine: Unit = game.units.filter(func(u: Unit) -> bool: return u.player_index == player)[0]
		_check(game.turns.select_unit(mine), "can pick own General")
		active = game.turns.active_unit()
	_check(active != null and active.player_index == player, "an active unit for the current player")
	_check(is_equal_approx(active.moves_left, 3.0), "movement locked at turn start, got %s" % active.moves_left)

	# Summon next to the General.
	var hand_card: CardData = game.players[player].hand.cards[0]
	var spot := _free_spot_near(game, active)
	var summoned := game.play_card(player, hand_card, spot)
	_check(summoned != null, "card summons a unit near the General")
	if summoned:
		_check(summoned.attributes.has(&"hp") and not summoned.is_general(), "summoned unit gets card attributes only")
		_check(game.players[player].card_plays_left == 0, "one card play per turn")

	# Move.
	var before := active.position
	var moved := false
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var target := game.board.to_global(active.position + direction * 80.0)
		if game.board.can_move_to(active, target) and game.board.move_unit(active, target):
			moved = true
			break
	_check(moved and active.position != before, "active unit can move")
	_check(active.moves_left < 3.0 or map_key == "free", "moving spends tiles on hex")

	# Poison ticks at turn start and merges.
	var enemy: Unit = game.living_units().filter(func(u: Unit) -> bool: return u.team != active.team)[0]
	var poison := stat(&"poison", 2)
	poison.duration = 3
	poison.tags = PackedStringArray(["status"])
	poison.behaviors = [DamageOverTimeBehavior.new()]
	enemy.attributes.add(poison)
	enemy.attributes.add(poison)
	_check(is_equal_approx(enemy.attributes.value(&"poison"), 4.0), "poison merged to 4")
	var hp_before := enemy.attributes.current(&"hp")
	game.bus.emit_new(GameEvents.TURN_STARTED, null, enemy)
	_check(is_equal_approx(enemy.attributes.current(&"hp"), hp_before - 4.0), "poison ticks on its holder's turn start")

	# Attack in range.
	enemy.attributes.remove(&"poison")
	game.board.remove_unit(enemy)
	var adjacent := _free_spot_near(game, active)
	var placed := game.board.place_unit(enemy, adjacent)
	_check(placed, "test setup: enemy moved next to attacker")
	if placed:
		var hp := enemy.attributes.current(&"hp")
		_check(Combat.attack(game, active, enemy), "attack in range works: %s" % Combat.attack_problem(game, active, enemy))
		_check(is_equal_approx(enemy.attributes.current(&"hp"), hp - 3.0), "attack removes hp")
		_check(not Combat.attack(game, active, enemy), "only one attack per turn")

	# Thorns.
	var thorns := stat(&"thorns", 2)
	thorns.behaviors = [ReflectDamageBehavior.new()]
	enemy.attributes.add(thorns)
	active.attacks_left = 1
	var attacker_hp := active.attributes.current(&"hp")
	Combat.attack(game, active, enemy)
	_check(is_equal_approx(active.attributes.current(&"hp"), attacker_hp - 2.0), "thorns hurt the attacker")

	# End turn passes to the other side.
	game.turns.end_turn()
	await host.get_tree().process_frame
	if turn_key == "phase":
		_check(game.turns.current_player() != player, "end phase passes to the next player")

	# Killing the enemy General ends the match.
	Combat.deal_damage(game, active, enemy, 999)
	await host.get_tree().process_frame
	_check(game.is_over(), "match ends when a team has no General")
	_check(game.winning_team == active.team, "the other team wins")
	game.free()
	await host.get_tree().process_frame


func _free_spot_near(game: TacticsMatch, unit: Unit) -> Vector2:
	var step := 64.0
	for ring: int in range(1, 4):
		for i: int in 12:
			var offset := Vector2.from_angle(TAU * i / 12.0) * step * ring
			var world := game.board.to_global(unit.position + offset)
			if game.board.can_summon_at(unit.player_index, world):
				return world
	return game.board.to_global(unit.position + Vector2(step, 0))


func _test_player_phase_rules(host: Node) -> void:
	_context = "player phase: "
	var game := await _start(host, _config("hex", "phase"))
	var turns := game.turns as PlayerPhaseTurns
	var player := turns.current_player()
	var general: Unit = game.units.filter(func(u: Unit) -> bool: return u.player_index == player)[0]
	var soldier := game.play_card(player, game.players[player].hand.cards[0], _free_spot_near(game, general))
	_check(soldier != null, "summon works")
	_check(not turns.can_select(soldier), "a unit summoned this phase waits")
	turns.select_unit(general)
	turns.end_turn()
	turns.end_turn()
	_check(turns.current_player() == player, "back to the first player after a round")
	_check(turns.select_unit(soldier), "summoned unit acts next phase")
	_check(turns.select_unit(general), "picking another unit works")
	_check(not turns.can_select(soldier), "cannot return to a unit after switching away")
	game.free()
	await host.get_tree().process_frame


func _test_ctb_order(host: Node) -> void:
	_context = "ctb: "
	var config := _config("free", "ctb")
	config.players[0].general = card("Fast", 20, 3, 3, 20)
	config.players[1].general = card("Slow", 20, 3, 3, 10)
	var game := await _start(host, config)
	var fast: Unit = game.units[0]
	var slow: Unit = game.units[1]
	_check(game.turns.active_unit() == fast, "the faster unit goes first")
	var order := game.turns.upcoming(4)
	_check(order.size() == 4, "turn order preview has 4 entries")
	var fast_count := order.filter(func(u: Unit) -> bool: return u == fast).size()
	_check(fast_count >= 2, "twice the speed, about twice the turns (got %d of 4)" % fast_count)
	game.turns.end_turn()
	_check(game.turns.active_unit() == order[0], "preview matches the real order")
	_check(slow.alive, "sanity")
	game.free()
	await host.get_tree().process_frame


func _test_two_vs_two(host: Node) -> void:
	_context = "2v2: "
	for map_key: String in MAP_SCENES:
		var game := await _start(host, _config(map_key, "phase", 4))
		_check(game.units.size() == 4, "%s: four Generals" % map_key)
		_check(game.teams().size() == 2, "two teams")
		var team_b: Array[Unit] = game.living_units(1)
		Combat.deal_damage(game, null, team_b[0], 999)
		_check(not game.is_over(), "%s: a team with one General left keeps playing" % map_key)
		Combat.deal_damage(game, null, team_b[1], 999)
		_check(game.is_over() and game.winning_team == 0, "%s: team A wins when both B Generals fall" % map_key)
		game.free()
		await host.get_tree().process_frame
