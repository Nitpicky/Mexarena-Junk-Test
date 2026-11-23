# Duelyst unit sprites

Animated pixel-art units from Open Duelyst (https://github.com/open-duelyst/duelyst),
released under **CC0 1.0** (public domain). Repackaged as Godot SpriteFrames by
https://github.com/Jordyfel/duelyst-animated-sprites-godot.

Approved by the person for playtesting (2026-11-23). Only the characters the
tactics_arena cards use are copied here (the full pack is about 700 units, 50 MB).

Changes from the pack: paths point here, UIDs removed, looping fixed (rest,
run, castloop and projectile loop; everything else plays once).

| File | Used by card |
|------|--------------|
| f1_general | Warlord |
| f4_general | Archmage |
| f1_silverguardsquire | Footman |
| f1_ranged | Archer |
| f3_badlandsscout | Scout |
| f4_gloomchaser | Venom Spitter |
| neutral_golemnature | Thorn Golem |
| neutral_mercdaggerkiri | Berserker |

To add one: copy `spriteframes/units/<name>.tres` and `spritesheets/units/<name>.png`
from the pack, apply the same three changes, then set the card's `sprite_frames`.
