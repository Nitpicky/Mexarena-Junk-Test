# .github/

## Architecture
- `workflows/smoke-test.yml`: on every PR, push to `main` and manual run.
  Downloads Godot 4.7.2 from the official release, verifies its SHA-512,
  imports the project headless, runs `res://tools/smoke_test.tscn`, and fails
  on a non-zero exit or any `SCRIPT ERROR` / `ERROR:` / `Parse Error` line.

Depends on `tools/smoke_test.*`. To remove: delete `.github/workflows/smoke-test.yml`
(then PRs need a manual local run before review).

## Etiquette
- Bump `GODOT_VERSION`, `GODOT_ZIP` and `GODOT_BIN` together when the engine
  version changes, and update `config/features` in `project.godot` too.
- Never skip or weaken the check to get a PR green. Fix the cause.
- Ask the person before adding new workflows.

## Recap
- 2026-11-23: Added the smoke test workflow.
