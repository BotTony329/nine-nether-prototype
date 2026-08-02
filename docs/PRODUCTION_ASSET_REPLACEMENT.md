# Production Asset Replacement — Sprint 01

**Source of truth:** `assets_v3/review/character_lineup.png`
**Branch:** `codex/production-asset-sprint-01`

This matrix is limited to assets that are instantiated by the current playable
M1 scenes, plus the combat-readability effects explicitly approved for this
sprint. Future characters, attacks, phases, props, inventory art, and weapons
are excluded.

| Current asset | Scene / consumer | Replacement asset | Priority |
| --- | --- | --- | --- |
| `assets/player/player_idle.png` | `actors/player/player_frames.tres` | `assets_v3/production/player/player_idle.png` | P0 |
| `assets/player/player_run.png` | `actors/player/player_frames.tres` | `assets_v3/production/player/player_walk.png` | P0 |
| `assets/player/player_attack.png` | `actors/player/player_frames.tres` | `assets_v3/production/player/player_attack.png` | P0 |
| `assets/player/player_hurt.png` | `actors/player/player_frames.tres` | `assets_v3/production/player/player_hurt.png` | P0 |
| `assets/player/player_death.png` | `actors/player/player_frames.tres` | `assets_v3/production/player/player_death.png` | P0 |
| `assets/player/player_jump.png` | player jump state | production idle frame reused; no new jump art in Sprint 01 | P0 |
| `assets/enemy/ghost_melee_*` | `actors/enemies/ghost_melee_frames.tres` | `assets_v3/production/ghost_melee/ghost_melee_*.png` | P0 |
| `assets/enemy/ghost_archer_*` | `actors/enemies/ghost_archer_frames.tres` | `assets_v3/production/ghost_archer/ghost_archer_*.png` | P0 |
| `Polygon2D` arrow fallback | `actors/enemies/ghost_arrow.tscn` | `assets_v3/production/projectiles/ghost_arrow.png` | P0 |
| `assets/boss/boss_*` | `actors/boss/boss_frames.tres` | `assets_v3/production/gate_warden/gate_warden_*.png` | P0 |
| `assets/tiles/tile_floor.png` | `scenes/arena.tscn` floor region | `assets_v3/production/environment/stone_floor.png` | P0 |
| `assets/tiles/tile_stone_brick.png` | arena wall/boundary sprites | `assets_v3/production/environment/stone_wall.png` | P0 |
| arena tomb/flag focal prop | `scenes/arena.tscn` | `assets_v3/production/environment/fortress_gate.png` | P1 |
| `assets/background/bg_deep.png`, `bg_tree.png`, `bg_chains.png` | arena parallax | `assets_v3/production/environment/battlefield_fog.png` and retained non-placeholder composition layers | P1 |
| brazier placeholder | `scenes/arena.tscn` | `assets_v3/production/effects/ghost_fire.png` | P1 |
| no production slash feedback | player attack presentation | `assets_v3/production/effects/slash.png` | P1 |
| no confirmed-hit feedback | EventBus observer | `assets_v3/production/effects/hit.png` | P1 |
| no blood feedback | EventBus observer | `assets_v3/production/effects/blood.png` | P1 |
| `assets/effects/effect_death_fade.png` | death presentation | `assets_v3/production/effects/death.png` | P1 |
| `assets/icons/ui/icon_hp.png` | `ui/hud.tscn` | `assets_v3/production/icons/icon_hp.png` | P1 |
| `assets/icons/ui/icon_boss.png` | `ui/hud.tscn` | `assets_v3/production/icons/icon_boss.png` | P1 |
| `assets/icons/ui/icon_sacrifice.png` | `ui/sacrifice_panel.tscn` | `assets_v3/production/icons/icon_sacrifice.png` | P1 |

## Explicit exclusions

- Player heavy attack and second light attack
- Gate Warden second phase or special attacks
- Corpse Beast and other future enemies
- Unused tiles, weapon icons, inventory frame, minimap frame, and decorative props
- Any gameplay, balance, state-machine, collision, Hitbox/Hurtbox, or
  `CombatResolver` redesign

## Production output

All generated deliverables are transparent, lossless RGBA PNGs under
`assets_v3/production/`. The committed `source/` boards have already had the
flat chroma field removed; `assets_v3/tools/build_production_assets.py`
deterministically rebuilds the normalized strips and metadata from them.

| Group | Delivered |
| --- | --- |
| Player | idle 4, walk 6, attack 4, hurt 2, death 6 |
| Ghost Melee | idle 4, walk 6, attack 4, hurt 2, death 4 |
| Ghost Archer | idle 4, walk 6, attack 4, hurt 2, death 4 |
| Gate Warden | idle 4, walk 6, attack 5, hurt 2, death 8 |
| Environment | stone floor, fortress wall, fortress gate, battlefield fog |
| Combat effects | slash, hit, blood, ghost fire, death dissolve |
| Interface | HP, Boss, and sacrifice icons |
| Projectile | Ghost Arrow |

### Final actor visual alignment

Collision bodies and their origins are unchanged. Each character owns its
visual transform in its actor scene; equal numeric values for the two ghosts
are explicit per-scene declarations, not a shared global offset.

| Actor | Frame | Declared pivot / foot | Sprite position | Sprite scale | Visual foot at actor origin |
| --- | --- | --- | --- | --- | --- |
| Player | 192×160 | (96, 150) | (0, -25.2) | 0.36 | 0.0 px |
| Ghost Melee | 192×160 | (96, 150) | (0, -25.2) | 0.36 | 0.0 px |
| Ghost Archer | 192×160 | (96, 150) | (0, -25.2) | 0.36 | 0.0 px |
| Gate Warden | 320×256 | (160, 248) | (0, -48) | 0.40 | 0.0 px |

The validation formula is `sprite_y + (foot_y - frame_height / 2) * scale_y`.
`tests/cases/test_production_assets.gd` checks it against every instantiated
actor scene.

## Validation

- Godot 4.7.1 real-renderer captures:
  `docs/screenshots/art_v3_wave.png`, `art_v3_boss.png`,
  `art_v3_lineup.png`, and `art_v3_combat.png`.
- Full headless suite: **64 tests, 438 assertions, 0 failures**.
- Confirmed no missing textures, broken actor animations, or altered actor
  collision/attack shapes.
- Confirmed Player, Ghost Melee, Ghost Archer, Gate Warden, and Ghost Arrow all
  resolve their live visuals from `assets_v3/production/`.

## Known limitations and remaining placeholders

- The player jump state reuses the first two production idle frames. This is a
  deliberate temporary fallback because Sprint 01 was limited to idle, walk,
  attack, hurt, and death.
- The approved generated boards contain three unique Ghost Melee idle poses,
  three unique Gate Warden idle poses, and seven unique Gate Warden death
  poses. A settled frame is repeated to preserve the existing framework's
  established frame counts and timings.
- The existing deep/tree/chain parallax composition and the health/stamina bar
  frames remain in use. They were outside this sprint's approved replacement
  list; the new fog layer, production environment tiles, gate, and icons render
  with them.
- Future enemies, unused tiles, inventory/minimap UI, weapon icons, heavy
  attack, additional Boss attacks, and audio remain intentionally untouched.

## Recommended Sprint 02

Produce the missing player jump/fall set, replace the remaining parallax and
bar-frame presentation with V3-approved assets, then author additional content
only after separate art-direction approval. Do not combine that work with
Boss phase-two or new gameplay-state implementation.
