# core/

## Architecture
Reusable code promoted out of sandboxes. One self-contained module per
subfolder.

| Folder   | Contents | Depends on | How to remove |
|----------|----------|------------|---------------|
| `debug/` | `sandbox_hud.gd`, registered as the optional `DebugHud` autoload: shows sandbox name, hotkeys, FPS and values pushed with `watch(key, value)`, only while a sandbox runs. `# PROTOTYPE:` | nothing | Delete `core/debug/` and the `DebugHud` line in `project.godot`. |
| `events/` | `EventBus`, `GameEvent`, `GameEvents`: per-match event system. | nothing | Delete with every tactics module below. |
| `attributes/` | Attribute system: `Attribute`, `AttributeSet`, modifiers, behaviors, stacking order. | `events` | Delete with the tactics modules that use it. |
| `units/` | `Unit`: a board piece holding attributes. | `attributes` | idem |
| `cards/` | `CardData`, `CardZone`, `DeckData`. | `attributes` | idem |
| `match/` | `TacticsMatch`, configs, player state, rule modules (Generals win rule, card play rule). | `events`, `attributes`, `units`, `cards`, `board`, `turns` | idem |
| `board/` | Map cores: `MapCore` + `hex/` (HexMap) + `free/` (FreeMap). | `events`, `units`, `match` | One core: delete its subfolder + its sandbox entry. |
| `turns/` | Turn cores: `TurnCore` + `player_phase/` + `ctb/`. | `events`, `units`, `match` | One core: delete its subfolder + its sandbox entry. |
| `visuals/` | `UnitAnimator`: optional animated sprite bodies from `CardData.sprite_frames`, driven by match events. | `events`, `units`, `cards`, `match`, `board` | Delete the folder, its test and the sandbox lines using it: units fall back to discs. |
| `combat/` | `Combat` helpers + attribute behaviors (poison, regen, thorns, on-hit). | `events`, `attributes`, `units`, `match` | Delete with the tactics sandbox (or rewrite its attack calls). |

The eight tactics modules form one family ("tactics core"). The whole family
is removed by deleting those folders, `sandboxes/tactics_arena/` and
`tools/tests/test_tactics_core.gd`.

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
- 2026-11-23: Added the tactics core family (events, attributes, units,
  cards, match, board, turns, combat). It went straight to `core/` with one
  sandbox using it, against the "two sandboxes" rule, because it is the
  game's foundation and every future core experiment will reuse it.
- 2026-11-23: Added `visuals/` (UnitAnimator). Unit draws its hp bar above children; units are y-sorted.
