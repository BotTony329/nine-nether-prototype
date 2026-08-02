# assets/player/ — Player Character Sprites

## Character
**岳家军普通军士** (Yue Family Army Soldier) — a broken, battle-worn foot soldier trapped in the underworld.

## Files
| File | Animation | Frames | Sheet Size | Frame Size | FPS |
|------|-----------|--------|------------|------------|-----|
| player_idle.png | Idle | 4 | 192×48 | 48×48 | 8 |
| player_run.png | Run | 6 | 288×48 | 48×48 | 12 |
| player_jump.png | Jump | 2 | 96×48 | 48×48 | 10 |
| player_attack.png | Attack | 4 | 192×48 | 48×48 | 14 |
| player_hurt.png | Hurt | 2 | 96×48 | 48×48 | 10 |
| player_death.png | Death | 6 | 288×48 | 48×48 | 8 |

## Sprite Sheet Format
Horizontal strip — frames arranged left-to-right. Transparent background. Nearest-neighbor filtering.

## Godot Import
- Filter: Off (Nearest)
- Mipmaps: Off
- Use with `AnimatedSprite2D` + `SpriteFrames` resource
- Set H-Frames per the table above

## Concept Reference
See `docs/art/CONCEPT_PLAYER.md` for full visual design description.

## Color Palette
Dried blood red `#5A322B`, ash brown `#3A2E25`, dark iron `#4A4035`, ghost fire eyes `#B4641E`
