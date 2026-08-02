# Concept: Visual Effects — 特效

> **Type:** VFX Sprites
> **Size:** 48 × 48 px (all effects)
> **Style:** Quick, impactful, dark fantasy

---

## Design Philosophy
- Effects are **fast** — visible for 2-6 frames (0.1-0.4 seconds)
- Each effect should read clearly even in chaotic combat
- Colors should contrast with the dark environment
- All effects use transparent backgrounds
- Effects are centered in the 48×48 frame

---

## Effect Designs (4 total)

### 1. effect_hit_slash.png — 斩击特效 (Hit Slash)
- **Type:** Single-frame (or 2-frame) impact effect
- **Description:** A white/silver slash arc — appears when player or enemy lands a melee hit
- **Colors:** Core `#E0E0E0`, edge `#A0A0A0`, outline `#606060`
- **Frame layout:** 2 frames — Frame 1: slash arc expanding, Frame 2: slash dissipating
- **Notes:** Diagonal slash arc, ~36px long. Should feel like a blade cut through air.
- **Engine usage:** Spawn at hit position, play 2 frames at 20 FPS, destroy.

### 2. effect_blood_splash.png — 鲜血飞溅 (Blood Splash)
- **Type:** Multi-frame particle burst
- **Description:** Dark crimson blood particles exploding outward
- **Colors:** Core `#5A1818`, spray `#8A2828`, droplets `#3A0808`
- **Frame layout:** 4 frames — expanding burst, particles flying, particles falling, fade
- **Notes:** Radial burst from center. 8-12 particles. Dark blood, not bright red.
- **Engine usage:** Spawn at damage position, play 4 frames at 15 FPS, destroy.

### 3. effect_ghost_fire.png — 鬼火特效 (Ghost Fire)
- **Type:** Looping ambient effect
- **Description:** Floating blue-green flame — used for brazier light, boss aura, projectile trail
- **Colors:** Core `#4AE68A`, mid `#1EB464`, outer `#0A5030`
- **Frame layout:** 4 frames — flame flickering (loop)
- **Notes:** Teardrop shape, pointed top. Flickers organically. Can be scaled for different uses.
- **Engine usage:** Loop at 10 FPS. Can be used as light source texture.

### 4. effect_death_fade.png — 死亡消散 (Death Fade)
- **Type:** Multi-frame dissolve
- **Description:** Character body dissolving into dark particles — used on enemy death
- **Colors:** Body `#3A2E35` (generic), particles `#1A151F`, glow `#2A1E2F`
- **Frame layout:** 4 frames — body intact → cracking → fragmenting → fully dissolved
- **Notes:** Vertical dissolve — bottom fades first. Particles drift upward (soul ascending).
- **Engine usage:** Play 4 frames at 8 FPS after death animation. Destroy after.

---

## Future Effects (Not Required for Prototype)
| Effect | Description |
|--------|-------------|
| effect_dash_trail.png | Player dash afterimage |
| effect_parry_spark.png | Parry successful spark |
| effect_sacrifice_aura.png | Sacrifice activation glow |
| effect_level_up.png | Power gain burst |
| effect_screen_shake.png | (Not a sprite — engine effect) |

---

## Design Notes for AI Art Generation
1. Effects should be **brighter than the environment** — they need to pop
2. Blood is **dark crimson**, not cartoon red — this is a dark fantasy game
3. Ghost fire is **blue-green**, not orange — this is the underworld's fire
4. All effects are **centered** in the 48×48 frame — origin point is center
5. Keep particle count readable at 48px — 8-12 particles max per effect
