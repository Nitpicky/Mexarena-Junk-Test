# core/board/

## Architecture
Map cores. The match and UI only talk to `MapCore`, with world positions.

| Path | What |
|------|------|
| `map_core.gd` (`MapCore`, Node2D) | Interface + shared bits: `get_bounds`, `general_spawn`, `can_summon_at`, `place_unit`, `remove_unit`, `can_move_to`, `move_unit`, `distance` (in movement points), `unit_at`, `refresh`. Locks `movement` into `unit.moves_left` on `turn_started`. Children: `Overlay` (range highlights) and `Units`. `summon_range` export. |
| `hex/` | `HexMap`: hex grid, per-tile movement with terrain costs, no passing through units. `hex_map.tscn` has a `Tiles` TileMapLayer using `hex_tileset.tres` (pointy-top, odd rows shifted right) and `hex_tiles.png` (plain, rough, wall). `HexTerrain` Resources on the map say what each atlas tile means (`move_cost`, `blocked`). Empty Tiles = generated default board (`# PROTOTYPE:`). |
| `free/` | `FreeMap`: open arena (`arena_size`). Reach is a circle of `movement x pixels_per_point` around where the unit started its turn; move inside it as often as you like. Round collision between units (destination and path). |

**Authoring a hex map in the editor:** duplicate `hex/hex_map.tscn`, select
`Tiles`, paint with the TileMap editor (bottom panel). Painted cells are the
map. To add a terrain, add a tile to `hex_tiles.png` / the atlas and a
`HexTerrain` entry in the map's `terrains`. Then point the sandbox's
`MAP_CORES` at the new scene.

Open point (2026-11-23): in free space the circle is locked at turn start even
if movement changes mid-turn. Person to confirm.

Depends on `events`, `units`, `match`. To remove one map core: delete its
folder and its entry in the sandbox's `MAP_CORES`.

## Etiquette
- A new map core = a new subfolder with a scene whose root extends `MapCore`.
- Keep distances in movement points so `range` and `movement` mean the same
  on every map.
- Overlay drawing is `# PROTOTYPE:`; keep it in `_draw_overlay()`.

## Recap
- 2026-11-23: Created MapCore, HexMap, FreeMap.
