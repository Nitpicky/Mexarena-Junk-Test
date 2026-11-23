# core/turns/

## Architecture
Turn cores. They decide who acts and emit the turn events; everything else
reacts to those events.

| Path | What |
|------|------|
| `turn_core.gd` (`TurnCore`, Node) | Interface: `start`, `active_unit`, `current_player`, `can_play_card`, `can_select`, `select_unit`, `end_turn`, `end_turn_label`, `upcoming(count)` (turn order preview), `status_text`. Signal `changed`. Emits `player_turn_started/ended` and `turn_started/ended`. |
| `player_phase/` | `PlayerPhaseTurns`: players take phases in config order. Pick a unit to play it; picking another ends the first for good. "End phase" passes on. `summoned_units_act_immediately` (default false). |
| `ctb/` | `CtbTurns`: each unit's gauge fills at its `speed` (`default_speed` if none). First to `gauge_size` acts; its owner is the current player. Ties: fuller gauge, then older unit. `upcoming()` simulates the order shown on screen. A unit killed during its own turn passes the turn. |

Depends on `events`, `units`, `match`. To remove one turn core: delete its
folder and its entry in the sandbox's `TURN_CORES`.

## Etiquette
- A turn core only decides order. Movement lock, draws, poison ticks, attack
  resets all hang on the events it emits.
- Always check `unit.alive` after emitting `turn_started` (poison can kill).

## Recap
- 2026-11-23: Created TurnCore, PlayerPhaseTurns, CtbTurns.
