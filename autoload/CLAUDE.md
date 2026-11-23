# autoload/

## Architecture
Global singletons registered in `project.godot` under `[autoload]`.

| Autoload      | File                          | Job | Required? |
|---------------|-------------------------------|-----|-----------|
| `SceneRouter` | `scene_router.gd`             | Lists sandboxes, switches scenes, Esc/F5 hotkeys. | Yes (frame) |
| `Events`      | `events.gd`                   | Signal bus. Signals only, no state or logic. | No |
| `DebugHud`    | `../core/debug/sandbox_hud.gd`| Sandbox overlay (see `core/CLAUDE.md`). | No |

`SceneRouter` registers its input actions (`playground_back`,
`playground_reload`) in code at startup, so they do not live in the Input Map.

### Dependencies and removal
- `SceneRouter` is used by `scenes/main/main.gd` and `tools/smoke_test.gd`. It
  depends on nothing else. It is part of the required frame; do not remove it.
- `Events` is used only through `get_node_or_null(^"/root/Events")`.
  To remove: delete `events.gd` and its line in `project.godot`.

## Etiquette
- Keep autoloads few and small. A new autoload needs a real cross-scene reason;
  most things belong in a sandbox or in `core/`.
- No gameplay rules in autoloads. They are plumbing.
- Optional autoloads must be reached with `get_node_or_null(^"/root/Name")`,
  never by their global name, so deleting them never breaks a caller.
- Add each new autoload to `project.godot` and to the table above.
- Signals in `Events` get a `##` comment saying who emits them.

## Recap
- 2026-11-23: Added `Events` (one signal: `sandbox_opened`) and `SceneRouter`.
- 2026-11-23: `SceneRouter` uses `Events` only if present. Documented
  required vs optional autoloads and how to remove each.
