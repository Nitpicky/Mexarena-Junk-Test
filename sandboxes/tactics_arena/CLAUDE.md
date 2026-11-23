# sandboxes/tactics_arena/

## Architecture
Hotseat sandbox for the tactics core (`core/events`, `attributes`, `units`,
`cards`, `match`, `board`, `turns`, `combat`). `# PROTOTYPE:` throughout.

- `tactics_arena.tscn` + `tactics_arena.gd`: root. Shows the setup panel,
  builds a `MatchConfig` from the picks, creates the `TacticsMatch` (board
  under `World`), frames `Camera2D`, turns clicks into match calls.
  `MAP_CORES` and `TURN_CORES` list the core scenes offered.
  Exports: `general_cards`, `deck` (everyone uses it), `card_play_rule`.
- `setup_panel.gd`: map core, turn core, 1v1 / 2v2, General per player.
- `match_hud.gd`: status bar + end turn, players and turn order (left), unit
  inspector and log (right), hand (bottom), game over panel.
- Every card names a sprite set (`sprite_frames`, from
  `assets/art/units/duelyst/`). Units get an animated body through
  `UnitAnimator` (`core/visuals/`); cards in hand show the idle animation.
- `data/cards/`: Generals (`warlord`, `archmage`) and units (`footman`,
  `archer`, `scout`, `venom_spitter`, `thorn_golem`, `berserker`).
  `data/attributes/poison.tres` (applied by Venom). `data/decks/starter_deck.tres`.

Controls: left click your unit to pick it, empty spot to move, enemy to
attack. Click a card, then a highlighted spot near a friendly General, to
summon. Right click cancels. Space ends the turn / phase. Esc: menu, F5: reload.

Player order is A1, B1, A2, B2 (team A blue, team B red).

Depends on the tactics core in `core/`. To remove: delete this folder.

## Etiquette
- No game rules here. If the sandbox needs a rule, it belongs in a `core/`
  module (a `MatchRule`, a map core, a turn core, a behavior).
- New cards: duplicate a `.tres` in `data/cards/` in the editor and edit its
  attributes in the Inspector; add it to `starter_deck.tres`.
- New core to try: add its scene to `MAP_CORES` or `TURN_CORES`.

## Recap
- 2026-11-23: Created: setup screen, hex/free maps x Player Phase/CTB, 1v1
  and 2v2 hotseat, 8 cards, starter deck.
- 2026-11-23: Animated Duelyst sprites on board units and hand cards; taller hand bar.
