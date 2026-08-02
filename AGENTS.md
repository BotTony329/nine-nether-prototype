# AGENTS.md

## Project

Nine Nether is a Godot 4.x/GDScript greybox prototype. Its core mechanic is sacrificing structural survival and action freedom for offensive power.

## Required reading and authority

Read in this source-of-truth order; an earlier document wins any conflict:

1. `docs/PRD.md`
2. `docs/PROTOTYPE_CONTRACT.md`
3. `docs/ARCHITECTURE.md`
4. `docs/INTERFACES.md`
5. `docs/DECISIONS.md`
6. `docs/AI_HANDOFF.md`
7. `AGENTS.md`

Do not invent missing product rules.

## Branch rules

- Never push directly to `main` or `develop`; use one branch per task.
- Claude uses `claude/<task-name>`; Codex uses `codex/<task-id>-<task-name>`.
- All work enters `develop` through pull requests. `main` receives only tested release PRs from `develop`.

## Ownership

Claude owns core architecture and system folders, combat resolution, `RunState`, state schemas, EventBus and RNG contracts, the sacrifice transaction framework, player architecture, and architecture decisions.

Codex owns concrete enemies, specific Boss attack content, UI implementations, sacrifice data, tests, debug tools, isolated content modules, and task-related documentation.

## Frozen interfaces

Codex must not modify a frozen core interface without documenting the need in the PR, adding a proposal to `docs/DECISIONS.md`, and waiting for Claude review.

## Completion checklist

Every task must run tests, review `git diff`, update `docs/AI_HANDOFF.md`, document interface changes, use data-driven values, avoid unrelated refactors, push its branch, and open a PR to `develop`.
