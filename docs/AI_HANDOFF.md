# AI Handoff

- **Current branch:** `codex/m2-runtime-art-source-fix`
- **Current phase:** M2 Ghost Market loop integrated with the Art V3 runtime
- **Next owner:** Game Director for integration review
- **Last updated:** 2026-08-02 (Australia/Melbourne)

## Playable status

The game now opens in the **Ghost Market**: start a run, fight, die or win, read
the run result, return to the market with soul ash banked, buy the one upgrade,
run again. See `docs/GHOST_MARKET_LOOP.md`.

The complete M1 loop remains playable: arena wave → sacrifice → Gate Warden →
victory/defeat → restart. Normal gameplay now renders the approved Art V3
player, melee ghost, Ghost Archer, Ghost Arrow, Gate Warden, environment,
combat effects, and primary HUD icons. Develop's gameplay architecture,
authored attack timing, collision geometry, and additional HUD statistics are
preserved. Debug collision shapes remain off by default and available on F8.

## Art V3 production integration

The V3 production strips are mapped into develop's established animation names
and frame-event contracts. Where a four- or five-pose approved strip is shorter
than develop's authored timing map, source poses are deliberately held across
multiple frames; this preserves startup, active, release, and recovery events
without changing gameplay scripts. Scene-local sprite position and scale keep
each declared V3 foot position on the stable actor origin. Combat feedback uses
the V3 slash, hit, blood, and death sheets, while damage remains exclusively in
`CombatResolver`.

The merge with current `develop` retained its player, melee ghost, Ghost Archer,
Boss, HUD, result-flow, and debug integration. The hidden Ghost Arrow polygon is
kept only as develop's emergency fallback; normal rendering uses the V3 arrow.
See `docs/PRODUCTION_ASSET_REPLACEMENT.md` and the V3 production `frame_map.json`
files for the replacement inventory and metadata.

## M2 Ghost Market loop

| Piece | Where |
| --- | --- |
| Main scene | `scenes/app.tscn` — owns `MetaState`, swaps market and run |
| Hub | `scenes/ghost_market.tscn` — soul ash, latest run, one upgrade, start, reset |
| Persisted state | `core/meta_state.gd` — soul ash, runs, deaths, victories, Tempered Blade |
| Run summary | `systems/run_result.gd` — outcome, duration, kills, sacrifices, integrity, imbalance, soul ash |
| Save | `core/meta_save.gd` — `user://meta_save.json`, versioned, path injectable |
| Meta tunables | `data/meta_config.tres` — reward rates and upgrade cost, apart from `BalanceConfig` |

Death and victory share one run-end pipeline; duplicate end requests are ignored
at both the coordinator and the app layer. Combat, enemy AI, the sacrifice
system, balance values, art and animations were not modified. The two changes to
existing gameplay code are recorded as ADR-013 (`run_finished` now carries a
`RunResult`; `RunState.add_flat_attack` added) and ADR-014 (one live child scene
rather than hiding the idle one — a hidden `Node2D` does not hide its
`CanvasLayer` children, and the market was drawing over the run).

Market visuals reuse existing floor, brick, brazier and ghost-fire art and are
decoration only: no script reads them, so real market art changes no code.

## M1.5 integration

| Area | Integrated mapping |
| --- | --- |
| Player | idle, run, jump, fall, light attack 1, hurt, death |
| Melee ghost | idle, walk, attack, hurt, death |
| Ghost Archer | idle, retreat, aim, shoot, hurt, death |
| Ghost Arrow | supplied 32×32 projectile texture; hidden emergency fallback |
| Gate Warden | idle, walk, attack 1, hurt, death |
| Effects | blade slash, confirmed hit, post-animation death dissolve |
| HUD | V3 HP, Boss and sacrifice icons; text/bar stats retain existing behaviour |

Animation frames are authoritative only for presentation and for gating the
existing attack flow. Player and melee active frames are 4–5; Gate Warden active
frames are 4–5; Ghost Archer releases exactly once on shoot frame 1 after aim
reaches full draw at frame 5. Damage calculation remains entirely in
`CombatResolver`. Player defeat UI and Boss victory wait for their respective
death strips to complete.

See `docs/ART_V2_INTEGRATION_REPORT.md` for the full asset inventory, dimensions,
frame rates, pivots, foot positions, timing windows, fallbacks, and unused art.

## Architecture compliance

The integration makes no new frozen-interface change. It retains Claude's M2
additions to `RunState` and `RunCoordinator`, documented in ADR-013, while
leaving `CombatResolver`, `DamageContext`, `DamageResult`, `IntegrityService`,
`SacrificeService`, `EventBus`, `RNGService`, `EnemyBase`, the player
controller/state-machine foundation, and the Hitbox/Hurtbox pipeline unchanged.
Production animation adapters remain in concrete actor/state scripts and scenes.

## Notable files

### Added

- `actors/enemies/melee_ghost.gd`
- `visuals/player_slash_visual.gd`
- `visuals/death_effect.gd`
- `tests/cases/test_art_v2.gd`
- `docs/ART_V2_INTEGRATION_REPORT.md`

### Updated

- Existing player, melee ghost, Ghost Archer/Arrow, and Boss scenes/scripts
- Concrete player state scripts for animation selection and hitbox frame gating
- Existing actor configuration resources for authored strip durations
- Main composition, HUD, sacrifice panel, debug panel, and result screen
- Actor, Ghost Archer, and end-to-end run-loop tests

## Tests

- **Local:** 85 tests, 796 assertions, 0 failures
- **Engine:** Godot 4.3 stable clean import and test run
- **Commands:**
  - `godot --headless --import`
  - `godot --headless --path . res://tests/test_runner.tscn`

Coverage includes production resource/scene loading, all required player mappings,
player/melee/Boss active frames, Archer release timing, hurt/death overrides,
Boss victory deferral, no post-death release, and debug-overlay defaults.
The M2 integration additionally boots the real `App`, starts a run, and checks
the live player, wave enemies, Boss, HUD, and combat feedback resolve to V3.

See `docs/RUNTIME_ART_SOURCE_AUDIT.md` for the runtime dependency trace and the
exact branch-divergence cause of the Art V2 regression.

Runtime evidence from the real App path is stored in
`docs/screenshots/runtime_market_v3.png`, `runtime_combat_v3.png`, and
`runtime_boss_v3.png`. Godot 4.3 rendered the Ghost Market, V3 player and melee
enemy with the current HUD, and the V3 Gate Warden at 640×360.

## Known limitations and next work

1. Only actions already present in gameplay are mapped. Player light attack 2,
   heavy attack, and Gate Warden attack 2 remain unused.
2. Corpse Beast art remains reserved for X03.
3. The Ghost Arrow polygon remains hidden as an emergency load-failure fallback.
4. Combat has no audio; audio integration remains outside M1.5 scope.
5. X04 now has a second supplied attack strip, but still depends on the Boss
   `PhaseController` / `AttackScheduler` foundation and an approved move design.
6. Meta progression is one currency and one upgrade. No upgrade tree, no meta
   unlocks touching the sacrifice pool or enemy roster, no multiple profiles.
7. **Engine version drift.** `project.godot` declares `4.3`, `godot-tests` pins
   `4.3-stable`, but the committed `assets_v2/**.import` files carry Godot 4.4+
   keys (`compress/uastc_level`, `process/channel_remap/*`) and the M1.5 handoff
   reports local work on 4.7.1. Opening the project on 4.3 rewrites those files.
   They were reverted rather than committed on this branch. The team should pick
   one engine version and align `project.godot`, CI and local tooling.

## Frozen interfaces

See `docs/INTERFACES.md` section 1. Changes require an ADR and Claude review.

`RunState` · `DamageContext` / `DamageResult` / `CombatResolver` ·
`IntegrityService` · `SacrificeDefinition` · `SacrificeService` · Damageable ·
`EnemyBase` · `EventBus` · `RNGService` · `RunCoordinator` · `Hitbox` / `Hurtbox`
