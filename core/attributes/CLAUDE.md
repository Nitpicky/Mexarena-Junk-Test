# core/attributes/

## Architecture
The attribute system: everything a unit "has" (stats, statuses, buffs, roles).
Units have no built-in stats.

| File | What |
|------|------|
| `attribute.gd` (`Attribute`, Resource) | `id` (the type), `base_value`, optional pool (`is_pool` + `current`, like hp), `duration` (-1 permanent), `merge` rule, `modifiers`, `behaviors`, `tags`, `hidden`. `merge_from()` folds a same-id newcomer in. `format_number()` helper for UI. |
| `attribute_set.gd` (`AttributeSet`) | One per holder. `add` (copies the template or merges by id), `remove`, `has`, `get_attribute`, `all`, `value(id)` (with modifiers), `current(id)`, `add_current`, `set_base`. `bind(bus, context)` wires behaviors to the bus and counts durations down on `turn_ended` of the holder. |
| `attribute_modifier.gd` (`AttributeModifier`) | `target_id`, `op` (ADD, PERCENT, OVERRIDE), `amount`. Placed on an attribute, it changes another attribute of the same holder. |
| `modifier_stack.gd` (`ModifierStack`) | The stacking order, in one function. |
| `attribute_behavior.gd` (`AttributeBehavior`, Resource) | Base for behavior an attribute carries. Lists event types (`_default_events()` or the `events` export), a `scope` (holder is target / source / any), a `priority`, and reacts in `handle(event, attribute, holder, context)`. Concrete behaviors live with the module they need (see `core/combat/behaviors/`). |

Rules the person set (2026-11-23):
- One attribute per id per holder: "a cat is a cat". Two poisons are one
  poison. Default merge = values add up, longer duration kept.
- Attributes can carry behavior, modularly (behavior Resources).
- Buffs modify other attributes and can stack. **Stacking order is not decided.**
  Default in `ModifierStack`: base + all ADD, then x (1 + sum of PERCENT), then
  the last OVERRIDE wins.
- A modifier on an attribute the holder lacks does nothing.

Depends on `core/events/`. Used by `units`, `cards`, `match`, `turns`,
`combat` and the tactics sandbox.

## Etiquette
- Keep behaviors stateless; state goes on the attribute (value, current,
  duration) so merging stays simple.
- Templates (on cards, in .tres) are never modified at runtime: `add()` copies.
- New stat = a new attribute id in data, not a new field in code.
- Change stacking only in `ModifierStack.compute()`.

## Recap
- 2026-11-23: Created (Attribute, AttributeSet, AttributeModifier, ModifierStack, AttributeBehavior).
