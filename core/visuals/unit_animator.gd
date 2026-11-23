class_name UnitAnimator
extends AnimatedSprite2D
## Animated sprite body for a Unit, driven by match events. Optional module.
##
## Uses the SpriteFrames named by the unit's card (CardData.sprite_frames).
## Units whose card has none keep the placeholder disc. Attach with
## UnitAnimator.attach(unit, game), for example on TacticsMatch.unit_added.
##
## Animations used (name aliases in ALIASES, missing ones are skipped):
##   breathing  rest loop, when it is not the unit's turn
##   idle       rest loop during the unit's turn
##   run        while sliding to a new spot
##   attack     melee attack (and ranged attack without cast)
##   cast       ranged attack (if the sprite has it)
##   caststart, castloop, castend
##              a General summoning a card next to it (falls back to cast)
##   projectile flies from attacker to target on a ranged attack
##   hit        when damaged
##   death      on death, as a corpse left behind that fades out
## Game logic never waits for animations: they only decorate what happened.

const ALIASES := {
	&"breathing": [&"breathing", &"breathe", &"breath", &"idle"],
	&"idle": [&"idle", &"breathing", &"breathe", &"breath"],
	&"run": [&"run", &"movement", &"move", &"crawl"],
	&"attack": [&"attack"],
	&"cast": [&"cast"],
	&"projectile": [&"projectile"],
	&"hit": [&"hit", &"hurt", &"damage"],
	&"death": [&"death"],
}
## Pixels per second when sliding between spots.
const MOVE_SPEED := 260.0
const PROJECTILE_SPEED := 700.0
## Seconds a looping step (castloop) is held inside a one-shot sequence.
const LOOP_HOLD := 0.5
## Where the feet sit, below the unit's center, as a fraction of its radius.
const FEET := 0.45

static var _feet_cache: Dictionary = {} # SpriteFrames -> float (feet y from frame center)

var unit: Unit
var game: TacticsMatch
var _units_root: Node2D
var _base_position: Vector2
var _move_tween: Tween
## One-shot animations still to play, in order (cast steps).
var _queue: Array[StringName] = []


## Adds an animated body to `unit` if its card has sprite frames. Returns it or null.
static func attach(p_unit: Unit, p_game: TacticsMatch) -> UnitAnimator:
	var card := p_unit.source_card as CardData
	if card == null or card.sprite_frames == null:
		return null
	var animator := UnitAnimator.new()
	animator.unit = p_unit
	animator.game = p_game
	animator.name = "Sprite"
	animator.sprite_frames = card.sprite_frames
	animator._setup()
	p_unit.add_body_visual(animator)
	return animator


## Finds the first animation of `wanted` (or its aliases) in `frames`.
static func resolve(frames: SpriteFrames, wanted: StringName) -> StringName:
	for name: StringName in ALIASES.get(wanted, [wanted]):
		if frames.has_animation(name):
			return name
	return &""


## Vertical offset that puts the sprite's feet on (0, 0), for any SpriteFrames.
static func feet_offset(frames: SpriteFrames) -> float:
	if _feet_cache.has(frames):
		return _feet_cache[frames]
	var result := 0.0
	var rest := resolve(frames, &"breathing")
	if rest != &"" and frames.get_frame_count(rest) > 0:
		var image := frames.get_frame_texture(rest, 0).get_image()
		if image:
			if image.is_compressed():
				image.decompress()
			var bottom := image.get_height() - 1
			var found := false
			while bottom > 0 and not found:
				for x: int in image.get_width():
					if image.get_pixel(x, bottom).a > 0.5:
						found = true
						break
				if not found:
					bottom -= 1
			result = float(image.get_height()) / 2.0 - float(bottom)
	_feet_cache[frames] = result
	return result


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	offset = Vector2(0, feet_offset(sprite_frames))
	_base_position = Vector2(0, unit.radius() * FEET)
	position = _base_position
	animation_finished.connect(_on_animation_finished)
	var bus := game.bus
	bus.subscribe(GameEvents.TURN_STARTED, _on_turn_changed)
	bus.subscribe(GameEvents.TURN_ENDED, _on_turn_changed)
	bus.subscribe(GameEvents.UNIT_MOVED, _on_moved)
	bus.subscribe(GameEvents.ATTACKED, _on_attacked)
	bus.subscribe(GameEvents.DAMAGED, _on_damaged)
	bus.subscribe(GameEvents.CARD_PLAYED, _on_card_played)
	bus.subscribe(GameEvents.UNIT_DIED, _on_died)
	_face_enemy_side()
	_play_rest()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and game and is_instance_valid(game):
		game.bus.unsubscribe_object(self)


func _enter_tree() -> void:
	if unit.get_parent() is Node2D:
		_units_root = unit.get_parent() as Node2D


## Plays `wanted` (by alias) once, then returns to the rest loop.
func play_once(wanted: StringName) -> bool:
	var name := resolve(sprite_frames, wanted)
	if name == &"":
		return false
	_queue.clear()
	play(name)
	return true


func _on_animation_finished() -> void:
	if _queue.is_empty():
		_play_rest()
		return
	var name: StringName = _queue.pop_front()
	play(name)
	if sprite_frames.get_animation_loop(name):
		# Looping steps never finish on their own: hold them briefly.
		get_tree().create_timer(LOOP_HOLD).timeout.connect(_end_loop_step.bind(name))


func _end_loop_step(name: StringName) -> void:
	if is_instance_valid(self) and animation == name:
		_on_animation_finished()


func _play_rest() -> void:
	if unit == null or not unit.alive:
		return
	if _move_tween and _move_tween.is_running():
		_play_loop(&"run")
		return
	var active := game.turns != null and game.turns.active_unit() == unit
	_play_loop(&"idle" if active else &"breathing")


func _play_loop(wanted: StringName) -> void:
	var name := resolve(sprite_frames, wanted)
	if name == &"":
		return
	if animation != name or not is_playing():
		play(name)


func _face(target_local: Vector2) -> void:
	if absf(target_local.x - unit.position.x) > 1.0:
		flip_h = target_local.x < unit.position.x


func _face_enemy_side() -> void:
	var board := game.board
	if board:
		flip_h = unit.position.x > board.get_bounds().get_center().x


func _on_turn_changed(event: GameEvent) -> void:
	if event.target == unit:
		# The turn core updates its active unit after the event: pick the loop later.
		_play_rest.call_deferred()


func _on_moved(event: GameEvent) -> void:
	if event.target != unit:
		return
	var from: Vector2 = event.get_value("from", unit.position)
	var to: Vector2 = event.get_value("to", unit.position)
	_face(from + (to - from) * 2.0)
	if _move_tween:
		_move_tween.kill()
	position = _base_position + (from - to)
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", _base_position, from.distance_to(to) / MOVE_SPEED)
	_move_tween.finished.connect(_play_rest)
	_play_loop(&"run")


func _on_attacked(event: GameEvent) -> void:
	if event.source != unit:
		return
	var target := event.target as Unit
	if target == null:
		return
	_face(target.position)
	var ranged := game.board.distance(unit, target) > 1.0 or unit.stat(&"range", 1.0) > 1.0
	if ranged:
		if not _play_cast():
			play_once(&"attack")
		_shoot(target)
	else:
		play_once(&"attack")


## "cast", else the cast steps. False if the sprite has neither.
func _play_cast() -> bool:
	return play_once(&"cast") or _play_cast_steps()


## caststart, castloop (held briefly), castend; else "cast". False if none.
func _play_cast_steps() -> bool:
	var steps: Array[StringName] = []
	for name: StringName in [&"caststart", &"castloop", &"castend"]:
		if sprite_frames.has_animation(name):
			steps.append(name)
	if steps.is_empty():
		return play_once(&"cast")
	_queue = steps
	_on_animation_finished()
	return true


func _shoot(target: Unit) -> void:
	var name := resolve(sprite_frames, &"projectile")
	if name == &"" or _units_root == null:
		return
	var shot := AnimatedSprite2D.new()
	shot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shot.sprite_frames = sprite_frames
	shot.z_index = 2
	var start := unit.position + Vector2(0, -unit.radius() * 0.6)
	var end := target.position + Vector2(0, -target.radius() * 0.6)
	shot.position = start
	shot.rotation = (end - start).angle()
	_units_root.get_parent().add_child(shot)
	shot.play(name)
	var tween := shot.create_tween()
	tween.tween_interval(0.25)
	tween.tween_property(shot, "position", end, start.distance_to(end) / PROJECTILE_SPEED)
	tween.tween_callback(shot.queue_free)


func _on_damaged(event: GameEvent) -> void:
	if event.target == unit and unit.alive and float(event.get_value("amount", 0.0)) > 0.0:
		var delay := 0.35 if event.has_tag("attack") and event.source is Unit and event.source != unit else 0.0
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
			if not is_instance_valid(self) or not unit.alive:
				return
		play_once(&"hit")


## A General plays its cast when its player summons a card next to it.
func _on_card_played(event: GameEvent) -> void:
	if not unit.alive or not unit.is_general():
		return
	var summoned := event.target as Unit
	if summoned == null or summoned.team != unit.team or int(event.get_value("player", -1)) != unit.player_index:
		return
	_face(summoned.position)
	_play_cast_steps()


## Leaves a corpse that plays the death animation and fades out.
func _on_died(event: GameEvent) -> void:
	if event.target != unit or _units_root == null or not is_instance_valid(_units_root):
		return
	var name := resolve(sprite_frames, &"death")
	if name == &"":
		return
	var corpse := AnimatedSprite2D.new()
	corpse.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	corpse.sprite_frames = sprite_frames
	corpse.offset = offset
	corpse.flip_h = flip_h
	corpse.position = unit.position + _base_position
	_units_root.add_child(corpse)
	corpse.play(name)
	var tween := corpse.create_tween()
	tween.tween_interval(maxf(0.2, float(sprite_frames.get_frame_count(name)) / maxf(sprite_frames.get_animation_speed(name), 1.0)))
	tween.tween_property(corpse, "modulate:a", 0.0, 0.6)
	tween.tween_callback(corpse.queue_free)
