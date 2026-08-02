# Testing

> **STATUS: ACTIVE — M1 harness in place**

Every task must add or update proportionate automated tests, run existing tests,
record commands and manual checks in its PR, and report the last successful
result in `docs/AI_HANDOFF.md`.

---

## Running the suite locally

Requires Godot **4.3 stable** on `PATH`.

```bash
godot --headless --import                          # generates .godot/ and the class registry
godot --headless --path . res://tests/test_runner.tscn
```

The runner exits `0` when everything passes and `1` on the first failure it
records, so it drops straight into CI or a pre-push hook. The import step is not
optional on a fresh clone: it builds the global class-name registry the test
scripts resolve `RunState`, `TestCase` and friends against.

Run it as a **scene**, not with `--script`. A MainLoop script is compiled before
the autoload singletons are registered, so any class naming `EventBus` or
`RNGService` fails to compile and every service silently becomes `null`. See
ADR-006.

## Continuous integration

Two workflows, both on pull requests into `develop` and `main`:

| Workflow | Checks |
| --- | --- |
| `repository-validation` | Required files present and non-empty, no committed secrets, no oversized files, YAML/JSON parse. Pre-existing; unchanged. |
| `godot-tests` | Downloads and caches Godot 4.3, imports the project, fails on any import error, then runs the suite. |

Both check names should be required in the branch ruleset for `develop`.

## Layout

```
tests/
├── test_runner.tscn / test_runner.gd   entry point and discovery
├── framework/test_case.gd              assertions, physics stepping, config helper
└── cases/
    ├── test_actors.gd          EnemyBase and BossActor
    ├── test_art_v2.gd          V2 loading, state mapping, frame timing, debug visibility
    ├── test_combat_resolver.gd damage pipeline
    ├── test_ghost_archer.gd    ranged AI, release timing, projectile and death
    ├── test_integrity.gd       structural integrity and snapshots
    ├── test_rng.gd             determinism and stream isolation
    ├── test_run_loop.gd        end-to-end run plus scene smoke checks
    └── test_sacrifice.gd       preview/apply transaction
```

Discovery is by convention: every `tests/cases/*.gd` extending `TestCase`, and
every method named `test_*`, on a fresh instance per method. Methods may `await`;
`step_physics(n)` advances real physics frames.

`make_balance()` returns a detached copy of `data/balance_config.tres` so a test
can retune a value without leaking it into the next test.

## What is covered

**Combat** — bucket order, armour as an equivalent-life model, penetration,
forced and pinned criticals, the crit-rate hard cap and the crit-damage and
more-product soft caps, lethality boundaries, and a check that the reported
breakdown multiplies back to the final damage.

**Integrity** — that current HP and current stamina do not move integrity while
max HP does (the arbitrage bug the research report was written to fix), the
intact-body ceiling, that a buff cannot offset a structural loss, structural
floors, exact snapshot round-tripping, and clone detachment.

**Sacrifice** — preview leaves the real state byte-identical; apply matches the
preview field by field; a rejected transaction rolls back whole; the shipped
card's numbers come from its `.tres`; the reward is priced against post-cost
integrity; a more broken body buys a bigger reward; duplicate, prerequisite and
lock-budget gating; and every shipped card passes `validate()`.

**Enemy and Boss** — the Damageable shape, damage through the resolver, death
firing exactly once across four routes (two lethal hits, a hit after death, and
two direct `die()` calls), a corpse taking no damage and running no behaviour,
target acquisition, that `BossActor` extends `EnemyBase`, authored melee/Boss
active-frame gating, and victory waiting for the Boss death strip.

**Art V2 and Ghost Archer** — required resources and critical scenes load,
player state-to-animation mappings, player startup/active/recovery gating,
hurt/death overrides, melee and Boss active frames, Archer patrol/range/aim/
release/cooldown/death, Ghost Arrow owner exclusion/one-hit/timeout behaviour,
and the debug overlay being off by default while remaining toggleable.

**RNG** — same seed replays, different seeds diverge, draining one stream does
not shift another, stream names change the derived seed, and integer draws stay
in range and replay.

**Run loop** — the real `main.tscn` driven through wave spawn, a genuine hitbox
connection from simulated input, wave clear, sacrifice offer and confirm, boss
spawn, victory, restart, and player death — plus every debug command and a smoke
check that all ten critical scenes load and instantiate.

Current baseline after M1.5: **66 tests / 421 assertions**.

## What is not covered

Honest gaps, so nobody reads a green suite as more than it is:

- No visual regression. The pixel-art rendering settings were verified by
  capturing frames under a virtual display during development; nothing asserts
  them automatically.
- No performance or frame-budget assertions.
- No input-remapping or controller coverage.
- No test for the enemy attack landing on the player through physics; the
  player-side path is covered, and the enemy side uses the same `Hitbox`.
- Timing-sensitive assertions use physics-frame counts, not wall clock, so they
  are deterministic but coarse.

## Adding a test

1. Add `tests/cases/test_<area>.gd` extending `TestCase`.
2. Name methods `test_*`; use `before_each` / `after_each` for fixtures.
3. Assert on behaviour and invariants, not on implementation details.
4. If a test needs elaborate scaffolding to reach the thing it checks, treat
   that as a signal about the design before reaching for a bigger hammer.
