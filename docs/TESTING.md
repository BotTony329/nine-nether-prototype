# Testing

> **STATUS: DRAFT — TO BE UPDATED BY CLAUDE AFTER FRAMEWORK IMPLEMENTATION**

Every task must add or update proportionate automated tests, run existing tests, record commands and manual checks in its PR, and report the last successful result in `docs/AI_HANDOFF.md`.

At present, CI runs only `repository-validation`; it checks repository structure and hygiene, not gameplay. Claude will define the Godot test harness and later add a separately named `godot-tests` workflow after it can run successfully.
