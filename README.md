# Nine Nether

Nine Nether is a Godot 4 greybox prototype exploring a core trade-off: sacrifice structural survival and action freedom for offensive power. Every power has a price.

- **Phase:** M1 — playable vertical slice foundation
- **Playable status:** playable end to end (wave → sacrifice → boss → victory or death → restart)
- **Engine/language:** Godot 4.3 stable / GDScript
- **Branches:** `main` contains stable playable releases; `develop` is the integration branch; work occurs on one `claude/*` or `codex/*` branch per task.

## Running it

Open the project folder in Godot 4.3 and press F5, or from the command line:

```bash
godot --path .
```

The main scene is `res://scenes/main.tscn`. There are no external dependencies — clone and run.

### Controls

| Action | Keys |
| --- | --- |
| Move | `A` / `D` or `←` / `→` |
| Jump | `Space` or `W` |
| Light attack | `J` or left mouse |
| Confirm sacrifice | `Enter` |
| Restart run | `R` |

### Debug (development builds)

| Key | Command |
| --- | --- |
| `F1` | Toggle the RunState readout (seed, phase, player state, every stat, snapshot hash) |
| `F2` / `F3` | Heal / damage the player |
| `F4` | Spawn a Ghost Archer next to the player |
| `F5` | Start the boss encounter |
| `F6` / `F7` | Preview / apply the sacrifice |
| `F8` | Toggle hit, hurt and body boxes |

## Tests

```bash
godot --headless --import
godot --headless --path . res://tests/test_runner.tscn
```

See [docs/TESTING.md](docs/TESTING.md). CI runs `repository-validation` and `godot-tests` on every pull request into `develop`.

## Where to start reading

Product first, then implementation:

1. [PRD](docs/PRD.md) and [Prototype Contract](docs/PROTOTYPE_CONTRACT.md) — the product source of truth
2. [Architecture](docs/ARCHITECTURE.md) — what the code does and why
3. [Interfaces](docs/INTERFACES.md) — the frozen contracts and where to extend them
4. [Decisions](docs/DECISIONS.md) — the trade-offs already made
5. [AI handoff](docs/AI_HANDOFF.md) — current state, known issues, next tasks
6. [Contributor rules](AGENTS.md) and [GitHub workflow](docs/GITHUB_WORKFLOW.md)

The playable actors, projectile, combat effects, and matching HUD fields use the
production Art V2 pack. The legacy placeholder set remains as source material
for modules not yet integrated; see
[docs/ART_V2_INTEGRATION_REPORT.md](docs/ART_V2_INTEGRATION_REPORT.md).

This repository is a greybox prototype, not a finished or publicly supported game.
