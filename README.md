# Mexarena Junk Test

A Godot **4.7.2** playground for rapidly iterating on the core experience of a
tactical game. Not final game code, but it always runs.

## Quick start
1. Install Godot 4.7.2 (standard build, not .NET).
2. Open Godot, **Import**, and pick `project.godot` in this folder.
3. Press **F5**. The menu lists every sandbox; click one to play it.

Inside a sandbox: **Esc** goes back to the menu, **F5** reloads the sandbox.
You can also open a sandbox scene and run it directly with **F6**.

## Layout
| Path | What lives there |
|------|------------------|
| `scenes/main/` | Sandbox picker (the main scene) |
| `sandboxes/<name>/` | One experiment per folder, found automatically by the menu |
| `core/` | Code shared by two or more sandboxes (incl. the optional `DebugHud` overlay) |
| `autoload/` | `SceneRouter` (required) and the optional `Events` signal bus |
| `data/` | Tuning Resources (`.tres`) |
| `assets/` | Art, audio, fonts |
| `tools/` | Headless smoke test |

Each folder has a `CLAUDE.md` describing its architecture, conventions and a
recap of changes. Start with the root [`CLAUDE.md`](CLAUDE.md).

## New experiment
In the Godot FileSystem dock, duplicate `sandboxes/blank_2d` or
`sandboxes/blank_3d`, rename the folder, scene and script to the same name, and
fix the script path in the scene. It shows up in the menu on the next run.

## Smoke test
```
godot --headless --path . --import
godot --headless --path . res://tools/smoke_test.tscn
```
Exit code 0 and no `SCRIPT ERROR` lines means every scene loads. GitHub Actions
runs the same check on every PR.

## Large files
Binary assets are marked in `.gitattributes`. If the repo gets heavy, enable
Git LFS (`git lfs install`, then `git lfs track "*.png" "*.wav" ...`) before
adding big files.
