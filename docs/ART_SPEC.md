# 九幽 — Art Specification (美术资源规范)

> **STATUS: ACTIVE — Prototype Phase**
> **Owner:** WorkBuddy (Art Director / Asset Pipeline Engineer)
> **Last Updated:** 2026-08-02

This document is the **single source of truth** for all visual art assets in the Nine Nether prototype. Claude and Codex should read this before referencing any sprite, icon, tile, or UI element.

---

## 1. Art Direction

### Style
- **Genre:** 2D Side-scrolling Action Roguelite
- **Visual Style:** Chinese Dark Fantasy Pixel Art (中国黑暗幻想像素风)
- **Era Reference:** Southern Song Dynasty (南宋) — Underworld / Hell (地府) — Ghosts & Demons (鬼怪) — Ancient Warfare (古代战争)
- **DO NOT reference:** Anime style, Chibi/Q-version, Western cartoon, any existing game directly

### Tone
- Oppressive, somber, decayed
- Muted palette with strategic accents of ghost-fire orange and blood red
- Textures should feel worn, broken, ancient — never clean or pristine

### Color Philosophy
| Role | Hex | Usage |
|------|-----|-------|
| Deep Void | `#0F0C12` | Backgrounds, shadows |
| Ash Stone | `#28231E` | Tiles, environment |
| Dried Blood | `#78322B` | Player base, blood |
| Ghost Blue | `#2D3746` | Ghost enemies |
| Corpse Flesh | `#372823` | Beast enemies |
| Underworld Purple | `#321E37` | Boss, sacrifice |
| Ghost Fire | `#B4641E` | Accents, fire, energy |
| Pale Bone | `#C4B89A` | Highlights, bone, pale skin |
| Rust Iron | `#5A4632` | Metal, armor |
| Yin Coin Gold | `#8B7332` | Currency, treasure |

---

## 2. Pixel Art Standards

### Resolution & Scale
| Asset Type | Frame Size | Notes |
|------------|-----------|-------|
| Player sprite | 48 × 48 px | Per animation frame |
| Enemy sprites (humanoid) | 48 × 48 px | Ghost Soldier, Ghost Archer |
| Enemy sprites (beast) | 64 × 48 px | Corpse Beast (wider, quadruped) |
| Boss sprite | 96 × 96 px | Larger than player for intimidation |
| Weapon icons | 32 × 32 px | Unified |
| UI icons | 32 × 32 px | Unified |
| Tiles | 32 × 32 px | Grid-based, tileable |
| Effects | 48 × 48 px | Combat VFX |
| Background elements | Varies | See individual metadata |
| UI elements | Varies | See individual metadata |

### Sprite Sheet Format
- **Layout:** Horizontal strip (frames arranged left-to-right)
- **Background:** Transparent (alpha channel)
- **Format:** PNG (lossless)
- **Filter:** Nearest-neighbor (no anti-aliasing)
- **Color depth:** RGBA 32-bit

### Animation Frame Counts
| Animation | Frames | Purpose |
|-----------|--------|---------|
| Idle | 4 | Subtle breathing / hovering |
| Run | 6 | Full run cycle |
| Jump | 2 | Launch + apex |
| Attack | 4-5 | Wind-up → strike → recovery |
| Hurt | 2 | Impact + stagger |
| Death | 4-8 | Collapse / dissolve |

### Frame Rate
- Default: 10 FPS (0.1s per frame)
- Attack: 12-15 FPS (snappier)
- Death: 6-8 FPS (slower, dramatic)

---

## 3. Naming Convention

### Pattern
```
<category>_<entity>_<action>.png
```

### Rules
1. **All lowercase**, words separated by underscores
2. **No spaces, no Chinese characters, no special chars** in filenames
3. **No version numbers** in filenames (use git, not `v2_final.png`)
4. **No generic names** like `image1.png`, `新建文件.png`
5. Sprite sheets use the action name, not frame numbers

### Examples
```
player_idle.png          ← Player idle animation (4-frame sheet)
player_run.png           ← Player run animation (6-frame sheet)
ghost_melee_attack.png   ← Ghost Soldier attack animation
boss_death.png           ← Boss death animation
weapon_songdao.png       ← Song Dynasty sword icon
icon_hp.png              ← HP UI icon
tile_floor.png           ← Floor tile
effect_blood_splash.png  ← Blood splash VFX
bg_tree.png              ← Background tree
ui_health_bar.png        ← Health bar UI element
```

### Category Prefixes
| Prefix | Directory | Description |
|--------|-----------|-------------|
| `player_` | `assets/player/` | Player character sprites |
| `ghost_melee_` | `assets/enemy/` | Ghost Soldier (鬼卒) |
| `ghost_archer_` | `assets/enemy/` | Ghost Archer (鬼弓手) |
| `corpse_beast_` | `assets/enemy/` | Corpse Beast (尸兽) |
| `boss_` | `assets/boss/` | Boss sprites |
| `weapon_` | `assets/icons/weapons/` | Weapon icons |
| `icon_` | `assets/icons/ui/` | UI stat icons |
| `tile_` | `assets/tiles/` | Tilemap tiles |
| `effect_` | `assets/effects/` | Visual effects |
| `bg_` | `assets/background/` | Background elements |
| `ui_` | `assets/ui/` | UI elements (bars, frames) |

---

## 4. Directory Structure

```
assets/
├── ART_SPEC.md              ← This file (master spec)
├── generate_placeholders.py ← Placeholder generation script
├── player/                  ← Player character sprites
│   ├── README.md
│   ├── metadata.md
│   └── *.png
├── enemy/                   ← All enemy sprites
│   ├── README.md
│   ├── metadata.md
│   └── *.png
├── boss/                    ← Boss sprites
│   ├── README.md
│   ├── metadata.md
│   └── *.png
├── icons/
│   ├── weapons/             ← 32×32 weapon icons
│   │   ├── README.md
│   │   └── *.png
│   └── ui/                  ← 32×32 UI stat icons
│       ├── README.md
│       └── *.png
├── tiles/                   ← 32×32 tilemap tiles
│   ├── README.md
│   ├── metadata.md
│   └── *.png
├── effects/                 ← 48×48 VFX sprites
│   ├── README.md
│   ├── metadata.md
│   └── *.png
├── background/              ← Parallax / decorative backgrounds
│   ├── README.md
│   ├── metadata.md
│   └── *.png
└── ui/                      ← UI elements (bars, frames)
    ├── README.md
    ├── metadata.md
    └── *.png
```

---

## 5. Placeholder Policy

All current PNGs are **placeholders** generated programmatically. They:
- Use the correct dimensions and sprite sheet layout
- Have a magenta border (1px) marking them as placeholders
- Show a checkerboard pattern + simple silhouette
- Can be directly replaced by dropping a new PNG with the same filename

### Replacement Workflow
1. Generate or commission the final pixel art
2. Save with the **exact same filename** and **exact same dimensions**
3. Run `git add assets/ && git commit -m "[Art] Replace <filename> placeholder with final art"`
4. The Godot import settings will remain valid as long as dimensions match

### How to Identify Placeholders
- Magenta (#FF00FF) 1px border = placeholder
- Checkerboard interior = placeholder
- Once replaced, remove the magenta border from the final art

---

## 6. Godot 4 Import Settings

### Texture Import (per PNG)
| Setting | Value |
|---------|-------|
| Preset | 2D Pixel |
| Filter | Off (Nearest) |
| Mipmaps | Off |
| Compression | Lossless |
| HDR | Off |

### Sprite Sheet → AnimatedSprite2D
1. Import the PNG as a texture
2. In the SpriteFrames editor, create a new animation
3. Set "Horizontal frames" to the frame count from metadata
4. Set FPS per the metadata (default 10)

### Recommended Godot Resource Path
```
res://assets/player/player_idle.png → SpriteFrames → "idle" animation
res://assets/player/player_run.png  → SpriteFrames → "run" animation
```

See `docs/art/GODOT_IMPORT_GUIDE.md` for step-by-step instructions.

---

## 7. Asset Inventory

### Player (6 sheets, 24 total frames)
| File | Frames | Size | FPS |
|------|--------|------|-----|
| player_idle.png | 4 | 192×48 | 8 |
| player_run.png | 6 | 288×48 | 12 |
| player_jump.png | 2 | 96×48 | 10 |
| player_attack.png | 4 | 192×48 | 14 |
| player_hurt.png | 2 | 96×48 | 10 |
| player_death.png | 6 | 288×48 | 8 |

### Enemies (15 sheets, 70 total frames)
| File | Frames | Size | FPS |
|------|--------|------|-----|
| ghost_melee_idle.png | 4 | 192×48 | 8 |
| ghost_melee_run.png | 6 | 288×48 | 10 |
| ghost_melee_attack.png | 4 | 192×48 | 12 |
| ghost_melee_hurt.png | 2 | 96×48 | 10 |
| ghost_melee_death.png | 4 | 192×48 | 8 |
| ghost_archer_idle.png | 4 | 192×48 | 8 |
| ghost_archer_run.png | 6 | 288×48 | 10 |
| ghost_archer_attack.png | 4 | 192×48 | 12 |
| ghost_archer_hurt.png | 2 | 96×48 | 10 |
| ghost_archer_death.png | 4 | 192×48 | 8 |
| corpse_beast_idle.png | 4 | 256×48 | 8 |
| corpse_beast_run.png | 6 | 384×48 | 14 |
| corpse_beast_attack.png | 4 | 256×48 | 12 |
| corpse_beast_hurt.png | 2 | 128×48 | 10 |
| corpse_beast_death.png | 4 | 256×48 | 8 |

### Boss (5 sheets, 25 total frames)
| File | Frames | Size | FPS |
|------|--------|------|-----|
| boss_idle.png | 4 | 384×96 | 6 |
| boss_run.png | 6 | 576×96 | 8 |
| boss_attack.png | 5 | 480×96 | 10 |
| boss_hurt.png | 2 | 192×96 | 8 |
| boss_death.png | 8 | 768×96 | 6 |

### Icons (17 total, all 32×32)
- Weapons: 6 (songdao, spear, ghostfire, talisman, gourd, flag)
- UI: 11 (hp, stamina, attack, armor, crit, speed, sacrifice, ghostfire, boss, key, coin)

### Tiles (7 total, all 32×32)
floor, stone_brick, wall, wood_bridge, brazier, tombstone, ground_spike

### Effects (4 total, all 48×48)
hit_slash, blood_splash, ghost_fire, death_fade

### Background (4 total)
tree (64×128), broken_flag (48×96), chains (32×96), deep (320×180)

### UI Elements (4 total)
health_bar (96×16), stamina_bar (96×16), frame (32×32), minimap_frame (64×64)

---

## 8. Concept Documents

Detailed visual concept descriptions for each entity:

| Document | Contents |
|----------|----------|
| `docs/art/CONCEPT_PLAYER.md` | Player character — Yue Family Army Soldier |
| `docs/art/CONCEPT_ENEMIES.md` | Ghost Soldier, Ghost Archer, Corpse Beast |
| `docs/art/CONCEPT_BOSS.md` | Gate Guardian Ghost General |
| `docs/art/CONCEPT_ICONS.md` | Weapon & UI icon designs |
| `docs/art/CONCEPT_TILES.md` | Tile & environment designs |
| `docs/art/CONCEPT_EFFECTS.md` | VFX designs |
| `docs/art/CONCEPT_BACKGROUND.md` | Background layer designs |
| `docs/art/CONCEPT_UI.md` | UI element designs |

---

## 9. AI Handoff Notes

- **For Claude:** All sprite sheets are horizontal strips. Frame counts and sizes are in each directory's `metadata.md`. Import with `filter=off, mipmaps=off` in Godot.
- **For art generation AI:** Replace any placeholder PNG with pixel art matching the same dimensions. Remove the magenta border. Follow the concept documents for visual direction.
- **Palette file:** See color table in Section 1. Use these exact hex values for consistency.
