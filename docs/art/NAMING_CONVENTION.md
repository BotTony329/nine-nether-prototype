# Naming Convention — 九幽 Art Assets

> **Rule:** All filenames follow `<prefix>_<entity>_<action>.png`
> **All lowercase, underscores only, no spaces, no version numbers**

---

## Prefixes

| Prefix | Directory | Example |
|--------|-----------|---------|
| `player_` | `assets/player/` | `player_idle.png` |
| `ghost_melee_` | `assets/enemy/` | `ghost_melee_attack.png` |
| `ghost_archer_` | `assets/enemy/` | `ghost_archer_idle.png` |
| `corpse_beast_` | `assets/enemy/` | `corpse_beast_run.png` |
| `boss_` | `assets/boss/` | `boss_death.png` |
| `weapon_` | `assets/icons/weapons/` | `weapon_songdao.png` |
| `icon_` | `assets/icons/ui/` | `icon_hp.png` |
| `tile_` | `assets/tiles/` | `tile_floor.png` |
| `effect_` | `assets/effects/` | `effect_blood_splash.png` |
| `bg_` | `assets/background/` | `bg_tree.png` |
| `ui_` | `assets/ui/` | `ui_health_bar.png` |

## Actions (for animated sprites)

| Action | Description |
|--------|-------------|
| `idle` | Default standing/breathing |
| `run` | Lateral movement |
| `jump` | Vertical launch |
| `attack` | Offensive action |
| `hurt` | Taking damage |
| `death` | Dying animation |

## Forbidden Names

❌ `新建文件.png`
❌ `image1.png`
❌ `最终版2.png`
❌ `player_idle_v2.png`
❌ `Player Idle.png`
❌ `player-idle.png`
❌ `temp.png`

## Replacement Rule

When replacing a placeholder, the new file MUST have the **exact same filename** and **exact same pixel dimensions**. No version numbers — use git for versioning.
