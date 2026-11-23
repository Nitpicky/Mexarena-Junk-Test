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

## Architecture at a glance
```
project.godot        engine config, autoloads, main scene = scenes/main/main.tscn
autoload/            global singletons (Events signal bus, SceneRouter)
scenes/main/         the sandbox picker menu (entry point)
sandboxes/<name>/    one self-contained experiment per folder: <name>/<name>.tscn
core/                code promoted out of sandboxes once 2+ sandboxes need it
data/                Resource files (.tres) for tuning values
assets/              art, audio, fonts (placeholders are fine)
tools/               smoke test and other dev tooling
addons/              third-party Godot plugins (create when the first one is added)
```
Flow: `main.tscn` asks `SceneRouter` for sandboxes, shows a button per sandbox,
and `SceneRouter` switches scenes. In any sandbox, **Esc** returns to the menu
and **F5** reloads it.

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
