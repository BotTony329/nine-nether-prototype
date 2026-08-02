# Concept: Tiles & Environment — 场景资源

> **Type:** Tilemap Tiles
> **Size:** 32 × 32 px (all tiles)
> **Style:** Seamless, tileable, dark stone

---

## Design Philosophy
- Tiles must be **seamless** — edges match perfectly when placed adjacent
- Keep texture simple — detail should come from variation, not per-tile complexity
- All tiles share a base palette (dark stone / ash)
- Decorative tiles (brazier, tombstone, spike) are NOT seamless — they're props

---

## Tile Designs (7 total)

### 1. tile_floor.png — 地面 (Ground Floor)
- **Type:** Seamless tileable
- **Description:** Cracked stone floor — the ground of the underworld
- **Colors:** Base `#28231E`, cracks `#15110D`, highlights `#3A3328`
- **Notes:** Horizontal crack running through center. Subtle texture noise. Must tile in all directions.

### 2. tile_stone_brick.png — 石砖 (Stone Brick)
- **Type:** Seamless tileable
- **Description:** Cut stone bricks in running bond pattern
- **Colors:** Base `#352E25`, mortar lines `#1A150F`, highlights `#4A4035`
- **Notes:** 2 rows of bricks per tile. Offset pattern. Mortar lines 1px thick.

### 3. tile_wall.png — 墙壁 (Wall)
- **Type:** Seamless tileable (vertical)
- **Description:** Dark rough stone wall — background barrier
- **Colors:** Base `#1E1812`, texture `#2A2218`, shadow `#0F0C08`
- **Notes:** Vertical striations (rock texture). Darker at bottom. Must tile horizontally.

### 4. tile_wood_bridge.png — 木桥 (Wooden Bridge)
- **Type:** Seamless tileable (horizontal)
- **Description:** Wooden plank surface — for bridge/platform sections
- **Colors:** Base `#3A2818`, plank gaps `#1A0E08`, highlights `#5A3E25`
- **Notes:** Horizontal planks. Gap every 8px. Slightly warped/rotted appearance.

### 5. tile_brazier.png — 鬼火火盆 (Ghost Fire Brazier)
- **Type:** Decorative prop (NOT tileable)
- **Description:** Stone brazier with ghost fire burning
- **Colors:** Base stone `#352E25`, fire `#1EB464` / `#4AE68A`, shadow `#1A150F`
- **Notes:** Light source — should have a glow effect in-engine. Brazier takes ~20px, fire ~12px on top.

### 6. tile_tombstone.png — 墓碑 (Tombstone)
- **Type:** Decorative prop (NOT tileable)
- **Description:** Worn stone tombstone with illegible inscription
- **Colors:** Base `#3A3530`, inscription `#1A150F`, moss `#2A3520`
- **Notes:** Rounded top, tapered bottom. Cracks visible. Background decoration, not collidable.

### 7. tile_ground_spike.png — 地刺 (Ground Spike)
- **Type:** Hazard prop (NOT tileable)
- **Description:** Row of bone/iron spikes pointing up — damage on contact
- **Colors:** Spike `#5A4A3A`, tip `#8A7A5A`, shadow `#2A2520`
- **Notes:** 3-4 spikes per tile. Sharp, jagged. Should look painful. Collidable hazard.

---

## Tile Variants (Future)
For prototype, one variant per tile is sufficient. Future versions should include:
- `tile_floor_cracked.png` — damaged variant
- `tile_floor_bloodied.png` — blood-stained variant
- `tile_stone_brick_mossy.png` — overgrown variant
- `tile_wall_crumbled.png` — broken wall section

---

## Design Notes for AI Art Generation
1. **Seamless tiles are critical** — test by placing 4 tiles in a 2×2 grid; seams must be invisible
2. **Keep texture low** — at 32×32, less is more. Suggest material, don't detail it.
3. **Props (brazier, tombstone, spike) have transparent backgrounds** — only the object is drawn
4. **Brazier fire should animate** — if multi-frame, create `tile_brazier_01.png` through `tile_brazier_04.png`
5. **Spikes should look like bone, not metal** — the underworld reuses the dead
