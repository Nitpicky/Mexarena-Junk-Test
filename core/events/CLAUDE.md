# core/events/

## Architecture
Modular event system for matches.

| File | What |
|------|------|
| `event_bus.gd` (`EventBus`) | Per-match bus. `subscribe(type, callable, priority)`, `unsubscribe`, `unsubscribe_object`, `emit(event)`, `emit_new(type, source, target, data)`. `EventBus.ANY` hears everything. Higher priority runs first; a listener can set `event.cancelled` to stop the rest. Signals: `dispatching` (before listeners, in the real order of things, used for logs) and `emitted` (after listeners, used for UI refresh). Guards against infinite chains (`MAX_DEPTH`). |
| `game_event.gd` (`GameEvent`) | `type`, `source` (who caused it), `target` (who it happened to), `data` (Dictionary), `cancelled`. Helpers `get_value`, `has_tag` (`data.tags`). |
| `game_events.gd` (`GameEvents`) | Names of the common event types, with what each carries. Constants only. |

Not an autoload on purpose: each match owns its own bus, so matches and
tests never hear each other. The playground's `Events` autoload is unrelated
(scene-level plumbing).

Depends on nothing. Used by every other tactics module (`attributes`,
`match`, `board`, `turns`, `combat`). Removing it means removing those too.

## Etiquette
- Convention: the unit an event is about is the `target` (turn_started,
  damaged, died...). The cause, if any, is the `source`.
- "before_*" events are the ones listeners may edit or cancel. Others are
  facts: do not cancel them.
- New event names are fine anywhere. Add common ones to `GameEvents` with a
  `##` comment saying what `data` carries.
- Never keep state in the bus. Listeners own their state.

## Recap
- 2026-11-23: Created (EventBus, GameEvent, GameEvents).
