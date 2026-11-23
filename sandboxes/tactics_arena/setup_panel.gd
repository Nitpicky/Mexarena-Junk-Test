extends Control
## PROTOTYPE: pre-match screen. Pick the map core, the turn core, the mode and
## each player's General, then press Start.

signal start_requested(map_name: String, turn_name: String, generals: Array[CardData])

var map_names: PackedStringArray = []
var turn_names: PackedStringArray = []
var general_cards: Array[CardData] = []

var _map: OptionButton
var _turns: OptionButton
var _mode: OptionButton
var _general_rows: Array[Control] = []
var _general_pickers: Array[OptionButton] = []


func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(440, 0)
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Tactics Arena"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var hint := Label.new()
	hint.text = "Hotseat sandbox. Pick the cores to test."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	_map = _add_picker(box, "Map", map_names)
	_turns = _add_picker(box, "Turns", turn_names)
	_mode = _add_picker(box, "Mode", PackedStringArray(["1v1", "2v2"]))
	_mode.item_selected.connect(func(_i: int) -> void: _update_rows())

	var general_names := PackedStringArray()
	for card: CardData in general_cards:
		general_names.append(card.label())
	var labels := ["Team A, player 1", "Team B, player 1", "Team A, player 2", "Team B, player 2"]
	for i: int in 4:
		var picker := _add_picker(box, "%s General" % labels[i], general_names)
		picker.select(i % maxi(general_names.size(), 1))
		_general_pickers.append(picker)
		_general_rows.append(picker.get_parent() as Control)
	_update_rows()

	var start := Button.new()
	start.text = "Start match"
	start.custom_minimum_size = Vector2(0, 40)
	start.pressed.connect(_on_start)
	box.add_child(start)
	start.grab_focus.call_deferred()


func _add_picker(box: VBoxContainer, label_text: String, items: PackedStringArray) -> OptionButton:
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(200, 0)
	row.add_child(label)
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item: String in items:
		picker.add_item(item)
	row.add_child(picker)
	return picker


func _player_count() -> int:
	return 4 if _mode.selected == 1 else 2


func _update_rows() -> void:
	for i: int in _general_rows.size():
		_general_rows[i].visible = i < _player_count()


func _on_start() -> void:
	var chosen: Array[CardData] = []
	for i: int in _player_count():
		var index := _general_pickers[i].selected
		chosen.append(general_cards[index] if index >= 0 and index < general_cards.size() else null)
	start_requested.emit(map_names[_map.selected], turn_names[_turns.selected], chosen)
