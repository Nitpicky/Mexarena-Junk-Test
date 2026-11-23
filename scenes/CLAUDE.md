# scenes/

## Architecture
Scenes that frame the playground itself, not experiments.

- `main/main.tscn` + `main.gd`: the entry scene. Builds one button per sandbox
  from `SceneRouter.list_sandboxes()`. It needs no edits when sandboxes are added.

## Etiquette
- Gameplay experiments do not go here; they go in `sandboxes/`.
- Keep the menu dumb: it lists and launches, nothing else.
- `foo.tscn` is paired with `foo.gd` in the same folder.

## Recap
- 2026-11-23: Added the sandbox picker menu.
