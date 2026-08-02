# Nine Nether — V2 (Steam Alpha) Art: Godot Import Guide

This guide is for **Codex** (or any engineer) wiring the V2 art set into the
Godot 4 project. The V2 set is a **full redesign** — do **not** reuse any
`assets/` (V1) sprites. V1 failed because characters shared body templates and
only differed by colour/weapon swaps, animations had near-invisible amplitude,
and there was no attack telegraph or silhouette variety. V2 fixes all of that.

---

## 1. Where things are

```
assets_v2/
  characters/
    player/        player_*.png            (96×96 / frame)
    melee_ghost/   melee_ghost_*.png       (96×96 / frame)
    ghost_archer/  ghost_archer_*.png      (96×96 / frame)
    corpse_beast/  corpse_beast_*.png      (128×96 / frame)
    gate_warden/   gate_warden_*.png       (192×192 / frame)
      └ each dir also has: concept_front/side/back.png, silhouette.png,
                           palette.png, contact_sheet.png, frame_map.json, metadata.md
  icons/           icon_*.png             (64×64, weapon/stat HUD icons)
  projectiles/     ghost_fire_arrow.png   (32×32)
  effects/         blade_slash / hit / ghost_fire / death_dissolve  (see sizes below)
  godot/           <char>_frames.tres     (SpriteFrames resources, ready to load)
  review/          character_scale_comparison.png, silhouette_comparison.png
  tools/           procedural generators (PIL) + gen_metadata.py
  GODOT_IMPORT_GUIDE.md
```

All sprite sheets are **horizontal strips** with `frames` cells left→right,
frame size as listed. Transparent background (RGBA). No anti-aliasing, no blur.

---

## 2. Import settings (critical)

For **every** PNG under `assets_v2/`:

- **Import as `Texture2D`** (default).
- In the `Import` dock:
  - **Filter:** `Nearest` (disable `Filter` / linear filtering).
  - **Mipmaps:** off.
  - **Compress:** keep (or `Compress > Mode = Lossless` if you see banding).
  - **Detect 3D:** off.
- Click **Reimport**.
- Do **not** enable `repeat`/`repeat_enable` on character sheets (you crop via AtlasTexture regions, see §4).

The game viewport is **640×360**, displayed at **1280×720** with integer
scaling — nearest-neighbour keeps pixels crisp.

---

## 3. Effects & projectiles (sizes)

| File | Size | Frames | Loop | Use |
|---|---|---|---|---|
| `effects/blade_slash.png` | 128×128 | 6 | no | melee hit VFX |
| `effects/hit.png` | 96×96 | 4 | no | generic impact |
| `effects/ghost_fire.png` | 64×64 | 8 | **yes** | ambient / emitter |
| `effects/death_dissolve.png` | 96×96 | 8 | no | death VFX |
| `projectiles/ghost_fire_arrow.png` | 32×32 | 1 | n/a | archer projectile (points RIGHT; flip in-engine for left) |

These are separate textures (not SpriteFrames) — use `AnimatedSprite2D` or
manual `region` animation, or just `Sprite2D` with a script stepping `region_rect`.

---

## 4. SpriteFrames resources (ready to use)

`assets_v2/godot/<char>_frames.tres` are **pre-generated** `SpriteFrames`
resources. Each animation is a list of `AtlasTexture` sub-resources cropping
`Rect2(frame*fw, 0, fw, fh)` from the character's sheet — identical pattern to
V1's `actors/enemies/ghost_archer_frames.tres`.

To use, in your actor scene:

```gdscript
# Player example
@onready var sprite: AnimatedSprite2D = $Sprite
func _ready():
    sprite.sprite_frames = load("res://assets_v2/godot/player_frames.tres")

func play_idle():  sprite.play("player_idle")
func play_attack(): sprite.play("player_light_attack_1")
```

Animation names == the sheet file stems (e.g. `player_light_attack_1`,
`gate_warden_attack_2`, `corpse_beast_charge_windup`). Full list per character
is in `assets_v2/characters/<char>/frame_map.json` and `metadata.md`.

If you change a sheet's frame count, **re-run** `python3
assets_v2/tools/gen_metadata.py` to regenerate the `.tres` (it asserts sheet
size == `frames*fw × fh`).

---

## 5. Hitbox / timing sync via frame_map.json

Every character dir has `frame_map.json` with, per animation:

```json
{
  "phases": { "startup": [0,1,2,3], "active": [4,5], "recovery": [6,7] },
  "pivot": [48, 66],
  "foot_position": [48, 88],
  "projectile_release_frame": null,   // ghost_archer_shoot -> 1
  "charge_ready_frame": null          // corpse_beast_charge_windup -> 5
}
```

- **`active`** = frames the hitbox / damage window should be ON.
- **`startup`** = telegraph (wind-up) — show a tell, no damage.
- **`recovery`** = can't act, vulnerable.
- **`projectile_release_frame`** = spawn the ghost arrow on this frame
  (ghost_archer_shoot = 1).
- **`pivot`** / **`foot_position`** = anchor the `AnimatedSprite2D` so the
  character's feet sit on the ground; offset the sprite via `centered = false`
  + `offset = -pivot` (or set `Sprite2D.offset`).

Example (player light attack 1): enable `Hitbox.monitoring` on frames 4–5,
disable otherwise.

---

## 6. AnimatedSprite2D offset (foot alignment)

Because the art is drawn with the feet near the bottom of the frame, set:
`centered = false`, and `offset = Vector2(-pivot.x, -foot_position.y)` so the
character's foot baseline lands on the node's origin. Per-character values:

| Character | frame | pivot | foot_y |
|---|---|---|---|
| player | 96×96 | (48,66) | 88 |
| melee_ghost | 96×96 | (48,70) | 90 |
| ghost_archer | 96×96 | (48,64) | 88 |
| corpse_beast | 128×96 | (64,58) | 86 |
| gate_warden | 192×192 | (96,128) | 176 |

---

## 7. Regenerating the art

From the repo root (Python 3.12 w/ Pillow required):

```bash
python3 assets_v2/tools/build_player.py
python3 assets_v2/tools/build_melee_ghost.py
python3 assets_v2/tools/build_ghost_archer.py
python3 assets_v2/tools/build_boss.py
python3 assets_v2/tools/build_corpse_beast.py
python3 assets_v2/tools/build_icons.py
python3 assets_v2/tools/build_projectiles.py
python3 assets_v2/tools/build_effects.py
python3 assets_v2/tools/build_design_bible.py     # concept/silhouette/contact/palette + comparisons
python3 assets_v2/tools/gen_metadata.py           # frame_map.json + metadata.md + .tres
```

The `.py` files are excluded from Godot import via `assets_v2/tools/.gdignore`.

---

## 8. Acceptance notes (for reviewers)

- Silhouettes are distinct (see `review/silhouette_comparison.png`): player =
  upright soldier w/ red cloth; melee ghost = top-heavy hunched; archer =
  tall thin w/ big bow; corpse beast = low wide quadruped; warden = colossal
  asymmetric pauldrons + great helm.
- Scale ladder (see `review/character_scale_comparison.png`): player ≈ 1.0×
  body, ghosts ≈ same height but different bulk, corpse beast ~0.6× height but
  wide, boss ≈ 2.5–3× player.
- Every animation frame is a genuinely different pose; feet baseline is stable;
  weapon length is constant across a character's frames.
