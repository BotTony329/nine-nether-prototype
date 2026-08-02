# Godot 4 Import Presets — 九幽

> **Purpose:** Default import settings for all texture assets.
> **Usage:** When first opening the project in Godot 4, apply these settings via the Import dock.

## Default Texture Import Settings (2D Pixel Art)

Apply to ALL `.png` files in `assets/`:

```ini
# In Godot Import dock, select all PNGs and set:
preset = "2D Pixel"
compress/mode = 0          # Lossless
compress/lossy_quality = 0.7
mipmaps/generate = false
process/fix_alpha_border = true
process/premult_alpha = false
process/normal_map_invert_y = false
process/hdr_as_srgb = false
process/hdr_clamp_exposure = false
process/size_limit = 0
detect_3d/compress_to = 0
```

## project.godot Settings (recommended)

```ini
[rendering]
textures/canvas_textures/default_texture_filter = 0
renderer/rendering_method = "gl_compatibility"

[display]
window/size/viewport_width = 1280
window/size/viewport_height = 720
window/stretch/mode = "viewport"
window/stretch/aspect = "keep"
```

## SpriteFrames Auto-Setup Reference

When creating SpriteFrames resources, reference the metadata files in each directory:

| Directory | Metadata File | Contains |
|-----------|--------------|----------|
| `assets/player/` | `metadata.md` | Frame counts, sizes, FPS for all player animations |
| `assets/enemy/` | `metadata.md` | Frame counts, sizes, FPS for all enemy animations |
| `assets/boss/` | `metadata.md` | Frame counts, sizes, FPS for all boss animations |
| `assets/effects/` | `metadata.md` | Frame counts, sizes, FPS for all effects |
| `assets/tiles/` | `metadata.md` | Tile specs and collision info |
| `assets/background/` | `metadata.md` | Background element specs and parallax info |
| `assets/ui/` | `metadata.md` | UI element specs and layout info |

## Naming → Animation Mapping

### Player SpriteFrames
| Animation Name | Source File | H-Frames |
|----------------|-------------|----------|
| idle | `res://assets/player/player_idle.png` | 4 |
| run | `res://assets/player/player_run.png` | 6 |
| jump | `res://assets/player/player_jump.png` | 2 |
| attack | `res://assets/player/player_attack.png` | 4 |
| hurt | `res://assets/player/player_hurt.png` | 2 |
| death | `res://assets/player/player_death.png` | 6 |

### Ghost Soldier (鬼卒) SpriteFrames
| Animation Name | Source File | H-Frames |
|----------------|-------------|----------|
| idle | `res://assets/enemy/ghost_melee_idle.png` | 4 |
| run | `res://assets/enemy/ghost_melee_run.png` | 6 |
| attack | `res://assets/enemy/ghost_melee_attack.png` | 4 |
| hurt | `res://assets/enemy/ghost_melee_hurt.png` | 2 |
| death | `res://assets/enemy/ghost_melee_death.png` | 4 |

### Ghost Archer (鬼弓手) SpriteFrames
| Animation Name | Source File | H-Frames |
|----------------|-------------|----------|
| idle | `res://assets/enemy/ghost_archer_idle.png` | 4 |
| run | `res://assets/enemy/ghost_archer_run.png` | 6 |
| attack | `res://assets/enemy/ghost_archer_attack.png` | 4 |
| hurt | `res://assets/enemy/ghost_archer_hurt.png` | 2 |
| death | `res://assets/enemy/ghost_archer_death.png` | 4 |

### Corpse Beast (尸兽) SpriteFrames
| Animation Name | Source File | H-Frames | Frame Size |
|----------------|-------------|----------|------------|
| idle | `res://assets/enemy/corpse_beast_idle.png` | 4 | 64×48 |
| run | `res://assets/enemy/corpse_beast_run.png` | 6 | 64×48 |
| attack | `res://assets/enemy/corpse_beast_attack.png` | 4 | 64×48 |
| hurt | `res://assets/enemy/corpse_beast_hurt.png` | 2 | 64×48 |
| death | `res://assets/enemy/corpse_beast_death.png` | 4 | 64×48 |

### Boss (镇关鬼将) SpriteFrames
| Animation Name | Source File | H-Frames | Frame Size |
|----------------|-------------|----------|------------|
| idle | `res://assets/boss/boss_idle.png` | 4 | 96×96 |
| run | `res://assets/boss/boss_run.png` | 6 | 96×96 |
| attack | `res://assets/boss/boss_attack.png` | 5 | 96×96 |
| hurt | `res://assets/boss/boss_hurt.png` | 2 | 96×96 |
| death | `res://assets/boss/boss_death.png` | 8 | 96×96 |

### Effects SpriteFrames
| Animation Name | Source File | H-Frames | Loop |
|----------------|-------------|----------|------|
| hit_slash | `res://assets/effects/effect_hit_slash.png` | 2 | No |
| blood_splash | `res://assets/effects/effect_blood_splash.png` | 4 | No |
| ghost_fire | `res://assets/effects/effect_ghost_fire.png` | 4 | Yes |
| death_fade | `res://assets/effects/effect_death_fade.png` | 4 | No |
