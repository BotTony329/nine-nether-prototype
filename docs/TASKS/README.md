# Task Register

Update status and PR only when work actually begins.

## Milestone M1.5 — Art V2 integration

| ID | Task | Owner | Status | Branch | Dependency | PR |
| --- | --- | --- | --- | --- | --- | --- |
| M15 | V2 character, enemy, Boss, projectile, effect, and HUD integration | Codex | In review | `codex/m15-art-v2-integration` | M1 + X02 | #6 |

M1.5 maps only existing gameplay actions. It does not add player attacks, Boss
phases, or a parallel combat/animation framework. See
`docs/ART_V2_INTEGRATION_REPORT.md` for the complete integration matrix.

## Milestone M1 — playable vertical slice foundation

All Claude tasks are delivered on `claude/core-framework` in one PR to
`develop`. The interfaces they release are frozen in `docs/INTERFACES.md`.

| ID | Task | Owner | Status | Branch | Dependency | PR |
| --- | --- | --- | --- | --- | --- | --- |
| C01 | Repository and document review, Godot project skeleton | Claude | Done | `claude/core-framework` | Repository setup | M1 PR |
| C02 | RunState, EventBus, RNGService, BalanceConfig | Claude | Done | `claude/core-framework` | C01 | M1 PR |
| C03 | CombatResolver and IntegrityService | Claude | Done | `claude/core-framework` | C02 | M1 PR |
| C04 | Sacrifice transaction and example card | Claude | Done | `claude/core-framework` | C03 | M1 PR |
| C05 | Player controller, state machine, art integration, arena | Claude | Done | `claude/core-framework` | C03 | M1 PR |
| C06 | EnemyBase, reference enemy, Boss foundation | Claude | Done | `claude/core-framework` | C04 | M1 PR |
| C07 | Run flow, HUD, sacrifice panel, result screen, debug tools | Claude | Done | `claude/core-framework` | C05, C06 | M1 PR |
| C08 | Test harness, test suite, `godot-tests` workflow | Claude | Done | `claude/core-framework` | C07 | M1 PR |
| C09 | Architecture, interfaces, decisions, testing and handoff docs | Claude | Done | `claude/core-framework` | C08 | M1 PR |

## Codex module tasks

Unblocked once the M1 PR merges into `develop`. Each takes one branch and one PR,
stays inside `docs/INTERFACES.md` section 4, and must not touch the protected
files in section 3.

| ID | Task | Owner | Status | Branch | Dependency | PR |
| --- | --- | --- | --- | --- | --- | --- |
| X01 | Melee ghost — full behaviour | Codex | Ready | `codex/x01-melee-ghost` | `EnemyBase` frozen | — |
| X02 | Ghost Archer — projectile, spacing, reposition | Codex | Done | `codex/x02-ghost-archer` | `EnemyBase` frozen | #4 |
| X03 | Charger ghost — telegraphed line charge, wall stagger | Codex | Ready | `codex/x03-charger-ghost` | `EnemyBase` frozen | — |
| X04 | Boss attack pack — three moves | Codex | Blocked on framework/design | `codex/x04-boss-attacks` | `PhaseController`, `AttackScheduler` | — |
| X05 | Sacrifice selection UI — A/B/C slots | Codex | Ready | `codex/x05-sacrifice-ui` | `SacrificeService` frozen | — |
| X06 | Twelve sacrifice definitions | Codex | Ready | `codex/x06-sacrifice-data` | `SacrificeDefinition` frozen | — |
| X07 | Debug and telemetry panel — timeline, JSON/CSV export | Codex | Ready | `codex/x07-debug-panel` | `EventBus` frozen | — |
| X08 | Automated test expansion | Codex | Partly blocked | `codex/x08-test-expansion` | Stamina and same-death systems | — |

**X04 art is now available** in the V2 Gate Warden pack, including attack 2.
The task remains blocked until Claude supplies the Boss `PhaseController` /
`AttackScheduler` foundation and the Game Director approves the move set. M1.5
uses attack 1 only because that is the only existing gameplay action.

**X08 is partly blocked**: the combat, integrity, sacrifice, actor, RNG and
run-loop cases exist. The stamina/dodge and same-death cases the Development
Pack asks for cannot be written until those systems do.

## Framework work still owned by Claude

Not yet scheduled; each unblocks further Codex tasks.

| Task | Unblocks |
| --- | --- |
| Three-slot sacrifice generator (A/B/C roles, weighting, pity) | X05 at full scope |
| `StaminaService` — costs, recovery delay, exhaustion lock, consecutive dodge | Dodge, heavy attack, X08 |
| `SameDeathController` — lethal-damage priority chain and the 0.65 s window | X08 |
| World director — imbalance and build-threat driving enemy pressure | Elite affixes, tag counters |
| Boss `PhaseController` and `AttackScheduler` | X04 at full scope |
