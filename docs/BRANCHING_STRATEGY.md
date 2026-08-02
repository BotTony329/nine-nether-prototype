# Branching Strategy

| Branch | Purpose |
| --- | --- |
| `main` | Stable playable releases only |
| `develop` | Integrated development branch |
| `claude/*` | Framework, architecture, refactoring, and core integration; e.g. `claude/core-framework` |
| `codex/*` | One isolated task/module per branch; e.g. `codex/x01-melee-ghost` |
| `release/*` | Optional later; not required for the first prototype |
| `hotfix/*` | Defects in `main` after playable releases exist |

All changes use reviewed pull requests. Delete task branches after merge. Never force-push shared protected branches.
