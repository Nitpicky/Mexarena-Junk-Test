# core/visuals/

## Architecture
Optional visuals for the tactics core.

- `unit_animator.gd` (`UnitAnimator`, AnimatedSprite2D): animated body for a
  `Unit`, from its card's `sprite_frames`. `UnitAnimator.attach(unit, game)`
  returns null (and the unit keeps the placeholder disc) when the card has
  none. It listens to the match bus and plays:
  breathing (rest), idle (during its turn), run (sliding to a new spot),
  attack (melee), cast + a flying projectile (ranged), hit (damaged),
  caststart, castloop, castend (a General when its player summons next to it),
  death (a corpse left behind that fades). Name variants (hurt, damage,
  movement, breathe...) are handled in `ALIASES`. Feet are found
  automatically from the first rest frame (`feet_offset`).
  Game logic never waits for animations.

The person asked (2026-11-23) to use every available animation wherever
possible.

Depends on `events`, `units`, `cards`, `match`, `board`. Used by
`sandboxes/tactics_arena/` (one `unit_added` line and the hand cards) and
`tools/tests/test_unit_visuals.gd`. To remove: delete this folder, that test,
and those sandbox lines; units fall back to discs.

## Etiquette
- Purely cosmetic: never change game state from here.
- Sprites face right; `flip_h` turns them toward their move or target.
- Use `TEXTURE_FILTER_NEAREST` for pixel art.

## Recap
- 2026-11-23: Created UnitAnimator.
