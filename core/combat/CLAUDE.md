# core/combat/

## Architecture
- `combat.gd` (`Combat`, static): `deal_damage` (through `before_damage`,
  editable and cancellable, then `damaged`; hp 0 = death), `heal`,
  `attack_problem`, `attack` (one per unit turn, `attack` value as damage,
  `range` default 1, measured by the map core).
- `behaviors/`: attribute behaviors that need combat.
  | Behavior | Does |
  |----------|------|
  | `DamageOverTimeBehavior` | Holder takes the attribute's value at its turn start (poison). |
  | `HealOverTimeBehavior` | Holder heals the value at its turn end (regeneration). |
  | `ReflectDamageBehavior` | Attacks on the holder deal the value back (thorns). |
  | `ApplyOnHitBehavior` | Holder's attacks add the `apply` attribute to the target (venom → poison). |

Depends on `events`, `attributes`, `units`, `match`. Used by the tactics
sandbox and `tools/tests/`.

## Etiquette
- All hp changes go through `Combat` so behaviors hear them.
- Tag damage (`attack`, `status`, `reflected`) so behaviors can filter.

## Recap
- 2026-11-23: Created Combat and four example behaviors.
