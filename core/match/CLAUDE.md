# core/match/

## Architecture
The match frame: players, units, zones, event bus, and the plugged-in cores.

| File | What |
|------|------|
| `tactics_match.gd` (`TacticsMatch`, Node) | `setup(config, board_parent)`, `start()`, `summon`, `play_card`, `card_play_problem`, `kill`, `draw_card`, `end_match`, `living_units`, `teams`. Owns `bus`, `board` (MapCore), `turns` (TurnCore), `players`, `units`, `rules`. Resets `attacks_left` on turn start. Generals get the `general` attribute (`GENERAL_ID`) at start. |
| `match_config.gd` (`MatchConfig`) | Players, `map_scene`, `turn_scene`, `rules`, `random_seed`. Swapping a core = another scene here. |
| `player_config.gd` (`PlayerConfig`) | Name, team, color, General card, deck. Same team = allies (2v2 = 4 players, 2 teams). |
| `player_state.gd` (`PlayerState`) | Runtime player: deck/hand/discard zones, `card_plays_left`. |
| `match_rule.gd` (`MatchRule`) | Base for optional rule modules, hooked on the bus in `setup()`. |
| `rules/generals_win_rule.gd` | A team with no living General is eliminated; last team standing wins. |
| `rules/card_play_rule.gd` | Starting hand, draw per player turn, plays per turn, max hand. Without it: no draws, unlimited plays. |

Flow: `setup` builds players (shuffled decks), instantiates the map and turn
scenes, copies the rules. `start` summons Generals, emits `match_started`
(rules deal hands), starts the turn core.

Placeholder choices (not decided by the person, easy to change):
- Cards summon on a free spot within `summon_range` of a friendly General
  (`MapCore.can_summon_at`).
- One card play and one draw per player turn (`CardPlayRule`). In CTB a
  player turn is each of their units' turns.
- One attack per unit turn.

Depends on `events`, `attributes`, `units`, `cards`, `board` (MapCore base)
and `turns` (TurnCore base). Used by `combat`, `board`, `turns`, the tactics
sandbox and `tools/tests/`.

## Etiquette
- The match must not know about a specific core or rule. If it needs to ask
  "can X happen?", add a method to MapCore / TurnCore or a rule.
- New win conditions, draw rules, economy... = new `MatchRule`s.

## Recap
- 2026-11-23: Created (TacticsMatch, configs, PlayerState, rules).
