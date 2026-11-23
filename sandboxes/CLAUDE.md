# sandboxes/

## Architecture
Each folder is one self-contained experiment on the core experience.

- Layout: `sandboxes/<name>/<name>.tscn` (+ `<name>.gd`, plus any local scenes,
  scripts and resources the experiment needs).
- The menu discovers any folder that contains `<name>/<name>.tscn`. Nothing to
  register.
- Folders starting with `_` are ignored by the menu. Use `_shared/` for helpers
  that only sandboxes use and that are not ready for `core/`.
- Add a `SandboxHud` (CanvasLayer with `res://core/debug/sandbox_hud.gd`) to show
  the name, hotkeys, FPS and live values via `watch(key, value)`.

Current sandboxes:
| Folder      | What it is |
|-------------|------------|
| `blank_2d/` | Empty 2D starter: Node2D, Camera2D, HUD. |
| `blank_3d/` | Empty 3D starter: camera looking down at a ground plane, light, HUD. |

## Etiquette
- **Starting a new sandbox:** duplicate `blank_2d` or `blank_3d` in the Godot
  FileSystem dock (right-click > Duplicate), rename the folder, the `.tscn`
  and the `.gd` to the same `snake_case` name, and fix the script path in the scene.
  Duplicating inside the editor keeps UIDs unique; copying on disk can clash.
- A sandbox may use `core/` and `autoload/`, never another sandbox. If two
  sandboxes need the same code, promote it to `core/`.
- Keep tuning values in `@export` vars so they can be tweaked in the Inspector.
- A broken sandbox breaks the smoke test. Fix it or delete it before merging.
- Add each new sandbox to the table above with one line on what it tests.

## Recap
- 2026-11-23: Added `blank_2d` and `blank_3d` starters.
