# AI Handoff

- **Current branch:** `codex/m15-art-v2-integration`
- **Current phase:** M1.5 Art V2 integrated; draft PR #6 open for review
- **Next owner:** Claude and Game Director for visual/gameplay review
- **Last updated:** 2026-08-02 (Australia/Melbourne)

## Playable status

The complete M1 loop remains playable: arena wave → sacrifice → Gate Warden →
victory/defeat → restart. Normal gameplay now renders the production V2 player,
melee ghost, Ghost Archer, Ghost Arrow, Gate Warden, combat effects, and matching
HUD icons. Debug collision shapes remain off by default and available on F8.

## M1.5 integration

| Area | Integrated mapping |
| --- | --- |
| Player | idle, run, jump, fall, light attack 1, hurt, death |
| Melee ghost | idle, walk, attack, hurt, death |
| Ghost Archer | idle, retreat, aim, shoot, hurt, death |
| Ghost Arrow | supplied 32×32 projectile texture; hidden emergency fallback |
| Gate Warden | idle, walk, attack 1, hurt, death |
| Effects | blade slash, confirmed hit, post-animation death dissolve |
| HUD | HP, stamina, attack, integrity/Boss, imbalance, sacrifice icons |

Animation frames are authoritative only for presentation and for gating the
existing attack flow. Player and melee active frames are 4–5; Gate Warden active
frames are 4–5; Ghost Archer releases exactly once on shoot frame 1 after aim
reaches full draw at frame 5. Damage calculation remains entirely in
`CombatResolver`. Player defeat UI and Boss victory wait for their respective
death strips to complete.

See `docs/ART_V2_INTEGRATION_REPORT.md` for the full asset inventory, dimensions,
frame rates, pivots, foot positions, timing windows, fallbacks, and unused art.

## Architecture compliance

No frozen framework interface changed. In particular, this work leaves
`RunState`, `CombatResolver`, `DamageContext`, `DamageResult`,
`IntegrityService`, `SacrificeService`, `EventBus`, `RNGService`,
`RunCoordinator`, `EnemyBase`, the player controller/state-machine foundation,
and the Hitbox/Hurtbox pipeline unchanged. The V2 adapters live in concrete
actor/state scripts and scenes.

## Notable files

### Added

- `actors/enemies/melee_ghost.gd`
- `visuals/player_slash_visual.gd`
- `visuals/death_effect.gd`
- `visuals/one_shot_sprite.gd`
- `visuals/combat_effects.gd`
- `tests/cases/test_art_v2.gd`
- `docs/ART_V2_INTEGRATION_REPORT.md`

### Updated

- Existing player, melee ghost, Ghost Archer/Arrow, and Boss scenes/scripts
- Concrete player state scripts for animation selection and hitbox frame gating
- Existing actor configuration resources for authored strip durations
- Main composition, HUD, sacrifice panel, debug panel, and result screen
- Actor, Ghost Archer, and end-to-end run-loop tests

## Tests

- **Local:** 66 tests, 421 assertions, 0 failures
- **Engine:** Godot 4.7.1 stable headless locally; CI remains pinned to 4.3
- **Commands:**
  - `godot --headless --import`
  - `godot --headless --path . res://tests/test_runner.tscn`

Coverage added for V2 resource/scene loading, all required player mappings,
player/melee/Boss active frames, Archer release timing, hurt/death overrides,
Boss victory deferral, no post-death release, and debug-overlay defaults.

Visual evidence is stored in `assets_v2/review/integration_*.png`: idle, run,
jump, player active-frame hitbox, Archer aim/arrow, and Boss attack/death. Godot
rendered the live main scene at 640×360. The environment's interactive macOS
control service and MP4 conversion were unavailable, so no preview video was
added.

## Known limitations and next work

1. Only actions already present in gameplay are mapped. Player light attack 2,
   heavy attack, and Gate Warden attack 2 remain unused.
2. Corpse Beast art remains reserved for X03.
3. The Ghost Arrow polygon remains hidden as an emergency load-failure fallback.
4. Combat has no audio; audio integration remains outside M1.5 scope.
5. X04 now has a second supplied attack strip, but still depends on the Boss
   `PhaseController` / `AttackScheduler` foundation and an approved move design.

## Frozen interfaces

See `docs/INTERFACES.md` section 1. Changes require an ADR and Claude review.

`RunState` · `DamageContext` / `DamageResult` / `CombatResolver` ·
`IntegrityService` · `SacrificeDefinition` · `SacrificeService` · Damageable ·
`EnemyBase` · `EventBus` · `RNGService` · `RunCoordinator` · `Hitbox` / `Hurtbox`
