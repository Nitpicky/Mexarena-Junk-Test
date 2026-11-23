extends Node2D
## PROTOTYPE: hotseat sandbox for the tactics core. Pick a map core (hex grid
## or free space), a turn core (Player Phase or CTB), 1v1 or 2v2 and each
## player's General, then play on one screen.
##
## Everything game-related lives in core/ (attributes, events, cards, match,
## board, turns, combat). This scene only builds a MatchConfig, turns clicks
## into match calls and shows the HUD.

const SetupPanel := preload("res://sandboxes/tactics_arena/setup_panel.gd")
const MatchHud := preload("res://sandboxes/tactics_arena/match_hud.gd")

const MAP_CORES := {
	"Hex grid": "res://core/board/hex/hex_map.tscn",
	"Free space": "res://core/board/free/free_map.tscn",
}
const TURN_CORES := {
	"Player Phase": "res://core/turns/player_phase/player_phase_turns.tscn",
	"CTB": "res://core/turns/ctb/ctb_turns.tscn",
}
## Player colors in MatchConfig order (A1, B1, A2, B2): team A blue, team B red.
const PLAYER_COLORS: Array[Color] = [Color(0.35, 0.6, 1.0), Color(1.0, 0.4, 0.35), Color(0.4, 0.9, 0.95), Color(1.0, 0.7, 0.3)]
## Screen space the HUD leaves for the board: left, top, right, bottom margins.
const BOARD_MARGINS := Vector4(260, 84, 310, 140)

## Cards offered as Generals on the setup screen.
@export var general_cards: Array[CardData] = []
## PROTOTYPE: every player gets this deck until deck sourcing is designed.
@export var deck: DeckData
@export var card_play_rule: CardPlayRule

var _game: TacticsMatch
var _hud: Control
var _setup: Control
var _pending_card: CardData

@onready var _camera: Camera2D = $Camera2D
@onready var _world: Node2D = $World
@onready var _ui: CanvasLayer = $UI


func _ready() -> void:
	_show_setup()


func _show_setup() -> void:
	_clear_match()
	_setup = SetupPanel.new()
	_setup.map_names = PackedStringArray(MAP_CORES.keys())
	_setup.turn_names = PackedStringArray(TURN_CORES.keys())
	_setup.general_cards = general_cards
	_ui.add_child(_setup)
	_setup.build()
	_setup.start_requested.connect(_start_match)


func _start_match(map_name: String, turn_name: String, generals: Array[CardData]) -> void:
	var config := MatchConfig.new()
	config.map_scene = load(MAP_CORES[map_name])
	config.turn_scene = load(TURN_CORES[turn_name])
	config.rules = [GeneralsWinRule.new(), card_play_rule if card_play_rule else CardPlayRule.new()]
	for i: int in generals.size():
		var player := PlayerConfig.new()
		player.team = i % 2
		player.display_name = "P%d" % (i + 1)
		player.color = PLAYER_COLORS[i % PLAYER_COLORS.size()]
		player.general = generals[i]
		player.deck = deck
		config.players.append(player)

	if _setup:
		_setup.queue_free()
		_setup = null
	_game = TacticsMatch.new()
	_game.name = "Match"
	add_child(_game)
	_game.setup(config, _world)
	_hud = MatchHud.new()
	_ui.add_child(_hud)
	_hud.build(_game, "%s + %s" % [map_name, turn_name])
	_hud.end_turn_pressed.connect(_end_turn)
	_hud.card_selected.connect(_on_card_selected)
	_hud.setup_pressed.connect(_show_setup)
	_game.state_changed.connect(_refresh_board)
	_game.start()
	_frame_camera()
	_refresh_board()


func _clear_match() -> void:
	_pending_card = null
	if _hud:
		_hud.queue_free()
		_hud = null
	if _game:
		_game.queue_free()
		_game = null
	for child: Node in _world.get_children():
		child.queue_free()


func _frame_camera() -> void:
	var bounds := _game.board.get_bounds()
	bounds.position += _game.board.global_position
	var screen := get_viewport_rect().size
	var free_area := Rect2(BOARD_MARGINS.x, BOARD_MARGINS.y,
		screen.x - BOARD_MARGINS.x - BOARD_MARGINS.z, screen.y - BOARD_MARGINS.y - BOARD_MARGINS.w)
	var zoom := minf(free_area.size.x / bounds.size.x, free_area.size.y / bounds.size.y)
	zoom = clampf(zoom, 0.3, 1.6)
	_camera.zoom = Vector2(zoom, zoom)
	# Put the board center on the center of the free area.
	var screen_offset := free_area.get_center() - screen / 2.0
	_camera.position = bounds.get_center() - screen_offset / zoom


func _unhandled_input(event: InputEvent) -> void:
	if _game == null:
		return
	if event is InputEventMouseMotion:
		_update_hover()
	elif event is InputEventMouseButton and event.pressed:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_click(get_global_mouse_position())
			get_viewport().set_input_as_handled()
		elif mouse.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_card()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.is_echo():
		if (event as InputEventKey).physical_keycode == KEY_SPACE:
			_end_turn()
			get_viewport().set_input_as_handled()


func _click(world_pos: Vector2) -> void:
	if _game.is_over():
		return
	var player := _game.turns.current_player()
	if _pending_card:
		var problem := _game.card_play_problem(player, _pending_card, world_pos)
		if problem.is_empty():
			_game.play_card(player, _pending_card, world_pos)
		else:
			_hud.flash(problem)
		_cancel_card()
		return
	var clicked := _game.board.unit_at(world_pos)
	var active := _game.turns.active_unit()
	if clicked:
		if clicked == active:
			return
		if clicked.player_index == player:
			if not _game.turns.select_unit(clicked):
				_hud.flash("%s cannot act right now." % clicked.display_name)
		elif active and clicked.team != active.team:
			var problem := Combat.attack_problem(_game, active, clicked)
			if problem.is_empty():
				Combat.attack(_game, active, clicked)
			else:
				_hud.flash(problem)
		elif active == null:
			_hud.flash("Pick one of your units first.")
		_refresh_board()
		return
	if active:
		if not _game.board.move_unit(active, world_pos):
			_hud.flash("Cannot move there.")
	else:
		_hud.flash("Pick one of your units first.")
	_refresh_board()


func _end_turn() -> void:
	if _game == null or _game.is_over():
		return
	_cancel_card()
	_game.turns.end_turn()
	_refresh_board()


func _on_card_selected(card: CardData) -> void:
	if _pending_card == card:
		_cancel_card()
		return
	_pending_card = card
	_hud.pending_card = card
	_game.board.summon_player = _game.turns.current_player()
	_refresh_board()
	_hud.refresh()


func _cancel_card() -> void:
	_pending_card = null
	if _hud:
		_hud.pending_card = null
		_hud.queue_refresh()
	if _game:
		_game.board.summon_player = -1
		_game.board.refresh()


func _update_hover() -> void:
	var world_pos := get_global_mouse_position()
	_game.board.hover_position = world_pos
	var hovered := _game.board.unit_at(world_pos)
	for unit: Unit in _game.living_units():
		unit.set_highlighted(unit == hovered)
	if _hud.inspected != hovered:
		_hud.inspected = hovered
		_hud.queue_refresh()
	_game.board.refresh()


func _refresh_board() -> void:
	if _game == null:
		return
	var active := _game.turns.active_unit()
	_game.board.focus_unit = active
	for unit: Unit in _game.living_units():
		unit.set_active(unit == active)
	_game.board.refresh()
