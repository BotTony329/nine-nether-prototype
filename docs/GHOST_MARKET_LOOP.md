# Ghost Market Loop

> **STATUS: ACTIVE — M2** · Owner: Claude

The loop between runs. Minimal on purpose: a hub, one upgrade, one save file.

```
Ghost Market → Start Run → Combat → Death / Victory → Run Result → Ghost Market
```

## Scenes

| Scene | Role |
| --- | --- |
| `scenes/app.tscn` | Main scene. Owns `MetaState` and `MetaSave`; swaps between the two below. |
| `scenes/ghost_market.tscn` | Hub UI: soul ash, latest run, one upgrade, start, reset. |
| `scenes/main.tscn` | One run. Unchanged in behaviour; it does not know the market exists. |

Exactly one of the last two is in the tree at a time. Hiding the idle one is not
an option: both present their UI on `CanvasLayer`s, and a `CanvasLayer` does not
inherit visibility from a parent `Node2D`, so a "hidden" market keeps drawing.

`main.tscn` still runs standalone (F6 in the editor): `autostart` defaults true
and dismissing the result screen restarts in place. `App` sets `autostart` false
and drives the run itself.

## Run end pipeline

Death and victory already converge on `RunCoordinator._finish_run`, which is
guarded by the phase machine. Everything after that is one path:

```
RunCoordinator._finish_run(outcome)
  → builds RunResult          (outcome, duration, kills, sacrifices, integrity, imbalance)
  → run_finished(result)
App._on_run_finished(result)
  → MetaState.record_run      (prices the run, banks the ash, moves the counters)
  → MetaSave.save_state
ResultScreen.dismissed
  → App.open_market
```

Banking happens on run end, not on dismissal: a player who quits at the result
screen keeps what they earned.

**Duplicate end requests are ignored** at two layers, each for its own reason —
`RunCoordinator` will not leave `PHASE_RESULT` twice, and `App._run_recorded`
guarantees one reward per run even if the signal is re-emitted.

## Data

`MetaState` (`core/meta_state.gd`) persists five values and nothing else:
soul ash, runs, deaths, victories, Tempered Blade owned. Private fields, reads
through getters, writes through named commands — the same rule `RunState`
follows, so the market observes and asks rather than assigning.

`RunResult` (`systems/run_result.gd`) is a plain value: outcome, duration, kills,
sacrifices, integrity, imbalance, soul ash earned. The run fills all but the
last; pricing is a meta concern.

`MetaConfig` (`data/meta_config.tres`) holds the meta tunables, kept apart from
`BalanceConfig` so tuning the shop cannot disturb combat balance:

| Field | Default |
| --- | --- |
| `soul_ash_base` | 5 |
| `soul_ash_per_kill` | 2 |
| `soul_ash_victory_bonus` | 25 |
| `tempered_blade_cost` | 40 |
| `tempered_blade_attack_bonus` | 2.0 |

## Save

`user://meta_save.json`, shape `{ "version": 1, "meta": { … } }`.
`MetaSave` takes its path as a constructor argument so tests write to a scratch
file. A missing, unreadable, malformed or newer-versioned save yields a fresh
profile with a warning — refusing to launch would be worse than losing a save.
Bump `MetaSave.VERSION` when the stored shape changes in a way
`MetaState.from_dictionary` cannot absorb, and add the migration there.

## The one upgrade

**Tempered Blade** — costs soul ash once, grants flat starting attack to every
later run, permanently. It reaches a run through exactly one channel:
`App` sets `Main.meta_attack_bonus`, `RunCoordinator` applies it via
`RunState.add_flat_attack` when the run's state is created. Offensive, not
structural, so a permanent upgrade cannot make the body read as more or less
whole and the integrity formula is unaffected.

## What a new run resets

Reset by creating a fresh `RunState` and clearing the actor root: current and
max HP, stamina, integrity, imbalance, sacrifice history, enemies, corpses and
projectiles. Kept: soul ash and the upgrade, which live in `MetaState`.

## Visuals

The market reuses existing floor, brick, brazier and ghost-fire art. It is
decoration: no script reads it, so replacing it with real market art changes no
code. There is no merchant, no NPC and no walkable hub — one panel.

## Not in M2

No second upgrade, no upgrade tree, no currency sinks beyond the one purchase,
no run modifiers chosen in the hub, no meta unlocks affecting the sacrifice pool
or enemy roster, no cloud save, no multiple profiles.
