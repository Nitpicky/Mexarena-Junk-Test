# autoload/

## Architecture
Global singletons registered in `project.godot` under `[autoload]`.

| Autoload      | File               | Job |
|---------------|--------------------|-----|
| `Events`      | `events.gd`        | Signal bus. Signals only, no state or logic. |
| `SceneRouter` | `scene_router.gd`  | Lists sandboxes, switches scenes, Esc/F5 hotkeys. |

`SceneRouter` registers its input actions (`playground_back`, `playground_reload`)
in code at startup, so they do not live in the project Input Map.

## Etiquette
- Keep autoloads few and small. A new autoload needs a real cross-scene reason;
  most things belong in a sandbox or in `core/`.
- No gameplay rules in autoloads. They are plumbing.
- Add each new autoload to `project.godot` and to the table above.
- Signals in `Events` get a `##` comment saying who emits them.

## Recap
- 2026-11-23: Added `Events` (one signal: `sandbox_opened`) and `SceneRouter`.
