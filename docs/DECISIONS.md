# Architecture Decisions

> **STATUS: ACTIVE**

Append decisions in this format; do not rewrite accepted history.

## ADR-NNN: Title

- **Status:** Proposed / Accepted / Superseded
- **Date:** YYYY-MM-DD
- **Owner:**
- **Context:**
- **Decision:**
- **Consequences:**
- **Interfaces affected:**

---

## ADR-001: Derive M1 scope from the Prototype Development Pack, not from a rewritten PRD

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** `docs/PRD.md` and `docs/PROTOTYPE_CONTRACT.md` are still
  `AWAITING GAME DIRECTOR SOURCE MATERIAL` stubs. The Game Director supplied
  *《九幽》白盒原型联合开发包 v1.0* and *《残躯换锋》2D 动作肉鸽核心机制深度研究报告* as
  reference material for M1. `AGENTS.md` forbids engineers inventing product
  rules, and the M1 brief forbids rewriting the PRD or replacing the Contract.
- **Decision:** Implement M1 against the Development Pack (Part I contract,
  Part II architecture) and the research report's formulas. Leave `PRD.md` and
  `PROTOTYPE_CONTRACT.md` untouched. Record every derived number's source
  section in code comments and in `docs/ARCHITECTURE.md`.
- **Consequences:** The repository's declared highest source of truth is still
  a stub, so the traceability chain runs through this ADR rather than through
  the PRD. **The Game Director should land the real PRD and Prototype Contract
  before Codex starts X01–X08**, so later work has a document to be reviewed
  against rather than an ADR.
- **Interfaces affected:** none directly; all balance constants in
  `data/balance_config.tres`.

## ADR-002: 640×360 viewport upscaled to 1280×720 with integer scaling

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** `godot/import_presets.md` recommends `viewport_width = 1280`,
  `viewport_height = 720` with `stretch/mode = viewport`. At that setting the
  game renders 1:1, so a 48×48 player is about 6% of screen height and a 32px
  tile is barely visible — the art reads as tiny rather than as pixel art.
- **Decision:** Viewport 640×360, window 1280×720, `stretch/mode = viewport`,
  `stretch/scale_mode = integer`. Nearest filtering, no mipmaps, 2D pixel
  snapping on, MSAA off, `gl_compatibility` renderer as recommended.
- **Consequences:** Every asset renders at an exact integer scale at any window
  size; no blur and no shimmer during camera movement. 320×180 `bg_deep` tiles
  cleanly at 1:1. The recommendation in `godot/import_presets.md` is superseded
  for the viewport size only; every other setting in that file is honoured.
  Asset dimensions were not changed.
- **Interfaces affected:** `project.godot` `[display]` and `[rendering]`.

## ADR-003: Use the WorkBuddy pixel art rather than the whitebox rectangles

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** Development Pack P12 specifies whitebox readability — blue-grey
  rectangle player, dark red enemies, purple Boss. Since that pack was written,
  WorkBuddy delivered a complete placeholder sprite pipeline (62 PNGs plus
  `docs/ART_SPEC.md`, which declares itself the source of truth for visual
  assets), and the M1 brief requires those assets to be used.
- **Decision:** Use the pixel art. Keep P12's *readability* requirements — the
  enemy wind-up is a colour flash driven by `EnemyConfig.telegraph_tint`, and
  F8 draws hit/hurt/body boxes.
- **Consequences:** The prototype looks further along than it is; the magenta
  placeholder borders make that visible. Readability obligations are met by
  behaviour rather than by flat colours.
- **Interfaces affected:** none.

## ADR-004: Generate SpriteFrames from the art spec instead of hand-authoring

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** Sixteen animations across player, reference enemy and Boss come
  to about 70 `AtlasTexture` sub-resources. Hand-writing them duplicates the
  frame counts and FPS that already exist in `docs/ART_SPEC.md` and each
  directory's `metadata.md`.
- **Decision:** `tools/generate_sprite_frames.py` owns the frame table and emits
  `actors/*/**_frames.tres`. The generated files are committed. The generator
  verifies each sheet's real pixel dimensions against the table and aborts on a
  mismatch.
- **Consequences:** When WorkBuddy replaces a sheet, re-run the generator and
  commit the diff. A sheet whose frame count silently changes fails loudly
  instead of producing sliced animations.
- **Interfaces affected:** none.

## ADR-005: Authored `imbalance_flat` wins over the derived imbalance formula

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** Research report 5.6 gives `ΔB = C × (0.75 + 0.05·S)`. For
  断寿之契 that yields 12.75, but the card table in section 9.2 lists +16, and
  the JSON example in 13.3 carries an explicit `imbalanceFlat`. The two sources
  disagree, and the card tables are the ones a designer will tune.
- **Decision:** `SacrificeDefinition.imbalance_flat` is authoritative when
  greater than zero; otherwise the formula applies. The derived cost score `C`
  is always computed and returned in `SacrificeResult.cost_score` for telemetry
  and for the future slot `ValueRatio` scoring.
- **Consequences:** Designers tune imbalance per card without fighting a
  formula, and the formula remains the default for cards that do not specify.
  Reconcile if the Game Director rules one way.
- **Interfaces affected:** `SacrificeDefinition`, `SacrificeService`.

## ADR-006: In-repo test harness, run as a scene rather than via `--script`

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** Development Pack A2 requires the project to run and test straight
  after clone with no extra downloads. Vendoring GUT or gdUnit4 for a dozen
  assertions costs more than it saves. Separately, running the suite through
  `godot --headless --script res://tests/run_tests.gd` was tried and failed:
  a MainLoop script is compiled *before* the autoload singletons are registered,
  so `CombatResolver` (which names `RNGService`) and `SacrificeService` (which
  names `EventBus`) fail to compile, `GameData` degrades to null services, and
  most tests fail with `Nonexistent function ... in base 'Nil'`.
- **Decision:** A ~90 line harness (`tests/framework/test_case.gd` +
  `tests/test_runner.gd`) launched as a scene:
  `godot --headless --path . res://tests/test_runner.tscn`.
- **Consequences:** No plugin dependency and no parse-order trap; the test
  process boots exactly like the game. If the suite outgrows plain assertions —
  parameterised cases, fixtures, mocking — swap in gdUnit4 rather than growing
  the harness.
- **Interfaces affected:** `docs/TESTING.md`, `.github/workflows/godot-tests.yml`.

## ADR-007: No TileMap in M1

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** The arena is one fixed space with four collision rectangles.
  Authoring a `TileSet` resource plus `TileMapLayer` data by hand adds a lot of
  generated content for a layout that does not vary.
- **Decision:** Terrain visuals are `Sprite2D` nodes with repeating texture
  regions; collision is explicit `StaticBody2D` + `RectangleShape2D`.
- **Consequences:** Simpler diffs and exact collision bounds. If the arena ever
  needs varied terrain, one-way platforms or hazards, move to `TileMapLayer` —
  the spawn markers and camera bounds on `Arena` do not change.
- **Interfaces affected:** `scenes/arena.gd` (`camera_bounds`,
  `enemy_spawn_points`, `player_spawn`, `boss_spawn`).

## ADR-008: A sacrifice may never raise structural integrity

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** The transaction needs a real failure mode for its rollback path
  to be meaningful. The most likely data defect is a designer typing a cost
  multiplier above 1 — `1.15` where `0.85` was meant — which would *increase* a
  structural stat and quietly hand the player a reward for free.
- **Decision:** After the cost step, `SacrificeService` compares integrity with
  its pre-transaction value. If integrity rose, the transaction fails with a
  readable reason and the state is restored from the snapshot.
- **Consequences:** The rollback path is exercised by a real, reachable defect
  rather than being dead code. Note the guard only trips when the affected
  integrity component is below its cap, since components are clamped at 1.
- **Interfaces affected:** `SacrificeService.apply` / `preview` failure results.

## ADR-009: `scenes/` directory beyond the A3 layout

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** Development Pack A3 lists `core/`, `systems/`, `actors/*`, `ui/`,
  `data/`, `tests/` and `docs/`, but A4 requires `Main.tscn` and `Arena.tscn`,
  which belong to none of them.
- **Decision:** Add `res://scenes/` for `main.tscn`, `main.gd`, `arena.tscn` and
  `arena.gd`. Claude-owned, same rules as `core/`.
- **Consequences:** One directory beyond the pack; the ownership table in
  `docs/ARCHITECTURE.md` covers it.
- **Interfaces affected:** none.

## ADR-010: The prototype Boss ships one attack

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** Development Pack A14/X04 asks for three moves and two phases. The
  M1 brief allows a second move "only if supported by the available animation
  assets". `assets/boss/` contains exactly one attack sheet
  (`boss_attack.png`, 5 frames) alongside idle, run, hurt and death.
- **Decision:** Ship one telegraphed melee attack. Do not fake a charge by
  replaying the run cycle and do not add a phase controller.
- **Consequences:** The Boss fight is thin — a readable pattern with one answer.
  Codex X04 adds the charge and the ground slam; it needs either new art from
  WorkBuddy or an explicit ruling that reusing the run cycle for a charge is
  acceptable.
- **Interfaces affected:** none; `BossActor` extends `EnemyBase` unchanged.

## ADR-011: Stamina is structural in M1 with no consumer

- **Status:** Accepted
- **Date:** 2026-08-02
- **Owner:** Claude
- **Context:** Research report 6.1 makes light attack cost 0 stamina on purpose,
  so a player is never fully locked out of acting. M1's only player action is
  the light attack, so nothing spends stamina. But a sacrifice that cuts max
  stamina must still be visible, and `IntegrityService` weights it at 0.24.
- **Decision:** `RunState` tracks current and max stamina with delayed
  regeneration; the HUD shows the bar; `Player.spend_stamina` exists and is
  routed. No StaminaService, no exhaustion lock, no dodge.
- **Consequences:** The stamina bar sits at full during normal play, which is
  correct rather than broken. A future StaminaService can wrap
  `Player.spend_stamina` without changing its callers.
- **Interfaces affected:** `RunState` stamina commands, `Player.spend_stamina`.
