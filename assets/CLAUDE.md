# assets/

## Architecture
Imported media: `art/`, `audio/`, `fonts/`. Godot creates a `.import` file next
to each asset; commit it. The imported data itself lives in `.godot/` and is ignored.

Contents:
- `art/units/duelyst/`: 8 animated unit sprite sets (SpriteFrames + sheet)
  from Open Duelyst, CC0. See its README for the source and how to add more.

## Etiquette
- Placeholders are welcome. This is a playground, not final content.
- `snake_case` file names, grouped by subfolder (`art/units/`, `audio/ui/`).
- Assets used by only one sandbox can live in that sandbox's folder instead.
- Keep files small. If binaries start to bloat the repo, move them to Git LFS
  (see README) rather than deleting history.
- Do not commit source files (`.blend`, `.psd`, `.kra`) unless asked.

## Recap
- 2026-11-23: Empty `art/`, `audio/`, `fonts/` folders created.
- 2026-11-23: Added 8 Duelyst unit sprite sets (CC0) for the tactics_arena cards.
