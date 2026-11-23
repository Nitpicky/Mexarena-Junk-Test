class_name Combat
extends RefCounted
## Basic combat helpers: damage, healing, attacks. Static, stateless.
##
## Attribute ids used: hp (pool), attack (damage), range (default 1).
## Every hit goes through BEFORE_DAMAGE (editable amount, cancellable) and
## DAMAGED events, so attribute behaviors can react (thorns, on-hit poison...).
## A unit whose hp reaches 0 dies.

const HP := &"hp"
const ATTACK := &"attack"
const RANGE := &"range"


## Deals damage. Returns the hp actually removed.
static func deal_damage(game: TacticsMatch, source: Unit, target: Unit, amount: float, tags: PackedStringArray = PackedStringArray()) -> float:
	if game == null or target == null or not target.alive or not target.attributes.has(HP):
		return 0.0
	var before := game.bus.emit_new(GameEvents.BEFORE_DAMAGE, source, target, {"amount": amount, "tags": tags})
	if before.cancelled:
		return 0.0
	var final_amount := maxf(0.0, float(before.get_value("amount", amount)))
	var dealt := -target.attributes.add_current(HP, -final_amount)
	game.bus.emit_new(GameEvents.DAMAGED, source, target, {"amount": dealt, "tags": tags})
	if target.alive and target.attributes.current(HP) <= 0.0:
		game.kill(target, source)
	return dealt


## Heals. Returns the hp actually restored.
static func heal(game: TacticsMatch, source: Unit, target: Unit, amount: float, tags: PackedStringArray = PackedStringArray()) -> float:
	if game == null or target == null or not target.alive or not target.attributes.has(HP):
		return 0.0
	var healed := target.attributes.add_current(HP, maxf(0.0, amount))
	if healed > 0.0:
		game.bus.emit_new(GameEvents.HEALED, source, target, {"amount": healed, "tags": tags})
	return healed


## Why `attacker` cannot attack `target` now, or "" if it can.
static func attack_problem(game: TacticsMatch, attacker: Unit, target: Unit) -> String:
	if attacker == null or target == null or not attacker.alive or not target.alive:
		return "No valid target."
	if attacker.team == target.team:
		return "Cannot attack an ally."
	if not attacker.attributes.has(ATTACK):
		return "%s has no attack." % attacker.display_name
	if attacker.attacks_left <= 0:
		return "%s already attacked this turn." % attacker.display_name
	if game.board.distance(attacker, target) > attacker.stat(RANGE, 1.0) + 0.001:
		return "Out of range."
	return ""


## One attack: spends the attacker's attack for the turn and deals its attack value.
static func attack(game: TacticsMatch, attacker: Unit, target: Unit) -> bool:
	if not attack_problem(game, attacker, target).is_empty():
		return false
	attacker.attacks_left -= 1
	game.bus.emit_new(GameEvents.ATTACKED, attacker, target)
	deal_damage(game, attacker, target, attacker.stat(ATTACK), PackedStringArray(["attack"]))
	return true
