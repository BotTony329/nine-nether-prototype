# GitHub Workflow

## Claude

```bash
git checkout develop
git pull origin develop
git checkout -b claude/core-framework
# Work, test, document, push, then open a PR to develop.
```

## Codex

```bash
git checkout develop
git pull origin develop
git checkout -b codex/x01-melee-ghost
# One task, one branch, one PR to develop.
```

Codex PRs are reviewed against `docs/INTERFACES.md`. Claude core PRs are reviewed against the PRD and Prototype Contract. The Game Director decides merges; no AI automatically merges its own PR.

Release via `develop` → PR → `main`. Tag stable releases `v0.1.0`, `v0.2.0`, and so on.
