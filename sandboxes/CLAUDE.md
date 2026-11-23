# sandboxes/

## Architecture
Each folder is one self-contained experiment on the core experience.

- Layout: `sandboxes/<name>/<name>.tscn` (+ `<name>.gd`, plus any local scenes,
  scripts and resources the experiment needs).
- The menu discovers any folder that contains `<name>/<name>.tscn`. Nothing to
  register.
- Folders starting with `_` are ignored by the menu. Use `_shared/` for helpers
  that only sandboxes use and that are not ready for `core/`.
- The optional `DebugHud` autoload shows the name, hotkeys and FPS
  automatically. To show live values, use it only if present:
  `var hud := get_node_or_null(^"/root/DebugHud")`, then `if hud: hud.watch("k", v)`.
- **Removing a sandbox** = deleting its folder. Nothing else references it.

Current sandboxes:
| Folder      | What it is |
|-------------|------------|
| `blank_2d/` | Empty 2D starter: Node2D, Camera2D. `# PROTOTYPE:` |
| `blank_3d/` | Empty 3D starter: camera looking down at a ground plane, light. `# PROTOTYPE:` |

## Etiquette
- **Starting a new sandbox:** duplicate `blank_2d` or `blank_3d` in the Godot
  FileSystem dock (right-click > Duplicate), rename the folder, the `.tscn`
  and the `.gd` to the same `snake_case` name, and fix the script path in the scene.
  Duplicating inside the editor keeps UIDs unique; copying on disk can clash.
- A sandbox may use `core/` and `autoload/` (optional autoloads only via
  `get_node_or_null`), never another sandbox. If two
  sandboxes need the same code, promote it to `core/`.
- Mark throwaway code `# PROTOTYPE:`.
- Keep tuning values in `@export` vars so they can be tweaked in the Inspector.
- A broken sandbox breaks the smoke test. Fix it or delete it before merging.
- Add each new sandbox to the table above with one line on what it tests.

## Recap
- 2026-11-23: Added `blank_2d` and `blank_3d` starters.
- 2026-11-23: Starters no longer embed the HUD node (it is an optional
  autoload now). Marked them `# PROTOTYPE:`.
