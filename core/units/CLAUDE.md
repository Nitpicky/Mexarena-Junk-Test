# core/units/

## Architecture
- `unit.gd` (`Unit`, Node2D): a piece on the board. Identity (`unit_id`,
  `display_name`, `player_index`, `team`, `color`, `source_card`), an
  `AttributeSet`, per-turn state (`moves_left`, `move_origin`,
  `attacks_left`) and `cell` for grid maps. `is_general()`, `stat(id)`,
  `radius()` (the `size` attribute, else `DEFAULT_RADIUS`).
  Placeholder look drawn in `_draw()` (`# PROTOTYPE:`): a disc, or only a
  team-colored ground ring when a visual module added a body with
  `add_body_visual()` (`has_sprite`). The hp bar and status badge are drawn
  on an `Overlay` child, above any sprite.

Attribute ids the core modules read (all optional): `hp`, `attack`, `range`,
`movement`, `speed`, `size`, `general`.

Depends on `core/attributes/`. Used by `match`, `board`, `turns`, `combat`.

## Etiquette
- No stats as fields on `Unit`. If a module needs a number, read an attribute.
- Per-turn state is reset by the match / map core on `turn_started`.

## Recap
- 2026-11-23: Created.
- 2026-11-23: Added `add_body_visual()` / `has_sprite`; hp bar moved to an overlay child.
