# Task Register

No future task is started. Update status and PR only when work actually begins.

| ID | Task | Owner | Status | Branch | Dependency | PR |
| --- | --- | --- | --- | --- | --- | --- |
| C01 | Repository and document review | Claude | Waiting | `claude/core-framework` | Repository setup | — |
| C02 | Godot project skeleton | Claude | Waiting | TBD | C01 | — |
| C03 | RunState and core models | Claude | Blocked | TBD | C02 | — |
| C04 | CombatResolver | Claude | Blocked | TBD | C03 | — |
| C05 | Sacrifice framework | Claude | Blocked | TBD | C03 | — |
| C06 | EnemyBase reference | Claude | Blocked | TBD | C04 | — |
| C07 | Boss framework | Claude | Blocked | TBD | C06 | — |
| C08 | Tests and CI | Claude | Blocked | TBD | Core framework | — |
| X01 | Melee ghost | Codex | Waiting for interface freeze | `codex/x01-melee-ghost` | C06 | — |
| X02 | Ranged ghost | Codex | Waiting for interface freeze | `codex/x02-ranged-ghost` | C06 | — |
| X03 | Charger ghost | Codex | Waiting for interface freeze | `codex/x03-charger-ghost` | C06 | — |
| X04 | Placeholder Boss attack pack | Codex | Waiting for interface freeze | `codex/x04-boss-attacks` | C07 | — |
| X05 | Sacrifice UI | Codex | Waiting for interface freeze | `codex/x05-sacrifice-ui` | C05 | — |
| X06 | Twelve sacrifice definitions | Codex | Waiting for interface freeze | `codex/x06-sacrifice-data` | C05 | — |
| X07 | Debug and telemetry panel | Codex | Waiting for interface freeze | `codex/x07-debug-panel` | Core framework | — |
| X08 | Automated test expansion | Codex | Waiting for interface freeze | `codex/x08-test-expansion` | C08 | — |
