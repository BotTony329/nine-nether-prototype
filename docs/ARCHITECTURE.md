# Architecture

> **STATUS: ACTIVE — M1 (playable vertical slice foundation)**
> **Owner:** Claude · **Branch:** `claude/core-framework` · **Engine:** Godot 4.3 stable / GDScript

This document describes what the code actually does. It does not define product
rules; those come from `docs/PRD.md` and `docs/PROTOTYPE_CONTRACT.md`.

---

## 1. Priorities

From the Prototype Development Pack (A1): **runnable > testable > configurable >
extensible > elegant**. The architecture serves the current scope and does not
pre-build for systems that do not exist yet.

Three rules shape almost every decision below:

1. **One source of truth per calculation.** Damage is resolved in exactly one
   place. Integrity is computed in exactly one place. The sacrifice preview and
   the sacrifice apply are the same function.
2. **Structural and momentary state are different things.** Max HP is
   structural; current HP is momentary. Confusing them is the bug the research
   report was written to fix.
3. **UI observes, services mutate.** The HUD, the sacrifice card and the debug
   panel all read state and call the coordinator. None of them writes a stat.

---

## 2. Directory layout

Follows Prototype Development Pack A3, plus `scenes/` (see ADR-009).

| Path | Contents | Owner |
| --- | --- | --- |
| `core/` | EventBus, RNGService, GameData, RunState, BalanceConfig, damage pipeline, SoftCaps, DerivedStats, Hitbox/Hurtbox | Claude |
| `systems/` | IntegrityService, sacrifice definition/result/service, RunCoordinator | Claude |
| `actors/player/` | Player, state machine, action states, SpriteFrames | Claude |
| `actors/enemies/` | EnemyBase contract and scene, EnemyConfig schema, concrete enemies | Claude (base) / Codex (concrete) |
| `actors/boss/` | BossActor and scene | Codex + Claude review |
| `scenes/` | `main.tscn` (composition root), `arena.tscn` | Claude |
| `ui/` | HUD, sacrifice panel, result screen, debug panel, shape overlay | Codex |
| `data/` | `balance_config.tres`, `sacrifices/*.tres`, `actors/*.tres` | Shared, validated by tests |
| `tests/` | Harness and cases | Codex primary |
| `tools/` | Generators and asset utilities | Shared |

---

## 3. Scene tree

`scenes/app.tscn` is the main scene and the composition root outside a run. It
owns the meta profile and keeps exactly one child scene in the tree — the market
or a run, never both. See `docs/GHOST_MARKET_LOOP.md`.

```
App (Node, scenes/app.gd)              ← owns MetaState + MetaSave
└── GhostMarket (scenes/ghost_market.tscn)   ← or Main, never both
```

`scenes/main.tscn` is one run, and matches Prototype Development Pack A4:

```
Main (Node2D, scenes/main.gd)          ← composition root
├── Arena (scenes/arena.tscn)          ← terrain, parallax, props, spawn markers, camera bounds
├── Actors (Node2D)                    ← player, wave enemies and boss are spawned here
├── RunCoordinator (systems/run_coordinator.gd)
├── UIRoot
│   ├── Hud
│   ├── SacrificePanel
│   └── ResultScreen
└── DebugRoot
    ├── DebugPanel
    └── DebugShapes (DebugShapeOverlay)
```

`Main._ready()` binds every observer before the run starts. Starting the run
from the coordinator's own `_ready` would let observers bind after the opening
`state_ready` had already fired. `App` sets `autostart = false` and calls
`start_run` itself once it has bound too; with `autostart` left on, `main.tscn`
plays standalone in the editor with no meta layer.

Actor scenes:

- `actors/player/player.tscn` — CharacterBody2D + AnimatedSprite2D + body
  collider + Hurtbox + AttackHitbox + Camera2D.
- `actors/enemies/enemy_base.tscn` — the 48×48 humanoid base; `ghost_melee.tscn`
  inherits it and supplies SpriteFrames only.
- `actors/boss/boss.tscn` — standalone because the Boss is 96×96 and needs its
  own collider sizes; it runs `BossActor`, which extends `EnemyBase`.

No core calculation lives in `Main`, in `Arena` or in any UI node.

---

## 4. State ownership

| State | Owner | Lifetime |
| --- | --- | --- |
| Balance configuration | `GameData` (autoload) | Process |
| Sacrifice library | `GameData` (autoload) | Process |
| RNG streams | `RNGService` (autoload) | Re-seeded per run |
| Active `RunState` | `RunCoordinator` | One run |
| `MetaState` (soul ash, counters, upgrade) | `App` | Process, persisted to `user://meta_save.json` |
| Latest `RunResult` | `App` | Until the next run ends |
| Enemy and Boss HP | The actor instance | One actor |
| Everything the UI shows | Nobody — it is read each frame | — |

`GameData` holds the stateless services (`CombatResolver`, `SacrificeService`)
and the loaded data. It deliberately does **not** hold the active `RunState`:
keeping mutable run data out of an autoload is what stops "just read it from the
global" becoming the way every script talks to the run.

### RunState

Fields are private. Reads go through getters; writes go through named commands
(`apply_damage`, `heal`, `scale_max_hp`, `add_additive`, `add_imbalance`, …).
Structural commands all end in `recalculate_derived()`, which is the single
place integrity, effective HP and the DPS estimate are produced.

`snapshot()` / `restore()` / `clone()` / `snapshot_hash()` support preview,
rollback, telemetry correlation and test assertions.

**Structural** (feeds integrity): max HP, max stamina, armour, stamina recovery,
structural locks, action taxes.
**Momentary** (never feeds integrity): current HP, current stamina.

---

## 5. Combat

`CombatResolver.resolve(DamageContext) -> DamageResult` is the only damage path,
implementing research report 5.3:

```
raw   = ATK × SkillMult × (1 + AddSum) × MoreProd × CondProd × CritMult
final = raw × 100 / (100 + max(0, ARM − Pen)) × Vulnerability
```

- `DamageContext` carries every input, so the resolver never reaches into a
  scene node or an autoload for a gameplay value.
- `DamageResult.breakdown` records each stage, so a wrong number can be traced
  to the bucket that produced it. A test multiplies the breakdown back to the
  final damage.
- The crit roll is injectable (`CombatResolver._roll_provider`) and a context can
  pin it (`crit_roll`) or force it (`force_crit`), which is what makes crit
  behaviour testable rather than a coin flip.
- Soft caps live in `SoftCaps` and are shared with `DerivedStats`, so the HUD's
  DPS estimate and an actual hit compress the same way.

**Damageable shape.** `Player` and `EnemyBase` both expose
`actor_id() / armour() / current_hp() / receive_damage(DamageContext)`. An
attacker can therefore hit either side without special-casing, and neither side
computes its own damage.

---

## 6. Integrity

`IntegrityService.compute(structural, balance)` — research report 5.4:

```
I = clamp(0.34h + 0.24s + 0.16a + 0.14r + 0.12f, 0, 1)
h = min(1, HPmax/100)                    s = min(1, STmax/100)
a = min(1, (1+ARM/100)/(1+ARM0/100))     r = min(1, SR/12)
f = max(0, 1 − 0.12·majorLocks − 0.06·actionTaxes)
```

The service takes primitives rather than a `RunState`, which keeps it pure and
avoids a class-level cycle. Each component is capped at 1 so an ordinary buff
cannot push integrity above the intact-body ceiling or launder away a sacrifice.

---

## 7. Sacrifice transaction

`SacrificeService` runs one ordered transaction (Prototype Development Pack A9):

1. validate (`can_offer`)
2. snapshot — the rollback point
3. apply cost
4. recalculate integrity (each structural command does this)
5. apply reward, priced against post-cost integrity
6. recalculate derived values
7. apply imbalance
8. publish the event
9. return `SacrificeResult`

`preview(state, def)` runs it on `state.clone()`. `apply(state, def)` runs it on
the real state. **Same function.** A preview therefore cannot disagree with the
result — there is a test asserting field-by-field equality.

Reward curve (5.5): `D = (1 − I)^1.35`, `G = g_S × (0.55 + 1.45·D) × Q`, with
`Q = clamp(1 + 0.12·synergy − 0.08·dilution, 0.85, 1.45)`. Pricing the reward
*after* the cost is what makes a more broken body buy a sharper blade.

Cost score (5.6): `C = 100Δh + 80Δs + 60Δa + 50Δr` over integrity component
drops. Imbalance uses the card's authored `imbalance_flat` when set, otherwise
`ΔB = C × (0.75 + 0.05·S)` — see ADR-005.

**Invariant:** a sacrifice may never raise integrity. If a card's data would do
so, the transaction fails and the state is restored whole (ADR-008).

---

## 8. Events and randomness

`EventBus` (autoload) carries `run_started`, `run_restarted`, `hit_dealt`,
`hit_taken`, `enemy_died`, `player_died`, `sacrifice_previewed`,
`sacrifice_applied`, `boss_started`, `boss_died`, `run_completed`. Every payload
is wrapped by `EventBus.context()` so telemetry can correlate without each
emitter inventing a shape.

Events are for UI, telemetry and decoupled reactions **only**. Deterministic
core resolution uses explicit service calls. Moving a calculation onto a signal
is a defect.

`RNGService` (autoload) gives each subsystem its own stream, seeded from the run
seed via FNV-1a over the stream name. An extra roll in one system therefore
cannot shift the sequence another system observes; there is a test for that.
Gameplay must never call `randi()`/`randf()` directly.

---

## 9. Player state machine

States: `Grounded`, `Airborne`, `Attacking`, `Hurt`, `Dead` — one small class
each under `actors/player/states/`. A state changes the player through helpers
on `Player` and requests a transition by returning the next state id; every
transition runs through `PlayerStateMachine._change_to`, so exit/enter cannot be
skipped and there is one place to look when a state sticks.

Documented extension points, deliberately not stubbed:

- **Dodge** — three phases with i-frames; entered from Grounded/Airborne, gated
  on a StaminaService that does not exist yet.
- **Exhausted** — entered from anywhere at zero stamina; blocks dodge, skill and
  heavy attack while leaving light attack available.
- **SameDeath** — must be checked at the top of `on_death`, before `DEAD`, since
  it is a lethal-damage interception rather than a state you walk into.

---

## 10. Pixel art rendering configuration

| Setting | Value | Reason |
| --- | --- | --- |
| Viewport | 640 × 360 | 48px player ≈ 13% of screen height; the 320×180 backdrop tiles cleanly |
| Window | 1280 × 720 | Exactly 2× the viewport |
| `stretch/mode` | `viewport` | Renders at the low resolution and upscales the whole frame |
| `stretch/scale_mode` | `integer` | No fractional scaling, so no shimmer at any window size |
| `default_texture_filter` | 0 (Nearest) | No smoothing on any canvas texture |
| `snap_2d_transforms_to_pixel` | true | Sprites land on whole pixels |
| `snap_2d_vertices_to_pixel` | true | No sub-pixel seams between tiles |
| `msaa_2d` | 0 | Anti-aliasing would soften pixel edges |
| Renderer | `gl_compatibility` | As recommended in `godot/import_presets.md` |
| Texture import | lossless, no mipmaps, `detect_3d/compress_to = 0` | Matches `docs/art/GODOT_IMPORT_GUIDE.md` |

This deviates from the 1280×720 viewport suggested in `godot/import_presets.md`
— see ADR-002. No asset is scaled by a non-integer factor and no sprite
dimensions were changed.

`SpriteFrames` resources are generated by `tools/generate_sprite_frames.py` from
the frame table in `docs/ART_SPEC.md`; the generator fails if a sheet's real
dimensions disagree with the table (ADR-004).

---

## 11. Known architectural gaps

Listed so nobody mistakes absence for oversight. Each is scoped to a later task.

- No StaminaService: stamina regenerates and is displayed, but nothing spends it
  (light attack costs 0 by design). Dodge and heavy attack are its first
  consumers.
- No world director: imbalance is tracked but does not yet drive enemy pressure.
- No same-death controller.
- No three-slot sacrifice generator: M1 offers one card at a fixed point.
- No Boss phase controller or attack scheduler.
- No telemetry persistence: events are emitted but nothing writes them to disk.
- Meta progression is one upgrade and one currency (M2). No upgrade tree, no
  meta unlocks touching the sacrifice pool or the enemy roster.
