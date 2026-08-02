# AI Handoff

- **Current phase:** Art asset pipeline complete; core framework not started.
- **Current playable state:** No playable build exists.
- **Completed repository work:** Collaboration rules, ownership, templates, task tracking, repository hygiene validation, and **prototype art asset pipeline** (63 placeholder sprites, 8 concept docs, master art spec, Godot import guide, all directory READMEs and metadata).
- **In progress:** Art PR (`workbuddy/prototype-art`) awaiting review/merge.
- **Next owner:** Claude.
- **Next task:** Create `claude/core-framework` from the latest `develop` branch. Art assets are ready in `assets/` — read `docs/ART_SPEC.md` and each directory's `metadata.md` for sprite sheet frame counts, sizes, and FPS values.
- **Frozen interfaces:** None; no gameplay interfaces are frozen yet.
- **Do not modify:** Product requirements without Game Director approval; `main`/`develop` directly; future frozen interfaces without the decision process; art concept documents (`docs/art/CONCEPT_*.md`) without consulting the Art Director.
- **Known blockers:** Approved detailed PRD and Prototype Contract source material is not present in the repository.
- **Art asset notes:** All PNGs in `assets/` are placeholders (magenta border). Replace by saving a new PNG with the same filename and dimensions. See `docs/ART_SPEC.md` Section 5 for replacement workflow. Godot import settings documented in `docs/art/GODOT_IMPORT_GUIDE.md` and `godot/import_presets.md`.
- **Last successful test:** Repository validation checks (2026-08-02).
- **Last updated:** 2026-08-02 (Australia/Melbourne).

The PRD and Prototype Contract are the current highest-priority sources of truth. `docs/ART_SPEC.md` is the source of truth for all visual art assets.
