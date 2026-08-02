# Contributing

## Authority and ownership

Read `docs/PRD.md`, `docs/PROTOTYPE_CONTRACT.md`, `docs/ARCHITECTURE.md`, `docs/INTERFACES.md`, `docs/DECISIONS.md`, `docs/AI_HANDOFF.md`, then `AGENTS.md`. Earlier documents have higher authority. The Game Director owns product requirements; Claude owns core architecture; Codex owns isolated modules, UI, data, tests, and debug tooling.

## Workflow

`develop` → new task branch → implementation → tests → documentation update → push → PR to `develop` → review → merge → delete task branch.

`main` is stable only; `develop` is integration. Use `claude/<task-name>` or `codex/<task-id>-<task-name>`. Never push directly to either protected branch, and never self-merge. Release by reviewed PR from `develop` to `main`.

Name PRs with task and owner, for example `[X01][Codex] Implement melee ghost`. Suggested commits:

- `[C01][Claude] Initialize Godot project skeleton`
- `[C02][Claude] Add combat resolver framework`
- `[X01][Codex] Implement melee ghost`
- `[X05][Codex] Add sacrifice selection UI`
- `[Docs] Update AI handoff`
- `[Fix] Prevent duplicate enemy death event`

## Interfaces, decisions, and handoff

To request a frozen-interface change, explain the need and impact in the PR, append a proposed decision to `docs/DECISIONS.md`, and wait for Claude review. Record new decisions without rewriting earlier history. Before handoff, update `docs/AI_HANDOFF.md` with state, next owner/task, interfaces, blockers, last successful test, and date.
