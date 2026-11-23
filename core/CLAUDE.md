# core/

## Architecture
Reusable code promoted out of sandboxes. One self-contained module per
subfolder.

| Folder   | Contents | Depends on | How to remove |
|----------|----------|------------|---------------|
| `debug/` | `sandbox_hud.gd`, registered as the optional `DebugHud` autoload: shows sandbox name, hotkeys, FPS and values pushed with `watch(key, value)`, only while a sandbox runs. `# PROTOTYPE:` | nothing | Delete `core/debug/` and the `DebugHud` line in `project.godot`. |

## Etiquette
- Code lands here only once **two or more sandboxes** need it. Until then it
  lives in the sandbox.
- Each subfolder is one module that can be deleted without breaking the
  project (beyond the code that directly uses it). List its dependencies and
  removal steps in the table above.
- Never depend on a sandbox. `core/` may use `autoload/`, but optional
  autoloads only via `get_node_or_null`.
- Use `class_name` for types here so sandboxes can reference them by name,
  except for scripts registered as autoloads (the names would clash).
- Keep it generic: no assumptions about mechanics that are not decided yet.
- When you promote code, update the sandboxes that used it in the same commit.
- Mark temporary code `# PROTOTYPE:`.

## Recap
- 2026-11-23: Added `debug/sandbox_hud.gd`.
- 2026-11-23: HUD is now the optional `DebugHud` autoload; sandboxes no
  longer reference it, so `core/debug/` can be deleted. Marked `# PROTOTYPE:`.
