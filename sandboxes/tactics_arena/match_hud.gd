extends Control
## PROTOTYPE: in-match UI. Status bar, players / turn order, hand, unit
## inspector, log and the game over panel. Reads everything from the match;
## sends player intents up through signals.

signal end_turn_pressed
signal card_selected(card: CardData)
signal setup_pressed

const LOG_LINES := 14

var game: TacticsMatch
var core_label: String = ""
var pending_card: CardData
var inspected: Unit

var _status: Label
var _end_turn: Button
var _left: Label
var _hand: HBoxContainer
var _inspector: RichTextLabel
var _log: RichTextLabel
var _flash: Label
var _game_over: PanelContainer
var _game_over_label: Label
var _log_lines: PackedStringArray = []
var _flash_time: float = 0.0
var _refresh_queued: bool = false


func build(p_game: TacticsMatch, p_core_label: String) -> void:
	game = p_game
	core_label = p_core_label
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top := _panel(Vector2(0, 30), Vector2(0, 44), Control.PRESET_TOP_WIDE)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.clip_text = true
	top_row.add_child(_status)
	_end_turn = _button("End turn", func() -> void: end_turn_pressed.emit())
	top_row.add_child(_end_turn)
	top_row.add_child(_button("New setup", func() -> void: setup_pressed.emit()))

	var left := _panel(Vector2(0, 80), Vector2(250, 0), Control.PRESET_LEFT_WIDE)
	left.offset_bottom = -160
	var left_box := VBoxContainer.new()
	left.add_child(left_box)
	_left = Label.new()
	_left.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(_left)

	var right := _panel(Vector2(0, 80), Vector2(300, 0), Control.PRESET_RIGHT_WIDE)
	right.offset_left = -300
	right.offset_bottom = -160
	var right_box := VBoxContainer.new()
	right.add_child(right_box)
	_inspector = _rich(right_box)
	_inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspector.size_flags_stretch_ratio = 1.2
	right_box.add_child(HSeparator.new())
	_log = _rich(right_box)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true

	var bottom := _panel(Vector2(0, -150), Vector2(0, 150), Control.PRESET_BOTTOM_WIDE)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom.add_child(scroll)
	_hand = HBoxContainer.new()
	_hand.add_theme_constant_override("separation", 8)
	scroll.add_child(_hand)

	_flash = Label.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_flash.position.y = 90
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_flash.add_theme_font_size_override("font_size", 20)
	_flash.add_theme_color_override("font_outline_color", Color.BLACK)
	_flash.add_theme_constant_override("outline_size", 6)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_game_over = PanelContainer.new()
	_game_over.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_game_over.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_game_over.grow_vertical = Control.GROW_DIRECTION_BOTH
	_game_over.visible = false
	_game_over.custom_minimum_size = Vector2(380, 150)
	add_child(_game_over)
	var over_box := VBoxContainer.new()
	over_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_game_over.add_child(over_box)
	_game_over_label = Label.new()
	_game_over_label.add_theme_font_size_override("font_size", 32)
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_box.add_child(_game_over_label)
	over_box.add_child(_button("New match", func() -> void: setup_pressed.emit()))

	game.state_changed.connect(queue_refresh)
	game.turns.changed.connect(queue_refresh)
	game.bus.dispatching.connect(_on_event)
	refresh()


func _process(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		_flash.modulate.a = clampf(_flash_time, 0.0, 1.0)


## Shows a short message in the middle of the screen.
func flash(text: String) -> void:
	_flash.text = text
	_flash_time = 2.5
	_flash.modulate.a = 1.0


func queue_refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		refresh.call_deferred()


func refresh() -> void:
	_refresh_queued = false
	if game == null or not is_instance_valid(game):
		return
	var player := game.turns.current_player()
	var player_name := game.players[player].display_name if player >= 0 else "-"
	_status.text = "%s   |   %s" % [core_label, game.turns.status_text()]
	_end_turn.text = "%s  [Space]" % game.turns.end_turn_label()
	_end_turn.disabled = game.is_over()

	var lines := PackedStringArray()
	for state: PlayerState in game.players:
		var marker := "> " if state.index == player else "  "
		lines.append("%s%s (%s)" % [marker, state.display_name, game.team_name(state.team)])
		lines.append("    hand %d  deck %d  plays left %s" % [state.hand.size(), state.deck.size(), "any" if state.card_plays_left < 0 else str(state.card_plays_left)])
	var order := game.turns.upcoming(8)
	if not order.is_empty() or game.turns.active_unit():
		lines.append("")
		lines.append("Turn order:")
		var active := game.turns.active_unit()
		if active:
			lines.append("  now  %s" % _unit_name(active))
		for i: int in order.size():
			lines.append("  %d.  %s" % [i + 1, _unit_name(order[i])])
	lines.append("")
	lines.append("Left click: pick / move / attack")
	lines.append("Card then click: summon near a General")
	lines.append("Right click: cancel")
	_left.text = "\n".join(lines)

	_refresh_hand(player, player_name)
	_refresh_inspector()

	_game_over.visible = game.is_over()
	if game.is_over():
		_game_over_label.text = "Draw!" if game.winning_team < 0 else "%s wins!" % game.team_name(game.winning_team)


func _refresh_hand(player: int, player_name: String) -> void:
	for child: Node in _hand.get_children():
		child.queue_free()
	if player < 0:
		return
	var title := Label.new()
	title.text = "%s's\nhand" % player_name
	title.custom_minimum_size = Vector2(90, 0)
	_hand.add_child(title)
	var state := game.players[player]
	var can_play := game.turns.can_play_card(player) and state.card_plays_left != 0
	for card: CardData in state.hand.cards:
		_hand.add_child(_card_button(card, can_play))


func _card_button(card: CardData, can_play: bool) -> Button:
	var button := _button("", card_selected.emit.bind(card))
	button.custom_minimum_size = Vector2(160, 132)
	button.tooltip_text = "%s\n%s" % [card.label(), card.description]
	button.disabled = not can_play
	button.toggle_mode = true
	button.button_pressed = card == pending_card
	button.clip_contents = true
	var label := Label.new()
	label.text = "%s\n%s" % [card.label(), _short_stats(card)]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", card.color.lightened(0.45))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -54
	if card.sprite_frames:
		# PROTOTYPE: card art = the unit's idle animation, feet above the text.
		var art := AnimatedSprite2D.new()
		art.sprite_frames = card.sprite_frames
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.offset = Vector2(0, UnitAnimator.feet_offset(card.sprite_frames))
		art.position = Vector2(80, 74)
		art.play(UnitAnimator.resolve(card.sprite_frames, &"idle"))
		if not can_play:
			art.modulate = Color(1, 1, 1, 0.45)
		button.add_child(art)
	else:
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(label)
	return button


func _refresh_inspector() -> void:
	var unit := inspected if inspected and is_instance_valid(inspected) and inspected.alive else game.turns.active_unit()
	if unit == null:
		_inspector.text = "[i]Hover a unit to inspect it.[/i]"
		return
	var text := "[b]%s[/b]\n%s, %s\n" % [_unit_name(unit), game.players[unit.player_index].display_name, game.team_name(unit.team)]
	if unit == game.turns.active_unit():
		text += "[color=yellow]Active: %s movement left, %d attack(s) left[/color]\n" % [Attribute.format_number(unit.moves_left), unit.attacks_left]
	text += "\n"
	for attribute: Attribute in unit.attributes.all():
		if attribute.hidden:
			continue
		var line := "%s" % attribute.label()
		var effective := unit.attributes.value(attribute.id)
		if attribute.is_pool:
			line += ": %s / %s" % [Attribute.format_number(attribute.current), Attribute.format_number(effective)]
		elif effective != 0.0 or attribute.base_value != 0.0:
			line += ": %s" % Attribute.format_number(effective)
			if not is_equal_approx(effective, attribute.base_value):
				line += " [color=gray](base %s)[/color]" % Attribute.format_number(attribute.base_value)
		if attribute.duration > 0:
			line += " [color=gray](%d turns)[/color]" % attribute.duration
		for modifier: AttributeModifier in attribute.modifiers:
			line += "\n    [color=cyan]%s[/color]" % modifier.describe()
		for behavior: AttributeBehavior in attribute.behaviors:
			if behavior:
				line += "\n    [color=violet]%s[/color]" % behavior.describe()
		if attribute.tags.has("status") or attribute.tags.has("buff") or attribute.tags.has("role"):
			line = "[color=orchid]%s[/color]" % line
		text += line + "\n"
	_inspector.text = text


func _on_event(event: GameEvent) -> void:
	var line := _describe(event)
	if line.is_empty():
		return
	_log_lines.append(line)
	while _log_lines.size() > LOG_LINES:
		_log_lines.remove_at(0)
	_log.text = "\n".join(_log_lines)


func _describe(event: GameEvent) -> String:
	var target := event.target as Unit
	var source := event.source as Unit
	match event.type:
		GameEvents.PLAYER_TURN_STARTED:
			if game.turns is PlayerPhaseTurns:
				var index: int = event.get_value("player", 0)
				return "[b]-- %s's phase --[/b]" % game.players[index].display_name
		GameEvents.CARD_PLAYED:
			var card: CardData = event.get_value("card")
			return "%s plays %s" % [game.players[event.get_value("player", 0)].display_name, card.label()]
		GameEvents.DAMAGED:
			var amount: float = event.get_value("amount", 0.0)
			if source:
				return "%s hits %s for %s" % [_unit_name(source), _unit_name(target), Attribute.format_number(amount)]
			var tags: PackedStringArray = event.get_value("tags", PackedStringArray())
			var why := " (%s)" % ", ".join(tags) if not tags.is_empty() else ""
			return "%s takes %s%s" % [_unit_name(target), Attribute.format_number(amount), why]
		GameEvents.HEALED:
			return "[color=lightgreen]%s heals %s[/color]" % [_unit_name(target), Attribute.format_number(event.get_value("amount", 0.0))]
		GameEvents.UNIT_DIED:
			return "[color=tomato]%s dies[/color]" % _unit_name(target)
		GameEvents.ATTRIBUTE_ADDED, GameEvents.ATTRIBUTE_MERGED, GameEvents.ATTRIBUTE_REMOVED:
			var attribute: Attribute = event.get_value("attribute")
			if attribute == null or not attribute.tags.has("status") or target == null or not target.alive:
				return ""
			if event.type == GameEvents.ATTRIBUTE_ADDED:
				return "[color=orchid]%s gains %s %s[/color]" % [_unit_name(target), attribute.label(), Attribute.format_number(attribute.base_value)]
			if event.type == GameEvents.ATTRIBUTE_MERGED:
				return "[color=orchid]%s's %s stacks to %s[/color]" % [_unit_name(target), attribute.label(), Attribute.format_number(attribute.base_value)]
			return "[color=orchid]%s's %s wears off[/color]" % [_unit_name(target), attribute.label()]
		GameEvents.TEAM_ELIMINATED:
			return "[b]%s has no General left[/b]" % game.team_name(event.get_value("team", 0))
		GameEvents.MATCH_ENDED:
			var team: int = event.get_value("winning_team", -1)
			return "[b]%s[/b]" % ("Draw" if team < 0 else "%s wins" % game.team_name(team))
	return ""


func _unit_name(unit: Unit) -> String:
	if unit == null or not is_instance_valid(unit):
		return "?"
	var owner_name := game.players[unit.player_index].display_name if unit.player_index >= 0 else ""
	return "%s %s%s" % [owner_name, unit.display_name, " (G)" if unit.is_general() else ""]


func _short_stats(card: CardData) -> String:
	var parts := PackedStringArray()
	for attribute: Attribute in card.attributes:
		if attribute == null or attribute.hidden:
			continue
		match attribute.id:
			&"hp":
				parts.append("HP %s" % Attribute.format_number(attribute.base_value))
			&"attack":
				parts.append("ATK %s" % Attribute.format_number(attribute.base_value))
			&"range":
				parts.append("RNG %s" % Attribute.format_number(attribute.base_value))
			&"movement":
				parts.append("MOV %s" % Attribute.format_number(attribute.base_value))
			&"speed":
				parts.append("SPD %s" % Attribute.format_number(attribute.base_value))
			_:
				parts.append(attribute.label())
	return " ".join(parts)


func _panel(pos: Vector2, size_hint: Vector2, preset: Control.LayoutPreset) -> PanelContainer:
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(preset)
	match preset:
		Control.PRESET_TOP_WIDE:
			panel.offset_top = pos.y
			panel.offset_bottom = pos.y + size_hint.y
		Control.PRESET_BOTTOM_WIDE:
			panel.offset_top = pos.y
			panel.offset_bottom = 0
		Control.PRESET_LEFT_WIDE:
			panel.offset_top = pos.y
			panel.offset_right = size_hint.x
		Control.PRESET_RIGHT_WIDE:
			panel.offset_top = pos.y
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.88)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


func _rich(parent: Control) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = false
	label.custom_minimum_size = Vector2(0, 120)
	parent.add_child(label)
	return label
