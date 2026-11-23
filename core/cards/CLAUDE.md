# core/cards/

## Architecture
| File | What |
|------|------|
| `card_data.gd` (`CardData`, Resource) | A card: `id`, `display_name`, `description`, `art`, `color`, `tags` ("general" marks General picks), `attributes` given to the summoned unit. |
| `card_zone.gd` (`CardZone`) | An ordered pile (deck, hand, discard). `add`, `remove`, `draw_top`, `shuffle`, `max_size`. Top = end of the array. |
| `deck_data.gd` (`DeckData`, Resource) | A card list, turned into a deck zone by `build_zone()`. `# PROTOTYPE:` deck sourcing. |

Not built yet (person, 2026-11-23): card costs, spell (non-unit) cards, and
deck sourcing (shared draft, per-player prebuilt decks, or small starter decks
plus buying/unlocking during the match). Deck sourcing will be its own
swappable core.

Depends on `core/attributes/`. Used by `match` and the tactics sandbox.

## Etiquette
- A card lists attribute templates; never put game logic in a card.
- When spells arrive, prefer a list of effect Resources on the card over a
  `kind` enum with special cases.

## Recap
- 2026-11-23: Created.
