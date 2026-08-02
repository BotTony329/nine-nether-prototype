# AI Handoff

- **Current branch:** `codex/x02-ghost-archer`
- **Current phase:** X02 Ghost Archer implemented on the M1 foundation; PR #4 open
- **Next owner:** Claude and Game Director for X02 review
- **Last updated:** 2026-08-02 (Australia/Melbourne)

---

## M1 playable status

**Playable end to end.** Launch → arena → move, jump, attack → clear a wave of
three ghost soldiers → preview and accept one sacrifice → become measurably
sharper and structurally weaker → fight the prototype Boss → victory or death →
restart.

Verified by the automated run-loop case and by capturing frames under a virtual
display during development. Engine: Godot 4.3 stable.

## Implemented systems

| System | State |
| --- | --- |
| `RunState` | Authoritative; private fields, named commands, snapshot/restore/clone/hash |
| `CombatResolver` | Single damage path, bucket order frozen, breakdown reported |
| `IntegrityService` | Five-component structural formula; momentary state excluded |
| `SacrificeService` | Shared preview/apply transaction with whole-state rollback |
| `EventBus` | 11 signals with a uniform correlation envelope |
| `RNGService` | Per-subsystem streams derived from the run seed |
| `BalanceConfig` | Every tunable number, in `data/balance_config.tres` |
| Player | Move, jump, light attack, hit reaction, death, restart, camera follow, 5-state machine |
| `EnemyBase` | Detect, approach, telegraphed wind-up, attack, recovery, hurt, idempotent death |
| Reference enemy | 鬼卒 Ghost Soldier at X01 timings |
| Ghost Archer (X02) | Patrol, detect, maintain range, retreat, aim, shoot, cooldown, hurt and death |
| Ghost Arrow (X02) | Fixed trajectory, one hit, owner exclusion, impact/timeout cleanup, CombatResolver path |
| `BossActor` | Extends `EnemyBase`; idle, chase, one telegraphed melee attack, health bar, victory |
| Arena | One fixed 1024×360 space, collision, spawns, parallax, camera bounds |
| UI | HUD, sacrifice preview/confirm, death and victory screens, restart |
| Debug | Panel plus 9 commands, all routed through `RunCoordinator` |
| Tests + CI | 52 tests / 205 assertions; `godot-tests` workflow |

## Frozen interfaces

See `docs/INTERFACES.md` section 1 for signatures and guarantees.

`RunState` · `DamageContext` / `DamageResult` / `CombatResolver` ·
`IntegrityService` · `SacrificeDefinition` · `SacrificeService` ·
the Damageable shape (`actor_id` / `armour` / `current_hp` / `receive_damage`) ·
`EnemyBase` · `EventBus` · `RNGService` · `RunCoordinator` · `Hitbox` / `Hurtbox`

Changing any of them requires a `docs/DECISIONS.md` proposal and Claude review.

## Files Codex must not modify

```
core/run_state.gd               core/combat_resolver.gd
core/damage_context.gd          core/damage_result.gd
core/soft_caps.gd               core/derived_stats.gd
core/event_bus.gd               core/rng_service.gd
core/game_data.gd               core/hitbox.gd             core/hurtbox.gd
systems/integrity_service.gd    systems/sacrifice_service.gd
systems/sacrifice_definition.gd systems/sacrifice_result.gd
systems/run_coordinator.gd
actors/enemies/enemy_base.gd    actors/enemies/enemy_base.tscn
actors/enemies/enemy_config.gd
actors/player/player.gd         actors/player/player_state_machine.gd
actors/player/states/player_state.gd
scenes/main.gd                  project.godot
.github/workflows/repository-validation.yml
```

Also unchanged without their owner: product requirements (Game Director) and
`docs/art/CONCEPT_*.md` (Art Director).

## Available Codex tasks

All interfaces these depend on are now frozen. See `docs/TASKS/README.md`.

| ID | Task | Depends on | Notes |
| --- | --- | --- | --- |
| X01 | Melee ghost, full behaviour | `EnemyBase` | The reference enemy is a starting point, not the finished X01 |
| X02 | Ghost Archer | `EnemyBase` | **Done on `codex/x02-ghost-archer`; pending review** |
| X03 | Charger ghost | `EnemyBase` | Art present: `corpse_beast_*` at 64×48 — needs its own collider sizes |
| X04 | Boss attack pack | `BossActor` | Blocked on art or a ruling — see gaps below |
| X05 | Sacrifice selection UI | `SacrificeService` | Three A/B/C slots; preview through the service, confirm through the coordinator |
| X06 | Twelve sacrifice definitions | `SacrificeDefinition` | Data only. S4/S5 cards need at least one rule-type cost |
| X07 | Debug and telemetry panel | `EventBus`, `RunCoordinator` | Event timeline and JSON/CSV export; the current panel is the baseline |
| X08 | Test expansion | harness | Stamina/dodge and same-death cases once those systems exist |

Not yet unblocked, because Claude has not built the framework they extend: the
three-slot generator, `StaminaService`, `SameDeathController`, the world
director, and the Boss `PhaseController`.

## Known issues

1. **`assets/effects/*.png` are single-frame.** All four are 48×48 while
   `assets/effects/metadata.md` specifies 2–4 frames (96×48 to 192×48). No VFX
   are used in M1. WorkBuddy needs to re-export the strips.
2. **The Boss has one attack.** `assets/boss/` ships one attack sheet, so the
   charge and the ground slam from A14/X04 are absent (ADR-010). The fight is a
   readable pattern with one answer — thin on purpose, not by oversight.
3. **`docs/PRD.md` and `docs/PROTOTYPE_CONTRACT.md` are still stubs.** M1 was
   derived from the Development Pack and research report under ADR-001. Land the
   real documents before Codex starts, so X01–X08 have something to be reviewed
   against.
4. **Stamina has no consumer** (ADR-011). The bar sits full during normal play.
5. **Imbalance is tracked but inert.** Nothing reads it yet; the world director
   is the consumer.
6. **No telemetry persistence.** Events are emitted with a correlation envelope
   but nothing writes them to disk (X07).
7. **No audio.** Out of scope for M1.
8. **Placeholder art everywhere.** Magenta border = placeholder, per
   `docs/ART_SPEC.md` section 5.
9. **The Ghost Arrow has no supplied sprite.** X02 uses a small procedural
   polygon fallback in `ghost_arrow.tscn`; replace only the `FallbackVisual`
   when approved projectile art arrives. Collision and behaviour are final.

## Test status

- **Last successful run:** 2026-08-02 — 59 tests, 229 assertions, 0 failures,
  Godot 4.7.1 stable headless locally. Existing CI remains pinned to Godot 4.3.
- **Command:** `godot --headless --import` then
  `godot --headless --path . res://tests/test_runner.tscn`
- **CI:** `repository-validation` (unchanged) and `godot-tests` (new). Both
  should be required checks on `develop`.

## Asset integration gaps

| Asset group | Status |
| --- | --- |
| `assets/player/` | All 6 sheets used; dimensions match `docs/ART_SPEC.md` exactly |
| `assets/enemy/ghost_melee_*` | All 5 sheets used |
| `assets/enemy/ghost_archer_*` | All 5 sheets used by X02 |
| `assets/enemy/corpse_beast_*` | Verified, unused — X03 |
| `assets/boss/` | idle, run, attack, hurt, death used; only one attack sheet exists |
| `assets/tiles/` | floor, stone_brick, brazier, tombstone used; `tile_wall`, `tile_wood_bridge`, `tile_ground_spike` unused (no platforms or hazards in M1) |
| `assets/background/` | bg_deep, bg_tree, bg_broken_flag, bg_chains all used in three parallax layers |
| `assets/ui/` | ui_health_bar, ui_stamina_bar used; `ui_frame`, `ui_minimap_frame` unused (no inventory, no minimap) |
| `assets/icons/ui/` | icon_hp, icon_boss, icon_sacrifice used; the other 8 unused |
| `assets/icons/weapons/` | All 6 unused — no weapon system in M1 |
| `assets/effects/` | **Unusable as animations** — see known issue 1 |

Nothing was stretched, scaled by a non-integer factor, or resized. Regenerate
`SpriteFrames` with `python3 tools/generate_sprite_frames.py` after replacing a
sheet; it aborts if the new dimensions disagree with the spec.

## X02 handoff

### Files added

- `actors/enemies/ghost_archer.gd`, `.tscn`, `_config.gd`, and `_frames.tres`
- `actors/enemies/ghost_arrow.gd` and `.tscn`
- `data/actors/ghost_archer.tres` and `ghost_archer_tactics.tres`
- `tests/cases/test_ghost_archer.gd`

### Integration and validation

- `scenes/main.tscn` injects the Ghost Archer through the existing
  `RunCoordinator.enemy_scene` / `enemy_config` extension seam. The wave and F4
  debug command therefore use the same coordinator-owned spawn path.
- Added tests for patrol/detection, retreat spacing, aim/shoot/cooldown, one-hit
  projectile resolution, armour integration, owner exclusion, timeout, damage,
  death, and no post-death behaviour.
- Commands run: SpriteFrames generator, headless import, full test scene, and a
  180-frame headless M1 main-scene smoke run.
- No frozen interface or protected framework file changed.
