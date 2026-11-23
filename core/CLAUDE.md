# core/

## Architecture
Reusable code promoted out of sandboxes. Grouped by topic in subfolders.

| Folder   | Contents |
|----------|----------|
| `debug/` | `SandboxHud`: overlay with sandbox name, hotkeys, FPS, watched values. |

## Etiquette
- Code lands here only once **two or more sandboxes** need it. Until then it
  lives in the sandbox.
- Never depend on a sandbox. `core/` may use `autoload/`.
- Use `class_name` for types here so sandboxes can reference them by name.
- Keep it generic: no assumptions about mechanics that are not decided yet.
- When you promote code, update the sandboxes that used it in the same commit.
- Each new subfolder gets a row in the table above (and its own CLAUDE.md once
  it holds more than a couple of files).

## Recap
- 2026-11-23: Added `debug/sandbox_hud.gd`.
