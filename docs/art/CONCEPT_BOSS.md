# Concept: Boss — 镇关鬼将 (Gate Guardian Ghost General)

> **Type:** Boss Character
> **Frame Size:** 96 × 96 px
> **Direction:** Face left by default (toward player)

---

## Visual Description

A towering underworld general who guards the gate between realms. Not a historical figure — a pure creation of the underworld's malice. He radiates oppressive ghost fire and wields a massive blade too heavy for any mortal.

### Scale
- **3× the player's height** — fills the 96×96 frame
- Player stands ~40px tall; Boss stands ~88px tall
- This size difference must feel threatening in-game

### Key Characteristics
- **巨大 (Gigantic):** Towers over the player. Body fills most of the frame.
- **压迫感 (Oppressive):** Broad shoulders, heavy posture. Even idle, he looms.
- **鬼火 (Ghost Fire):** Blue-green flames wreath his shoulders, blade, and eyes. This is his signature visual.
- **重刀 (Heavy Blade):** Wields a massive guandao/Heavy saber (重刀), blade alone is ~40px long.
- **Not historical:** No real armor style. This is underworld plate — organic, bone-like, demonic.
- **Horns:** Curved bone horns protrude from helmet/brow
- **Cape:** Tattered cloak of dark energy flows behind him

### Face
- No visible eyes — just two burning ghost-fire orbs in a shadowed face
- Mouth: Permanent grimace, visible fangs
- Helmet: Bone crown fused to skull

### Body Proportions (within 96×96)
- Head + horns: ~24px tall
- Torso: ~36px tall, shoulders ~56px wide
- Legs: ~28px tall
- Blade extends ~40px to the left when attacking
- Cape flows ~20px behind
- Ghost fire aura: ~8px radius around shoulders and blade

---

## Color Palette
| Part | Color | Hex |
|------|-------|-----|
| Armor (bone plate) | Dark underworld steel | `#321E37` |
| Armor highlight | Ghostly purple sheen | `#5A3264` |
| Cape | Void black with purple edge | `#1A0E1F` |
| Blade | Dark iron | `#2A2520` |
| Blade edge | Faint cold steel | `#4A4540` |
| Ghost fire (shoulders/eyes/blade) | Blue-green flame | `#1EB464` |
| Ghost fire core | Bright cyan-green | `#4AE68A` |
| Bone (horns/teeth) | Yellowed ivory | `#A0987A` |
| Shadow | Deep void | `#0F0C12` |

---

## Animations

### Idle (4 frames, 6 FPS)
- Frame 1: Standing, blade resting on ground, ghost fire flickering on shoulders
- Frame 2: Slight rise, fire intensifies
- Frame 3: Neutral, fire dims slightly
- Frame 4: Slight sink, fire returns to baseline
- **Feel:** Slow, heavy breathing. A sleeping volcano. The fire should pulse.

### Run (6 frames, 8 FPS)
- Frame 1: Left foot forward, blade dragging on ground
- Frame 2: Mid-stride, ground cracks beneath foot
- Frame 3: Right foot forward, blade lifted slightly
- Frame 4: Mid-stride, airborne moment (despite size, he moves fast)
- Frame 5: Left foot forward, blade swings
- Frame 6: Recovery
- **Feel:** Earth-shaking charge. The ground should feel like it trembles.

### Attack (5 frames, 10 FPS)
- Frame 1: Wind-up — blade raised overhead with both hands, ghost fire channels into blade
- Frame 2: Strike begins — blade swings down in a massive overhead arc
- Frame 3: Impact — blade hits ground, shockwave of ghost fire erupts
- Frame 4: Follow-through — blade drags along ground, creating fire trail
- Frame 5: Recovery — lifts blade back to resting position
- **Feel:** Devastating, slow, telegraphed. Each swing should feel like it could level a wall.

### Hurt (2 frames, 8 FPS)
- Frame 1: Recoil — staggers back, ghost fire flares defensively
- Frame 2: Recovers — plants feet, glares (fire eyes intensify)
- **Feel:** He barely feels it. The anger is more dangerous than the pain.

### Death (8 frames, 6 FPS)
- Frame 1: Blade drops from hands, embeds in ground
- Frame 2: Grabs chest — cracks appear in bone armor
- Frame 3: Ghost fire erupts from cracks
- Frame 4: Falls to one knee
- Frame 5: Both knees, head bowed
- Frame 6: Armor shatters — bone fragments fly
- Frame 7: Body dissolves into ghost fire
- Frame 8: Only the blade remains, driven into the ground, fire slowly dying
- **Feel:** Epic, slow, dramatic. The boss's death should feel like a mountain crumbling.

---

## Design Notes for AI Art Generation
1. **Scale is critical** — at 96×96, the Boss must look 3× the player's size
2. **Ghost fire is the signature** — blue-green flames on shoulders, eyes, and blade in EVERY frame
3. **The blade is massive** — it should look too heavy for any normal character to wield
4. **Bone armor, not metal** — the armor should look organic, grown from bone, not forged
5. **No symmetrical design** — the cape flows left, blade rests right — asymmetry adds menace
6. **Color: purple + blue-green fire** — distinct from all other enemies (no red, no brown)
7. **Death animation is the longest** (8 frames) — it should feel rewarding to defeat

---

## Boss Arena Visual Notes
- The boss room should have larger ghost fire braziers
- Ground should crack during boss attacks (tile variation)
- Background should darken when boss appears
- Consider a faint purple fog at screen edges during boss fight
