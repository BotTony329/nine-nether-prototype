# Interfaces

> **STATUS: ACTIVE — first interface freeze (M1)**
> **Owner:** Claude · **Frozen on:** `claude/core-framework`

Everything in section 1 is **frozen**. Codex may call it, extend it at the
documented points, and read it — but not change a signature, a field name or an
ordering guarantee without opening a proposal in `docs/DECISIONS.md` and waiting
for Claude review, per `AGENTS.md`.

Section 3 lists the files Codex must not modify at all. Section 4 lists the
extension points that are open for work right now.

---

## 1. Frozen contracts

### 1.1 `RunState` — `core/run_state.gd`

Authoritative run-level player state.

```gdscript
static func create(balance: BalanceConfig, run_seed: int) -> RunState

# reads
func max_hp() -> float                      func current_hp() -> float
func max_stamina() -> float                 func current_stamina() -> float
func armour() -> float                      func stamina_recovery() -> float
func attack() -> float                      func additive_sum() -> float
func more_product() -> float                func crit_rate() -> float
func crit_damage() -> float                 func attack_speed() -> float
func structural_locks() -> Array[StringName]
func action_taxes() -> Array[StringName]
func integrity() -> float                   func imbalance() -> float
func effective_hp() -> float                func dps_estimate() -> float
func sacrifice_history() -> Array[StringName]
func build_tags() -> Dictionary             func tag_count(tag) -> int
func run_seed() -> int                      func run_status() -> StringName
func hp_ratio() -> float                    func stamina_ratio() -> float
func is_alive() -> bool                     func is_guttering() -> bool
func structural_snapshot() -> Dictionary    func offence_snapshot() -> Dictionary

# momentary commands
func apply_damage(amount: float) -> float   func heal(amount: float) -> float
func set_current_hp(value: float) -> void
func spend_stamina(amount: float) -> void
func regenerate_stamina(amount: float) -> void
func set_run_status(status: StringName) -> void

# structural commands (each ends in recalculate_derived)
func scale_max_hp(factor: float) -> void
func scale_max_stamina(factor: float) -> void
func set_armour(value: float) -> void
func set_stamina_recovery(value: float) -> void
func add_additive(value: float) -> void     func multiply_more(factor: float) -> void
func add_crit_rate(value: float) -> void    func add_crit_damage(value: float) -> void
func multiply_attack_speed(factor: float) -> void
func add_structural_lock(lock_id: StringName) -> void
func add_action_tax(tax_id: StringName) -> void
func add_imbalance(value: float) -> void
func record_sacrifice(id: StringName, tags: Array[StringName]) -> void
func recalculate_derived() -> void

# snapshots
func snapshot() -> Dictionary               func restore(snap: Dictionary) -> void
func clone() -> RunState                    func snapshot_hash() -> String
```

**Invariants.**

- Fields are private. There is no path to a stat that is not a command above.
- Current HP and current stamina never affect integrity.
- Healing never restores structure.
- Structural stats are clamped to the `BalanceConfig` floors.
- Derived values are produced only by `recalculate_derived()`.
- `clone()` shares the `BalanceConfig` and nothing else.

**UI rule.** UI code may call reads only. Mutations go through
`RunCoordinator`.

### 1.2 Damage pipeline — `core/damage_context.gd`, `core/damage_result.gd`, `core/combat_resolver.gd`

```gdscript
CombatResolver.new(balance: BalanceConfig, roll_provider := Callable())
func resolve(ctx: DamageContext) -> DamageResult
func player_attack_context(state, target_id, target_armour, target_current_hp,
                           skill_multiplier) -> DamageContext
```

`DamageContext` inputs: `source_id`, `target_id`, `base_damage`,
`skill_multiplier`, `additive_modifiers`, `more_modifiers`,
`conditional_modifiers`, `crit_allowed`, `crit_rate`, `crit_damage`,
`crit_roll`, `force_crit`, `target_armour`, `armour_penetration`,
`vulnerability`, `target_current_hp`, `tags`, `metadata`.

`DamageResult` outputs: `raw_damage`, `final_damage`, `is_critical`,
`mitigation`, `is_lethal`, `breakdown`, plus `to_dictionary()`.

**Ordering guarantee (frozen).** base → additive → more → conditional → crit →
armour/vulnerability. A new effect joins an existing bucket; it does not add a
stage.

**Rule.** There is one damage path. Player, Enemy, Boss, HUD and the sacrifice
preview all call `resolve`. Re-deriving damage anywhere else is a defect.

### 1.3 `IntegrityService` — `systems/integrity_service.gd`

```gdscript
static func compute(structural: Dictionary, balance: BalanceConfig) -> float
static func components_of(structural: Dictionary, balance: BalanceConfig) -> Dictionary
```

`structural` comes from `RunState.structural_snapshot()`. `components_of`
returns `{h, s, a, r, f}`, each in `[0, 1]`.

### 1.4 `SacrificeDefinition` — `systems/sacrifice_definition.gd`

Resource schema; content lives in `res://data/sacrifices/*.tres`.

| Group | Fields |
| --- | --- |
| Identity | `id`, `display_name`, `strength` (1–5), `rarity` |
| Classification | `tags`, `roles`, `exclusive_group` |
| Generation | `base_weight`, `prerequisite_min_sacrifices`, `banned_with` |
| Costs | `cost_max_hp_multiplier`, `cost_max_stamina_multiplier`, `cost_armour_multiplier`, `cost_stamina_recovery_multiplier`, `cost_structural_locks`, `cost_action_taxes`, `imbalance_flat` |
| Rewards | `reward_additive`, `reward_generic_more`, `reward_crit_rate`, `reward_crit_damage`, `reward_attack_speed_multiplier` |
| Triggers | `triggers` (declarative; nothing consumes them yet) |
| Display | `short_text`, `preview_template`, `warning_level` |

`roles` must contain one or more of `CONTINUATION`, `RISK_ESCALATION`,
`PIVOT_STABILIZE`. `validate() -> Array[String]` returns data problems; the test
suite fails on any non-empty result for a shipped card.

**Adding cards (X06) requires no code change.** Adding a *new kind of cost or
reward* does, and that is an interface change.

### 1.5 `SacrificeService` — `systems/sacrifice_service.gd`

```gdscript
SacrificeService.new(balance: BalanceConfig)
func can_offer(state: RunState, definition) -> Dictionary    # {ok: bool, reason: String}
func preview(state: RunState, definition) -> SacrificeResult # runs on a clone
func apply(state: RunState, definition) -> SacrificeResult   # runs on the real state
```

`SacrificeResult`: `ok`, `definition_id`, `failure_reason`, `before`, `after`,
`deltas`, `gain`, `cost_score`, `imbalance_delta`, `warnings`, plus
`matches(other)` and `to_dictionary()`.

**Frozen guarantees.**

- `preview` and `apply` execute the identical transaction function.
- `preview` leaves the passed state byte-identical.
- Transaction order is validate → snapshot → cost → integrity → reward →
  derived → imbalance → publish → return.
- Any failure restores the pre-transaction snapshot whole.
- A sacrifice may never raise integrity.

### 1.6 Damageable shape — `Player` and `EnemyBase`

```gdscript
func actor_id() -> StringName
func armour() -> float
func current_hp() -> float
func receive_damage(context: DamageContext) -> DamageResult
```

Any new damageable actor implements all four. An attacker builds a
`DamageContext` and calls `receive_damage`; it never applies damage itself.

### 1.7 `EnemyBase` — `actors/enemies/enemy_base.gd`

```gdscript
func initialize(enemy_config: EnemyConfig, target: Node2D) -> void
func acquire_target(target: Node2D) -> void
func change_state(next: int) -> void          # enum State
func receive_damage(context: DamageContext) -> DamageResult
func die(source_id: StringName = &"unknown") -> void
signal died(enemy: EnemyBase)
enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, DEAD }
```

**Frozen guarantees.**

- `die` is idempotent: one death event however many lethal hits land.
- A dead enemy takes no further damage and runs no behaviour.
- Every transition goes through `change_state`.
- Enemies never touch RunState structure or the sacrifice system.

`EnemyConfig` (`actors/enemies/enemy_config.gd`) is the stat and timing schema;
instances live in `res://data/actors/`.

### 1.8 `EventBus` — `core/event_bus.gd`

Signals: `run_started`, `run_restarted`, `hit_dealt`, `hit_taken`,
`enemy_died`, `player_died`, `sacrifice_previewed`, `sacrifice_applied`,
`boss_started`, `boss_died`, `run_completed`. Each carries a `Dictionary` built
by `EventBus.context(extra)` containing `timestamp`, `run_id`, `stage_id` plus
the emitter's own fields.

**Rule.** Observation and telemetry only. Never a calculation.

### 1.9 `RNGService` — `core/rng_service.gd`

```gdscript
func configure(new_seed: int) -> void
func run_seed() -> int
func stream(stream_name: StringName) -> RandomNumberGenerator
func randf(stream_name: StringName) -> float
func randi_range(stream_name: StringName, from: int, to: int) -> int
const STREAM_SACRIFICE, STREAM_COMBAT, STREAM_SPAWN
```

**Rule.** No gameplay code calls `randi()`/`randf()` directly. Add a new stream
constant rather than reusing an unrelated one.

### 1.10 `RunCoordinator` — `systems/run_coordinator.gd`

```gdscript
signal phase_changed(phase: StringName)     signal state_ready(state: RunState)
signal sacrifice_offered(definition)        signal boss_spawned(boss: BossActor)
signal run_finished(outcome: StringName)

func start_run(run_seed: int, restarted := false) -> void
func restart_run(reuse_seed := true) -> void
func confirm_sacrifice(definition) -> SacrificeResult
func begin_boss() -> void
func state() -> RunState                    func player() -> Player
func boss() -> BossActor                    func phase() -> StringName
func live_enemies() -> Array[EnemyBase]     func offered_sacrifice() -> SacrificeDefinition
func spawn_enemy_at(position: Vector2) -> EnemyBase

# debug commands — the only route from a debug UI to the run
func debug_heal(amount: float) -> void      func debug_damage(amount: float) -> void
func debug_spawn_reference_enemy() -> void
func debug_preview_sacrifice() -> SacrificeResult
func debug_apply_sacrifice() -> SacrificeResult
```

Phases: `boot`, `wave`, `sacrifice`, `boss`, `result`.

### 1.11 `Hitbox` / `Hurtbox` — `core/hitbox.gd`, `core/hurtbox.gd`

`Hitbox.set_active(bool)` opens and closes the damage window and emits
`hit_actor(actor)` at most once per actor per window. `Hurtbox.actor()` returns
the damageable that owns it. Neither knows anything about damage numbers.

Physics layers: `world`(1) `player_body`(2) `enemy_body`(3) `player_hurtbox`(4)
`enemy_hurtbox`(5) `player_hitbox`(6) `enemy_hitbox`(7).

---

## 2. Data contracts

`BalanceConfig` (`core/balance_config.gd`, instance
`res://data/balance_config.tres`) holds every tunable number. Adding a field is
additive and safe. **Hardcoding a balance value in a script is a review
failure.**

---

## 3. Files Codex must not modify

Without a `docs/DECISIONS.md` proposal and Claude review:

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

Freely editable: `data/**`, `ui/**`, `tests/**`, concrete enemy scenes such as
`actors/enemies/ghost_*.tscn`, attack content in `actors/boss/boss_actor.gd`,
**new** files under `actors/player/states/`, and `tools/**`.

---

## 4. Open extension points

| Point | Where | What to do |
| --- | --- | --- |
| New enemy archetype | `actors/enemies/` + `data/actors/` | New scene inheriting `enemy_base.tscn`, new `EnemyConfig` .tres, add behaviour states — do not edit `EnemyBase` |
| Boss moves | `actors/boss/boss_actor.gd` | Add an attack scheduler over config-driven definitions; do not add a second damage path |
| Sacrifice cards | `data/sacrifices/*.tres` | Data only; `validate()` must pass |
| Three-slot generator | new file in `systems/` | Use `RNGService.STREAM_SACRIFICE`; call `can_offer`/`preview`; never re-implement scoring inside the UI |
| Player states | `actors/player/states/` | Add a file, register the id in `PlayerStateMachine._init`, give an existing state a reason to return it |
| Stamina consumers | `Player.spend_stamina` | Already routed through `RunState`; a StaminaService can wrap it without changing callers |
| Telemetry sink | subscribe to `EventBus` | Payloads already carry the correlation envelope |
