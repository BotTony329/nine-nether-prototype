# Runtime Art Source Audit

## Audit context

The M2 Ghost Market line and Art V3 production line both forked from commit
`5bbeb87`. The audit compares the Claude M2 tip (`c418516`) with latest
`develop` (`1ecdd05`) and traces the integrated working tree from the real
application entry point. Line numbers below refer to those committed revisions
unless explicitly marked as the integrated working tree.

## Live runtime chain

`project.godot:13` selects `scenes/app.tscn`. `scenes/app.tscn:5` exports
`scenes/main.tscn` as the run scene, and `scenes/app.gd:70-83` instantiates that
exact `PackedScene`. The combat composition selects its concrete actors at
`scenes/main.tscn:6-10`.

| Actor / visual | Spawned scene | Visual node | Runtime texture / animation source | Current | Expected | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Player | `actors/player/player.tscn` | `Sprite` (`AnimatedSprite2D`) | scene line 4 → `assets_v3/godot/player_frames.tres:5-13` → `assets_v3/production/player/**` | V3 | V3 | CORRECT |
| Melee Ghost | `actors/enemies/ghost_melee.tscn` | inherited `Sprite` | scene line 4 → `assets_v3/godot/melee_ghost_frames.tres:5-9` → `assets_v3/production/ghost_melee/**` | V3 | V3 | CORRECT |
| Ghost Archer | `actors/enemies/ghost_archer.tscn` | inherited `Sprite` | scene line 5 → `assets_v3/godot/ghost_archer_frames.tres:5-10` → `assets_v3/production/ghost_archer/**` | V3 | V3 | CORRECT |
| Ghost Arrow | `actors/enemies/ghost_arrow.tscn` | `Visual` (`Sprite2D`) | scene line 4 → `assets_v3/production/projectiles/ghost_arrow.png` | V3 | V3 | CORRECT |
| Gate Warden | `actors/boss/boss.tscn` | `Sprite` (`AnimatedSprite2D`) | scene line 4 → `assets_v3/godot/gate_warden_frames.tres:5-10` → `assets_v3/production/gate_warden/**` | V3 | V3 | CORRECT |
| Combat effects | `scenes/main.tscn` | `CombatFeedback` | `visuals/combat_feedback.gd:10-22` → V3 slash, hit, blood, death | V3 | V3 | CORRECT |
| Primary HUD icons | `ui/hud.tscn` | `Player/Icon`, `Boss/Icon` | lines 6-7 → V3 HP and Boss icons | V3 | V3 | CORRECT |
| Secondary HUD icons | `ui/hud.tscn` | obsolete stamina, attack, integrity, imbalance icon nodes | removed; their text and bars remain | absent | V3-only runtime | CORRECT |

`tools/generate_sprite_frames.py` writes the four live resources under
`assets_v3/godot/`. This generator plus those generated resources is the single
source of truth for production actor animations. Legacy generated resources
under `assets_v2/godot/` and unreferenced actor-local `*_frames.tres` files are
not part of the live graph.

## Exact source of the observed Art V2 visuals

The regression is branch selection, not a Godot cache defect. At the M2 tip
`c418516`, the same compatibility resources were still their pre-production
versions:

- `assets_v2/godot/player_frames.tres:5-13` loaded
  `assets_v2/characters/player/**`.
- `assets_v2/godot/melee_ghost_frames.tres:5-9` loaded
  `assets_v2/characters/melee_ghost/**`.
- `assets_v2/godot/ghost_archer_frames.tres:5-10` loaded
  `assets_v2/characters/ghost_archer/**`.
- `assets_v2/godot/gate_warden_frames.tres:5-10` loaded
  `assets_v2/characters/gate_warden/**`.
- `actors/enemies/ghost_arrow.tscn:4` loaded the V2 arrow.
- `actors/player/player.tscn:8,10`, the concrete enemy/Boss scenes, and
  `scenes/main.tscn:17` loaded V2 slash, death, and hit effects.
- `ui/hud.tscn:6-10` loaded V2 HUD icons.

M2's `App` correctly instantiates `scenes/main.tscn`; it does not override an
actor or texture. Running the M2 branch therefore selected its older committed
run resource graph exactly as authored. Art V3 existed only on the divergent
production branch. A later production-branch commit (`ba3ae3f`) changed only
`project.godot` to point at `scenes/app.tscn` but did not contain that scene, so
it is not a valid integration source.

## Likely-cause verdicts

1. **Scene reference mismatch — rejected.** `App` exports and instantiates the
   current `scenes/main.tscn`; `Main` exports the current concrete actor scenes.
2. **Actor scene points to Art V2 — confirmed on M2.** The scene points to a
   compatibility `.tres` whose M2 revision loaded V2 atlases. The integrated
   revision loads V3 atlases.
3. **Duplicate visual nodes — rejected for live actors.** Each actor has one
   character `AnimatedSprite2D`. Actor-local frame resources are duplicate
   files, not simultaneously rendered nodes.
4. **Fallback always active — rejected.** Ghost Arrow's polygon starts hidden;
   `ghost_arrow.gd:23-25` enables it only if `Visual` or its texture is null.
5. **Old merge resolution — confirmed as a branch-history risk.** M2 never
   contained the production scene/resource commits; choosing its versions
   recreates the regression.
6. **Runtime-generated SpriteFrames — rejected for actors.** No actor script
   replaces `sprite_frames`; only transient combat effects build frames at
   runtime, from V3 preloads.
7. **PackedScene override — rejected.** `app.tscn` exports current `main.tscn`;
   no test or runtime code replaces its player, enemy, or Boss scene fields.
8. **Import/cache mismatch — rejected.** The M2 committed source paths are V2;
   cache clearing cannot turn them into V3. A clean import remains required for
   validation.
9. **Wrong branch / missing merge — confirmed root cause.** Latest `develop`
   contained Art V3 but not M2; M2 contained the app loop but predated Art V3.
10. **Wrong launch scene — partially confirmed elsewhere.** `ba3ae3f` points to
    a missing `app.tscn`. The integrated project selects the real M2 App and its
    current Main scene.

## Required integration resolution

The Claude-authored M2 line is merged onto latest `develop`, leaving develop's
Art V3 actor scenes, generated animation mappings, effects, and primary HUD
icons authoritative. Unused duplicate animation mappings and visible V2 HUD
icons are removed so normal gameplay has one production visual path. The Ghost
Arrow fallback remains asset-failure-only; collision and debug geometry are
unchanged.

Regression coverage must boot the actual `App`, start a run, and inspect the
live player, wave enemy, Ghost Archer, arrow, Gate Warden, HUD, effects, death
return, and second run—not merely load PNG files from disk.

## Validation result

- Godot 4.3 stable imported from a clean generated cache.
- Full suite: 85 tests, 796 assertions, 0 failures.
- The App opens the Ghost Market with no combat scene present.
- App-driven first and second runs resolve live player and melee atlases to
  `assets_v3/production`.
- Direct production-scene coverage verifies Ghost Archer, Ghost Arrow, Gate
  Warden, fallback state, HUD icons, and all four combat-feedback textures.
- Death and victory both return to the Ghost Market through the M2 pipeline.
- Evidence: `docs/screenshots/runtime_market_v3.png`,
  `docs/screenshots/runtime_combat_v3.png`, and
  `docs/screenshots/runtime_boss_v3.png`.
