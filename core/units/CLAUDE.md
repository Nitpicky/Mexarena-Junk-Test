# core/units/

## Architecture
- `unit.gd` (`Unit`, Node2D): a piece on the board. Identity (`unit_id`,
  `display_name`, `player_index`, `team`, `color`, `source_card`), an
  `AttributeSet`, per-turn state (`moves_left`, `move_origin`,
  `attacks_left`) and `cell` for grid maps. `is_general()`, `stat(id)`,
  `radius()` (the `size` attribute, else `DEFAULT_RADIUS`).
  Placeholder look drawn in `_draw()` (`# PROTOTYPE:`).

Attribute ids the core modules read (all optional): `hp`, `attack`, `range`,
`movement`, `speed`, `size`, `general`.

Depends on `core/attributes/`. Used by `match`, `board`, `turns`, `combat`.

## Etiquette
- No stats as fields on `Unit`. If a module needs a number, read an attribute.
- Per-turn state is reset by the match / map core on `turn_started`.

## Recap
- 2026-11-23: Created.
