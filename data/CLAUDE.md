# data/

## Architecture
Resource files (`.tres`) holding tuning values and definitions shared by more
than one sandbox, plus the `Resource` scripts that define them if they are not
in `core/`. Empty for now.

## Etiquette
- Data that only one sandbox uses stays in that sandbox's folder.
- Prefer `.tres` (text) over `.res` (binary) so diffs are readable.
- Define the shape with a typed `Resource` script (`class_name FooData`), and keep
  values in `.tres` files edited through the Inspector.
- `snake_case` file names: `unit_stats_default.tres`.

## Recap
- 2026-11-23: Folder created, no data yet.
