# assets/tiles/ — Tilemap Tiles

All 32×32 px. Seamless tiles have matching edges. Props have transparent backgrounds.

## Files
| File | Name | Type | Seamless |
|------|------|------|----------|
| tile_floor.png | 地面 | Ground | Yes (all directions) |
| tile_stone_brick.png | 石砖 | Brick pattern | Yes (all directions) |
| tile_wall.png | 墙壁 | Wall texture | Yes (horizontal) |
| tile_wood_bridge.png | 木桥 | Wood planks | Yes (horizontal) |
| tile_brazier.png | 鬼火火盆 | Prop (light source) | No |
| tile_tombstone.png | 墓碑 | Prop (decoration) | No |
| tile_ground_spike.png | 地刺 | Prop (hazard) | No |

## Godot Import
- Import as TileSet or individual sprites
- Tile size: 32×32
- See `docs/art/GODOT_IMPORT_GUIDE.md` Section 3 for collision setup

## Concept Reference
See `docs/art/CONCEPT_TILES.md` for full design descriptions.
