# Mexarena Junk Test: root guide for Claude

## What this repo is
A **Godot 4.7.2 playground** for rapidly iterating on the core experience of a
tactical game. Code here is throwaway-friendly, not final level code, but it
**must always run**: the project opens, the menu lists every sandbox, and the
smoke test passes.

The game design is not settled. Do not invent mechanics. Build only what the
person asks for, inside a sandbox, and keep shared code generic.

## How Claude works in this repo (agent rule)
- **One main Opus agent does the work**: design, code, scenes, reviews, commits.
- **1 to 3 Haiku subagents** are used only for **scouting and fetching**:
  finding files, listing what exists, quoting file contents, grepping for usages.
  They never edit files, commit or make design calls.
- Use the `repo-scout` agent in `.claude/agents/` for this (it is pinned to Haiku).
- Start with one scout. Add a second or third only when the lookups are independent
  (for example one scouts `sandboxes/`, another scouts `core/`). Never more than 3.
- The main agent verifies anything a scout reports before acting on it.

## Working with the person (collaboration rules)
- **Question phase first.** Before starting any task, ask a thorough round of
  clarifying questions, and restate the ask in your own words so you both
  confirm you are on the same wavelength. Do not start building until the
  person confirms the restated ask.
- **Challenge earlier work.** If a new goal clashes with something already
  implemented, say so plainly: what clashes, why, and the options. Agree on a
  conclusion with the person, then rework the earlier implementation to match.
  Do not silently work around or silently rewrite it.
- **Ask before adding any plugin or addon.** Name it, say why it is needed and
  what it replaces, and wait for a yes before adding anything to `addons/` or
  enabling it.

## Build rules
- **Modular and removable.** Every module (a sandbox, a `core/` system, an
  autoload) must be self-contained and easy to delete. Deleting its folder,
  plus at most one listed line elsewhere (an autoload entry, for example),
  must leave the project running. Each module's CLAUDE.md lists what depends
  on it and how to remove it.
- **Reusable but strippable resources.** Design `Resource` types to be generic
  enough to reuse for many different things (small, composable, no assumptions
  about one use), but easy to strip out: nothing should break if a resource or
  one of its fields is removed beyond the code that directly uses it.
- **Must run before review.** A PR is only ready for review once the project
  has actually run (smoke test passing). If it could not be run, the PR stays a
  draft and says so.
- **Keep a recap.** Every change adds a dated line to the Recap of each
  CLAUDE.md it affects, in the same commit.
- **Mark throwaway code** with a `# PROTOTYPE:` comment saying what is
  temporary and why, so it is easy to find with a search and replace later.

## Architecture at a glance
```
project.godot        engine config, autoloads, main scene = scenes/main/main.tscn
autoload/            global singletons (Events signal bus, SceneRouter)
core/debug/          DebugHud: optional overlay autoload (PROTOTYPE)
core/events|attributes|units|cards|match|board|turns|combat|visuals/
                     the tactics core: attribute system, event bus, cards and
                     zones, match frame + rules, swappable map and turn cores
scenes/main/         the sandbox picker menu (entry point)
sandboxes/<name>/    one self-contained experiment per folder: <name>/<name>.tscn
core/                code promoted out of sandboxes once 2+ sandboxes need it
data/                Resource files (.tres) for tuning values
assets/              art, audio, fonts (placeholders are fine)
tools/               smoke test, logic tests (tools/tests/) and other dev tooling
addons/              third-party Godot plugins (ask first; create on first one)
.github/workflows/   CI: smoke test on every PR and push to main
```
Flow: `main.tscn` asks `SceneRouter` for sandboxes, shows a button per sandbox,
and `SceneRouter` switches scenes. In any sandbox, **Esc** returns to the menu
and **F5** reloads it.

**Required frame vs removable modules.** The only required pieces are the
frame: `scenes/main/` (menu) and `SceneRouter`. Everything else is a module
that can be deleted: each sandbox (delete its folder), `Events` and `DebugHud`
(delete the file or folder plus one autoload line in `project.godot`), and any
`core/` subfolder. Optional modules are reached with
`get_node_or_null(^"/root/Name")` so nothing breaks when they are gone.

**Promotion rule:** new ideas start inside a sandbox folder. When a second
sandbox needs the same code, move it to `core/` and update both. Sandboxes may
depend on `core/` and `autoload/`; `core/` must never depend on a sandbox.

## Etiquette

### GDScript
- Follow the official GDScript style guide. Tabs for indentation.
- Static typing everywhere: typed vars, params, returns, and loop variables.
- `snake_case` files, folders, functions and variables. `PascalCase` for
  `class_name` and node names. `CONSTANT_CASE` for constants.
- Private members start with `_`. Use `%UniqueName` for nodes a script needs.
- Every script starts with a `##` doc comment saying what it is for.
- Signals up, calls down. Use the `Events` bus only between unrelated scenes.
- Tuning numbers go in `@export` vars or a Resource in `data/`, not literals
  buried in logic.
- `class_name` only for types used across folders (mostly in `core/`).

### Scenes
- One root script per scene, same name as the scene (`foo.tscn` + `foo.gd`).
- Prefer composition (child nodes) over deep inheritance.
- Commit the `.uid` files Godot creates next to scripts and resources.

### Git
- Never commit directly to `main`. Work on a branch and open a PR.
- Branch names: `feature/<short-name>`, `fix/<short-name>`, `sandbox/<name>`
  (Claude sessions may use the `claude/...` branch they were given).
- Commit messages: imperative, short subject (`Add grid cursor sandbox`), with
  a body when the why is not obvious. One logical change per commit.
- Before a PR: run the smoke test (below) and update the CLAUDE.md files you touched.
- Never commit `.godot/`, export builds or secrets.

## Verifying a change
```
godot --headless --path . --import
godot --headless --path . res://tools/smoke_test.tscn
```
Exit code 0 and no `SCRIPT ERROR` lines means it passes. See `tools/CLAUDE.md`.
CI runs the same check on every PR (`.github/workflows/smoke-test.yml`); a PR
is ready for review only once that check is green. Cloud Claude sessions can
also download the official Godot 4.7.2 Linux build into their scratchpad and
run it headless; with `xvfb-run` and `--rendering-driver opengl3` they can
even take screenshots to check a sandbox visually.

## Game design (as told by the person, 2026-11-23)
Card-based tactical PvP, 1v1 and 2v2, hotseat for now. Units hold
Attributes (stats, statuses, buffs: no hard-coded stats). Cards in hand
summon units with the card's attributes. Each player starts with a chosen
General; a team with no General left loses. Swappable cores: map (hex grid vs
free space with a movement circle) and turns (Player Phase vs CTB). Open:
buff stacking order, deck sourcing, costs, spells, summon placement. See each
`core/*/CLAUDE.md` for what is decided and what is a placeholder.

## Keeping these docs alive
Every relevant directory has a `CLAUDE.md` with three parts: **Architecture**,
**Etiquette**, **Recap**. When you add, move or remove something, update the
`CLAUDE.md` of that directory in the same commit, and add a dated line to its
Recap log. New directories that hold code or content get their own `CLAUDE.md`.

## Recap
- 2026-11-23: Repo bootstrapped. Godot 4.7.2 skeleton, sandbox menu,
  SceneRouter hotkeys, SandboxHud overlay, blank 2D and 3D sandboxes, smoke test.
- 2026-11-23: Added collaboration rules (question phase + restate, challenge
  earlier work that clashes with new goals).
- 2026-11-23: Added rules: ask before addons, modular and removable modules,
  reusable but strippable resources, must run before review, recap per change,
  `# PROTOTYPE:` marker for throwaway code.
- 2026-11-23: Reworked scaffold to match the build rules: HUD is now the
  optional `DebugHud` autoload, `SceneRouter` no longer requires `Events`,
  throwaway code marked `# PROTOTYPE:`, smoke test added to CI.
- 2026-11-23: Added the tactics core (`core/events`, `attributes`, `units`,
  `cards`, `match`, `board`, `turns`, `combat`), the `tactics_arena` sandbox,
  logic tests in `tools/tests/`, the game design summary, and committed the
  `.uid` / `.import` files Godot generates.
- 2026-11-23: Added animated unit sprites: `core/visuals/` (UnitAnimator),
  8 Duelyst sprite sets (CC0) in `assets/art/units/duelyst/`, cards name a
  sprite set, and hand cards show it.
