extends RefCounted
## Checks for core/visuals (UnitAnimator): attaching, fallback, and that
## moves, attacks, casts, hits and deaths play without errors.
## Uses one sprite set from assets/ if present; skips the sprite checks if not.

const SPRITES := "res://assets/art/units/duelyst/f1_general.tres"
const RANGED_SPRITES := "res://assets/art/units/duelyst/f1_ranged.tres"
const Core := preload("res://tools/tests/test_tactics_core.gd")

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("visuals: " + message)


func run(host: Node) -> Array[String]:
	var config := MatchConfig.new()
	config.map_scene = load("res://core/board/free/free_map.tscn")
	config.turn_scene = load("res://core/turns/player_phase/player_phase_turns.tscn")
	config.random_seed = 3
	var has_art := ResourceLoader.exists(SPRITES) and ResourceLoader.exists(RANGED_SPRITES)
	for i: int in 2:
		var player := PlayerConfig.new()
		player.team = i
		player.general = Core.card("General", 20, 3, 3, 10, 4.0 if i == 0 else 1.0)
		if has_art and i == 0:
			player.general.sprite_frames = load(SPRITES)
		config.players.append(player)
	var game := TacticsMatch.new()
	host.add_child(game)
	game.setup(config)
	var animators: Array[UnitAnimator] = []
	game.unit_added.connect(func(unit: Unit) -> void:
		var animator := UnitAnimator.attach(unit, game)
		if animator:
			animators.append(animator))
	game.start()
	var mine: Unit = game.units[0]
	var theirs: Unit = game.units[1]
	_check(not theirs.has_sprite, "a card without sprite frames keeps the placeholder look")
	if not has_art:
		game.free()
		return _failures

	_check(mine.has_sprite and animators.size() == 1, "a card with sprite frames gets an animated body")
	var body := animators[0]
	_check(body.offset.y < 0.0, "feet offset lifts the sprite (got %s)" % body.offset.y)
	_check(body.is_playing(), "rest loop is playing")

	game.turns.select_unit(mine)
	await host.get_tree().process_frame
	_check(body.animation == &"idle", "idle during its turn, got %s" % body.animation)
	var target := game.board.to_global(mine.position + Vector2(60, 0))
	_check(game.board.move_unit(mine, target), "move works")
	_check(body.animation == &"run", "run while sliding, got %s" % body.animation)

	# Ranged attack: cast + projectile.
	game.board.remove_unit(theirs)
	_check(game.board.place_unit(theirs, game.board.to_global(mine.position + Vector2(170, 0))), "test setup: enemy placed in range")
	mine.attacks_left = 1
	_check(Combat.attack(game, mine, theirs), "ranged attack works: %s" % Combat.attack_problem(game, mine, theirs))
	_check(body.animation == &"cast", "ranged attack plays cast, got %s" % body.animation)

	# A summon next to the General plays the cast steps.
	var card := Core.card("Archer", 5, 2, 2, 10, 3)
	card.sprite_frames = load(RANGED_SPRITES)
	game.players[0].hand.add(card)
	game.players[0].card_plays_left = 1
	var summoned: Unit = null
	for i: int in 12:
		var spot := game.board.to_global(mine.position + Vector2.from_angle(TAU * i / 12.0) * 70.0)
		summoned = game.play_card(0, card, spot)
		if summoned:
			break
	_check(summoned != null and summoned.has_sprite, "summoned unit gets its card's sprite")
	_check(body.animation == &"caststart", "General plays caststart on a summon, got %s" % body.animation)
	await host.get_tree().create_timer(1.5).timeout
	_check(body.animation in [&"idle", &"breathing", &"castend", &"castloop"], "cast steps run on, got %s" % body.animation)

	# Death leaves a corpse playing the death animation.
	var root := game.board.units_root
	Combat.deal_damage(game, theirs, mine, 999)
	var corpse_found := false
	for child: Node in root.get_children():
		if child is AnimatedSprite2D and (child as AnimatedSprite2D).animation == &"death":
			corpse_found = true
	_check(corpse_found, "death leaves a corpse playing death")
	await host.get_tree().create_timer(0.3).timeout
	game.free()
	await host.get_tree().process_frame
	return _failures
