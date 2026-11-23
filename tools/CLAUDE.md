# tools/

## Architecture
Dev tooling that is not part of the game.

- `smoke_test.tscn` + `smoke_test.gd`: loads the menu and every sandbox for a
  few frames in headless mode, then runs every `tests/test_*.gd`, and exits 1
  if any scene fails to load or any check fails.
- `tests/`: logic tests. Each `test_*.gd` extends RefCounted and has
  `func run(host: Node) -> Array[String]` returning failure messages (it may
  `await`). `test_tactics_core.gd` checks the event bus, attribute merging,
  modifiers, durations, behaviors, hex distances, every map x turn core
  combination (summon, move, attack, poison, thorns, win), Player Phase
  rules, CTB order and 2v2. It builds its own cards, so it never depends on a
  sandbox. Delete `tests/` and the smoke test just skips it.

## Etiquette
- Run the smoke test before every PR:
  ```
  godot --headless --path . --import        # first run on a fresh clone
  godot --headless --path . res://tools/smoke_test.tscn
  ```
  Pass = exit code 0 and no `SCRIPT ERROR` lines in the output.
- CI runs exactly this on every PR (see `.github/CLAUDE.md`). Cloud Claude
  sessions cannot run Godot themselves, so the green CI check is the proof
  that a PR runs.
- Tools must not be referenced by game scenes.
- Tests use `core/` only, never a sandbox (deleting a sandbox must not break them).
- Editor plugins go in `addons/`, not here.

## Recap
- 2026-11-23: Added the headless smoke test.
- 2026-11-23: Smoke test now also runs in CI.
- 2026-11-23: Smoke test also runs `tests/test_*.gd`; added `test_tactics_core.gd`.
