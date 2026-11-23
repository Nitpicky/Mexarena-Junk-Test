# tools/

## Architecture
Dev tooling that is not part of the game.

- `smoke_test.tscn` + `smoke_test.gd`: loads the menu and every sandbox for a
  few frames in headless mode and exits 1 if any scene fails to load.

## Etiquette
- Run the smoke test before every PR:
  ```
  godot --headless --path . --import        # first run on a fresh clone
  godot --headless --path . res://tools/smoke_test.tscn
  ```
  Pass = exit code 0 and no `SCRIPT ERROR` lines in the output.
- Tools must not be referenced by game scenes.
- Editor plugins go in `addons/`, not here.

## Recap
- 2026-11-23: Added the headless smoke test.
