# Repository Ownership

| Area | Primary Owner | Secondary Reviewer | Modification Rule |
| --- | --- | --- | --- |
| Core architecture | Claude | Game Director | Codex cannot change directly |
| RunState | Claude | Game Director | Frozen after interface release |
| CombatResolver | Claude | Game Director | Single source of truth |
| Enemy modules | Codex | Claude | Use EnemyBase only |
| Boss attacks | Codex | Claude | Cannot create separate damage system |
| UI | Codex | Claude | Cannot mutate RunState directly |
| Sacrifice data | Codex | Claude | Framework owned by Claude |
| Tests | Codex | Claude | Required for all modules |
| Debug tools | Codex | Claude | Development-only behaviour |
| Product requirements | Game Director | ChatGPT/WorkBuddy | Engineers do not rewrite |
