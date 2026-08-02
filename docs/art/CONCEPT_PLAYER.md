# Concept: Player — 岳家军普通军士 (Yue Family Army Soldier)

> **Type:** Player Character
> **Frame Size:** 48 × 48 px
> **Direction:** Faces right by default

---

## Visual Description

A common soldier of the Yue Family Army (岳家军), not Yue Fei himself. He is a grunt — worn down by endless war, now trapped in the underworld.

### Key Characteristics
- **残破盔甲 (Broken Armor):** Song dynasty lamellar armor (步人甲), cracked and missing plates. Visible chainmail beneath torn cloth.
- **布甲 (Cloth Armor):** Simple padded gambeson (绵甲) underneath, dark brown fabric with frayed edges.
- **朴素 (Plain):** No ornamentation. No insignia. No gleam. This is a foot soldier, not a general.
- **一把宋刀 (Single Song Sword):** Wielded right-handed. Straight-backed dao (直背刀), blade nicked and dark.
- **黑红色调 (Dark Red Tone):** Palette dominated by dried blood red, rust brown, ash grey. No bright colors.

### Face
- Half-shadowed, eyes glowing faintly (residual life force)
- Simple headband or helmet rim — broken
- No expression — dead-eyed determination

### Body Proportions (within 48×48)
- Head: ~12px tall, centered
- Torso: ~16px tall, shoulders ~20px wide
- Legs: ~14px tall
- Sword extends ~16px to the right when attacking
- Total silhouette ~40px tall, 24px wide (standing)

---

## Color Palette
| Part | Color | Hex |
|------|-------|-----|
| Armor plates | Dried blood red | `#5A322B` |
| Armor highlight | Faded rust | `#7A4235` |
| Cloth/gambeson | Dark ash brown | `#3A2E25` |
| Skin | Pale corpse grey | `#8A7A6A` |
| Sword blade | Dark iron | `#4A4035` |
| Sword edge | Faint steel | `#6A5A4A` |
| Eyes | Faint ghost glow | `#B4641E` |
| Shadow | Deep void | `#0F0C12` |

---

## Animations

### Idle (4 frames, 8 FPS)
- Frame 1: Standing, sword at side, slight slouch
- Frame 2: Very slight rise (breathing in)
- Frame 3: Neutral (same as 1, minor variation)
- Frame 4: Slight sink (breathing out)
- **Feel:** Exhausted, haunted, but ready. Not a heroic idle — a tired soldier's.

### Run (6 frames, 12 FPS)
- Frame 1: Left foot forward, sword arm back
- Frame 2: Mid-stride, weight transitioning
- Frame 3: Right foot forward, sword arm forward
- Frame 4: Mid-stride, airborne moment
- Frame 5: Left foot forward, leaning
- Frame 6: Recovery to frame 1
- **Feel:** Heavy, armored clank. Not graceful — burdened running.

### Jump (2 frames, 10 FPS)
- Frame 1: Crouch + launch (knees bent, sword raised)
- Frame 2: Apex (legs tucked, sword overhead)
- **Feel:** Desperate leap, not athletic jump.

### Attack (4 frames, 14 FPS)
- Frame 1: Wind-up — sword pulled back to right shoulder
- Frame 2: Strike — horizontal slash, sword fully extended left
- Frame 3: Follow-through — sword sweeping down
- Frame 4: Recovery — returning to guard
- **Feel:** Brutal, heavy slash. Military sword technique, not flashy.

### Hurt (2 frames, 10 FPS)
- Frame 1: Impact — recoil backward, head snapped
- Frame 2: Stagger — off-balance, one knee buckling
- **Feel:** Painful but recovering. Not a knockdown.

### Death (6 frames, 8 FPS)
- Frame 1: Sword drops from hand
- Frame 2: Knees buckle
- Frame 3: Falling forward
- Frame 4: Hits ground on hands
- Frame 5: Collapses fully
- Frame 6: Dissolves into dark particles (entering the underworld)
- **Feel:** Slow, inevitable. A soldier's final fall.

---

## Design Notes for AI Art Generation
1. Keep the silhouette readable at 48×48 — avoid excessive detail
2. The sword should be clearly visible in all frames (it's the identity)
3. Armor damage should be consistent across all animations
4. The dark red palette must dominate — no blues, no greens on the player
5. Eyes glow faintly orange (ghost fire) — this is the only warm accent
