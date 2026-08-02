# Concept: Background Elements — 背景资源

> **Type:** Parallax / Decorative
> **Sizes:** Varies (see each)
> **Style:** Distant, atmospheric, dark

---

## Design Philosophy
- Background elements are **behind the gameplay layer**
- They should be darker and less detailed than foreground elements
- Parallax scrolling: background moves slower than foreground
- All elements have transparent backgrounds (except bg_deep which is full-frame)

---

## Background Designs (4 total)

### 1. bg_tree.png — 背景树 (Background Tree)
- **Size:** 64 × 128 px
- **Description:** Dead, skeletal tree — bare branches reaching upward
- **Colors:** Trunk `#14100E`, branches `#1E1812`, highlight `#2A2218`
- **Notes:** Leafless, twisted, ancient. Should look like it died centuries ago. Placed at intervals along the background parallax layer.
- **Parallax layer:** Mid-background (0.5x scroll speed)
- **Tiling:** Can be placed at intervals; not seamless but repeatable with variation

### 2. bg_broken_flag.png — 残破旗帜 (Broken Flag)
- **Size:** 48 × 96 px
- **Description:** Broken flag pole with tattered battle flag still attached
- **Colors:** Pole `#2A2218`, flag `#3A221B` (faded blood red), frayed edges `#1A0E0B`
- **Notes:** Flag should look wind-blasted and old. Pole is broken at the top — flag hangs from the break point. Placed as atmospheric decoration.
- **Parallax layer:** Mid-background (0.5x scroll speed)
- **Notes:** Can have slight sway animation if multi-frame variant is created later

### 3. bg_chains.png — 锁链 (Chains)
- **Size:** 32 × 96 px
- **Description:** Hanging chains from above — vertical decoration
- **Colors:** Chain `#3A3530`, highlight `#5A5045`, shadow `#1A150F`
- **Notes:** 3-4 chain links visible. Hangs from top of frame. Rusted, heavy iron chains. Atmospheric element suggesting imprisonment/torture.
- **Parallax layer:** Close background (0.7x scroll speed)
- **Notes:** Can have slight sway animation in future

### 4. bg_deep.png — 深景背景 (Deep Background)
- **Size:** 320 × 180 px
- **Description:** Full-frame deep background — distant underworld landscape
- **Colors:** Sky `#0A080C`, mountains `#15110D`, mist `#1A151F`, distant fire `#1E2820`
- **Notes:** Wide landscape showing the underworld vista — jagged mountains, low-hanging mist, faint distant ghost fires. This is the deepest parallax layer.
- **Parallax layer:** Deep background (0.2x scroll speed)
- **Tiling:** Designed to tile horizontally — left and right edges match

---

## Parallax Layer Structure (for Claude's reference)
```
Layer 0 (0.2x): bg_deep.png — underworld vista
Layer 1 (0.5x): bg_tree.png, bg_broken_flag.png — mid decoration
Layer 2 (0.7x): bg_chains.png — close decoration
Layer 3 (1.0x): Gameplay (tiles, player, enemies)
Layer 4 (1.0x): effects, UI
```

---

## Future Background Elements (Not Required for Prototype)
| Element | Description |
|---------|-------------|
| bg_gate.png | Massive underworld gate (boss arena backdrop) |
| bg_river.png | River of blood/souls in deep background |
| bg_tower.png | Distant watchtower silhouette |
| bg_fog.png | Moving fog overlay (semi-transparent) |
| bg_fireflies.png | Floating ghost fire particles (ambient) |

---

## Design Notes for AI Art Generation
1. **Backgrounds are DARKER than foreground** — they recede visually
2. **Less detail, more silhouette** — at parallax distance, details are lost
3. **bg_deep.png is the only full-frame background** — all others are sprite props
4. **Trees should be dead/skeletal** — no leaves, twisted branches
5. **Chains should look heavy and rusted** — not clean metal
6. **The deep background sets the MOOD** — spend the most effort here
