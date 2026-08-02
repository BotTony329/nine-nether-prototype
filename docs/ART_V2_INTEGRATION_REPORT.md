# Art V2 Integration Report

**Branch:** `codex/m15-art-v2-integration`

**Audit date:** 2026-08-02

**Target viewport:** 640×360

## Verification method

Every integrated PNG was opened programmatically and checked for RGBA
transparency, exact sheet dimensions, whole-frame divisibility, and the frame
count declared by its adjacent `frame_map.json` / `metadata.md`. Godot then
imported every resource and instantiated the critical scenes in the headless
test suite. Source PNGs were not resized or rewritten.

The supplied `assets_v2/godot/*_frames.tres` resources are used directly.
Project-wide nearest-neighbour filtering and disabled mipmaps remain in force;
sprites use integer scale and explicit foot-aligned offsets independent of
their collision shapes.

## Integrated inventory

| Asset | Declared frames | Actual frames | Integrated | Fallback | Notes |
| --- | ---: | ---: | --- | --- | --- |
| Player idle | 8 × 96×96 | 8 (768×96) | Yes | None | 8 FPS, loop, pivot (48,66), foot y=88 |
| Player run | 8 × 96×96 | 8 (768×96) | Yes | None | 12 FPS, loop |
| Player jump | 3 × 96×96 | 3 (288×96) | Yes | None | 10 FPS, non-looping; rising state |
| Player fall | 3 × 96×96 | 3 (288×96) | Yes | None | 10 FPS, non-looping; falling state |
| Player light attack 1 | 8 × 96×96 | 8 (768×96) | Yes | None | 12 FPS; startup 0–3, active 4–5, recovery 6–7 |
| Player hurt | 4 × 96×96 | 4 (384×96) | Yes | None | 10 FPS, non-looping |
| Player death | 10 × 96×96 | 10 (960×96) | Yes | None | 8 FPS, non-looping; result overlay waits |
| Melee ghost idle | 6 × 96×96 | 6 (576×96) | Yes | None | 8 FPS, loop, pivot (48,70), foot y=90 |
| Melee ghost walk | 8 × 96×96 | 8 (768×96) | Yes | None | 8 FPS, loop |
| Melee ghost attack | 8 × 96×96 | 8 (768×96) | Yes | None | 10 FPS; startup 0–3, active 4–5, recovery 6–7 |
| Melee ghost hurt | 4 × 96×96 | 4 (384×96) | Yes | None | 10 FPS, non-looping |
| Melee ghost death | 8 × 96×96 | 8 (768×96) | Yes | None | 8 FPS, non-looping; removal waits |
| Ghost Archer idle | 6 × 96×96 | 6 (576×96) | Yes | None | 8 FPS, loop, pivot (48,64), foot y=88 |
| Ghost Archer retreat | 8 × 96×96 | 8 (768×96) | Yes | None | 10 FPS, loop; patrol/retreat movement |
| Ghost Archer aim | 6 × 96×96 | 6 (576×96) | Yes | None | 8 FPS, full draw at frame 5 |
| Ghost Archer shoot | 4 × 96×96 | 4 (384×96) | Yes | None | 14 FPS; projectile release frame 1, recovery 2–3 |
| Ghost Archer hurt | 4 × 96×96 | 4 (384×96) | Yes | None | 10 FPS, non-looping |
| Ghost Archer death | 8 × 96×96 | 8 (768×96) | Yes | None | 8 FPS, non-looping; no post-death release |
| Gate Warden idle | 8 × 192×192 | 8 (1536×192) | Yes | None | 6 FPS, loop, pivot (96,128), foot y=176 |
| Gate Warden walk | 8 × 192×192 | 8 (1536×192) | Yes | None | 8 FPS, loop |
| Gate Warden attack 1 | 10 × 192×192 | 10 (1920×192) | Yes | None | 9 FPS; startup 0–3, active 4–5, recovery 6–9 |
| Gate Warden hurt | 4 × 192×192 | 4 (768×192) | Yes | None | 8 FPS, non-looping |
| Gate Warden death | 12 × 192×192 | 12 (2304×192) | Yes | None | 6 FPS, non-looping; victory waits |
| Ghost Fire Arrow | 1 × 32×32 | 1 (32×32) | Yes | Hidden polygon | Emergency fallback only if texture load fails |
| Blade slash | 6 × 128×128 | 6 (768×128) | Yes | None | Read-only visual event on player active frame |
| Confirmed-hit effect | 4 × 96×96 | 4 (384×96) | Yes | None | Spawned by EventBus observer only after positive final damage |
| Death dissolve | 8 × 96×96 | 8 (768×96) | Yes | None | Secondary effect; never replaces death animation |
| Yang / HP icon | 1 × 64×64 | 1 | Yes | None | Existing HP HUD field |
| Qi / stamina icon | 1 × 64×64 | 1 | Yes | None | Existing stamina HUD field |
| Songdao / attack icon | 1 × 64×64 | 1 | Yes | None | Existing attack readout |
| Obsession / integrity icon | 1 × 64×64 | 1 | Yes | None | Integrity and Boss structural readouts |
| Ghostfire / imbalance icon | 1 × 64×64 | 1 | Yes | None | Existing imbalance field |
| Talisman / sacrifice icon | 1 × 64×64 | 1 | Yes | None | Existing sacrifice panel |

## Gameplay mapping and timing

The existing player state machine and `EnemyBase` state model remain the source
of gameplay truth. Concrete actor scripts translate those states to V2
animation names. `AnimatedSprite2D.frame_changed` only gates the existing
`Hitbox`; damage still flows through `Hitbox` → `Hurtbox` → `CombatResolver`.

- Player: grounded idle/run, rising jump, falling fall, light attack 1, hurt,
  death. Facing flips the sprite, slash, and existing attack hitbox together.
- Melee ghost: idle, walk, attack, hurt, death. Damage is enabled on frames 4–5.
- Ghost Archer: idle, retreat, aim, shoot, hurt, death. Aim reaches frame 5
  before shoot begins; its arrow is emitted once on shoot frame 1.
- Gate Warden: idle, walk, attack 1, hurt, death. Damage is enabled on frames
  4–5, and victory is emitted after the death strip completes.

## Mismatches, fallbacks, and remaining art

No integrated sheet has an invalid dimension, missing frame, transparency
failure, or metadata mismatch. The Ghost Arrow retains its old polygon as a
hidden emergency fallback, but normal gameplay always uses the supplied V2
texture.

Unused art was deliberately left out when gameplay has no matching action:
player light attack 2 and heavy attack, Gate Warden attack 2, the Corpse Beast
pack, Ghost Fire effect, and unmatched inventory/weapon icons. Integrating
those belongs with the corresponding gameplay modules, not this visual pass.

The following frozen/protected architecture files were not changed:
`RunState`, `CombatResolver`, `DamageContext`, `DamageResult`,
`IntegrityService`, `SacrificeService`, `EventBus`, `RNGService`,
`RunCoordinator`, `EnemyBase`, `player.gd`, `player_state_machine.gd`, and
`player_state.gd`.

## Visual validation evidence

Godot 4.7.1 rendered the real `main.tscn` at 640×360 while an automation driver
exercised idle, run, jump, player attack with F8 collision display, F4 Archer
spawn/aim/arrow release, and F5 Boss attack/death. The driver was removed after
capture; the resulting screenshots are under `assets_v2/review/integration_*.png`.

The screenshots confirm V2 actors/projectile/effects are visible, foot baselines
remain on the arena floor, the active player hitbox overlaps the visible slash,
and disabling the overlay leaves no primitive actor rendering. The full M1 loop,
sacrifice application, death deferral, and victory/restart were also exercised
by the automated run-loop suite. Interactive macOS control and MP4 conversion
were unavailable, so screenshots are supplied instead of a video.
