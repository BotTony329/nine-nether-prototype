#!/usr/bin/env python3
"""Generate Godot SpriteFrames resources from the art pipeline's sprite sheets.

The frame counts, frame sizes, FPS and loop flags below are transcribed from
`docs/ART_SPEC.md` section 7 and the per-directory `metadata.md` files, which
are the art pipeline's source of truth. Writing the resources by hand would mean
~70 AtlasTexture blocks maintained by copy-paste; generating them means the
frame table exists once and the .tres files can be regenerated whenever
WorkBuddy replaces a sheet.

Usage (from the repository root):

    python3 tools/generate_sprite_frames.py

The generated .tres files are committed. Re-run and commit the diff if a sheet's
frame count changes.
"""

from __future__ import annotations

import pathlib
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent

# actor -> (output path, frame width, frame height,
#           [(animation, sheet, source-frame indices, fps, loop)])
#
# Animation names remain the gameplay framework's established names.  Art V3
# calls locomotion "walk" in metadata, while the state machines call it "run".
ACTORS = {
    "player": (
        "assets_v3/godot/player_frames.tres",
        192,
        160,
        [
            ("player_idle", "assets_v3/production/player/player_idle.png", [0, 1, 2, 3], 6.0, True),
            ("player_run", "assets_v3/production/player/player_walk.png", [0, 1, 2, 3, 4, 5], 10.0, True),
            # Sprint 01 has no V3 jump/fall set. Reuse distinct idle pairs so
            # develop's rising/falling animation contract remains available.
            ("player_jump", "assets_v3/production/player/player_idle.png", [0, 1], 10.0, False),
            ("player_fall", "assets_v3/production/player/player_idle.png", [2, 3], 10.0, False),
            # Develop gates the hitbox on frames 4-5. Repeat each approved V3
            # pose twice to retain the eight-frame startup/active/recovery map.
            ("player_light_attack_1", "assets_v3/production/player/player_attack.png", [0, 0, 1, 1, 2, 2, 3, 3], 12.0, False),
            ("player_light_attack_2", "assets_v3/production/player/player_attack.png", [0, 0, 1, 1, 2, 2, 3, 3], 12.0, False),
            ("player_heavy_attack", "assets_v3/production/player/player_attack.png", [0, 0, 1, 1, 2, 2, 3, 3], 10.0, False),
            ("player_hurt", "assets_v3/production/player/player_hurt.png", [0, 1], 8.0, False),
            ("player_death", "assets_v3/production/player/player_death.png", [0, 1, 2, 3, 4, 5], 8.0, False),
        ],
    ),
    "ghost_melee": (
        "assets_v3/godot/melee_ghost_frames.tres",
        192,
        160,
        [
            ("melee_ghost_idle", "assets_v3/production/ghost_melee/ghost_melee_idle.png", [0, 1, 2, 3], 6.0, True),
            ("melee_ghost_walk", "assets_v3/production/ghost_melee/ghost_melee_walk.png", [0, 1, 2, 3, 4, 5], 9.0, True),
            ("melee_ghost_attack", "assets_v3/production/ghost_melee/ghost_melee_attack.png", [0, 0, 1, 1, 2, 2, 3, 3], 10.0, False),
            ("melee_ghost_hurt", "assets_v3/production/ghost_melee/ghost_melee_hurt.png", [0, 1], 8.0, False),
            ("melee_ghost_death", "assets_v3/production/ghost_melee/ghost_melee_death.png", [0, 1, 2, 3], 7.0, False),
        ],
    ),
    "ghost_archer": (
        "assets_v3/godot/ghost_archer_frames.tres",
        192,
        160,
        [
            ("ghost_archer_idle", "assets_v3/production/ghost_archer/ghost_archer_idle.png", [0, 1, 2, 3], 6.0, True),
            ("ghost_archer_retreat", "assets_v3/production/ghost_archer/ghost_archer_walk.png", [0, 1, 2, 3, 4, 5], 9.0, True),
            ("ghost_archer_aim", "assets_v3/production/ghost_archer/ghost_archer_attack.png", [0, 0, 1, 1, 1, 1], 8.0, False),
            ("ghost_archer_shoot", "assets_v3/production/ghost_archer/ghost_archer_attack.png", [1, 2, 2, 3], 14.0, False),
            ("ghost_archer_hurt", "assets_v3/production/ghost_archer/ghost_archer_hurt.png", [0, 1], 8.0, False),
            ("ghost_archer_death", "assets_v3/production/ghost_archer/ghost_archer_death.png", [0, 1, 2, 3], 7.0, False),
        ],
    ),
    "boss": (
        "assets_v3/godot/gate_warden_frames.tres",
        320,
        256,
        [
            ("gate_warden_idle", "assets_v3/production/gate_warden/gate_warden_idle.png", [0, 1, 2, 3], 5.0, True),
            ("gate_warden_walk", "assets_v3/production/gate_warden/gate_warden_walk.png", [0, 1, 2, 3, 4, 5], 7.0, True),
            ("gate_warden_attack_1", "assets_v3/production/gate_warden/gate_warden_attack.png", [0, 0, 1, 1, 2, 2, 3, 3, 4, 4], 9.0, False),
            ("gate_warden_attack_2", "assets_v3/production/gate_warden/gate_warden_attack.png", [0, 0, 1, 1, 2, 2, 3, 3, 4, 4], 8.0, False),
            ("gate_warden_hurt", "assets_v3/production/gate_warden/gate_warden_hurt.png", [0, 1], 7.0, False),
            ("gate_warden_death", "assets_v3/production/gate_warden/gate_warden_death.png", [0, 1, 2, 3, 4, 5, 6, 7], 6.0, False),
        ],
    ),
}

HEADER = (
    "; Generated by tools/generate_sprite_frames.py from docs/ART_SPEC.md.\n"
    "; Do not hand-edit: re-run the generator instead.\n"
)


def verify_sheet(sheet: pathlib.Path, frame_indices: list[int], width: int, height: int) -> None:
    """Fail loudly if a sheet does not match the frame table."""
    try:
        from PIL import Image  # optional; skip verification when unavailable
    except ImportError:
        return
    with Image.open(sheet) as image:
        source_frames = max(frame_indices) + 1
        expected = (source_frames * width, height)
        if image.height != height or image.width < expected[0] or image.width % width != 0:
            raise SystemExit(
                f"{sheet.relative_to(REPO_ROOT)} is {image.size}, "
                f"expected at least {expected} for indices {frame_indices} at {width}x{height}"
            )


def build(actor: str) -> str:
    output_path, frame_w, frame_h, animations = ACTORS[actor]
    ext_lines: list[str] = []
    sub_lines: list[str] = []
    animation_entries: list[str] = []

    for index, (anim, sheet, frame_indices, fps, loop) in enumerate(animations):
        verify_sheet(REPO_ROOT / sheet, frame_indices, frame_w, frame_h)
        ext_id = f"{index + 1}_{anim}"
        ext_lines.append(
            f'[ext_resource type="Texture2D" path="res://{sheet}" id="{ext_id}"]'
        )
        frame_refs = []
        for frame, source_frame in enumerate(frame_indices):
            sub_id = f"AtlasTexture_{anim}_{frame}"
            sub_lines.append(
                f'[sub_resource type="AtlasTexture" id="{sub_id}"]\n'
                f'atlas = ExtResource("{ext_id}")\n'
                f"region = Rect2({source_frame * frame_w}, 0, {frame_w}, {frame_h})"
            )
            frame_refs.append(
                '{\n"duration": 1.0,\n'
                f'"texture": SubResource("{sub_id}")\n'
                "}"
            )
        animation_entries.append(
            "{\n"
            f'"frames": [{", ".join(frame_refs)}],\n'
            f'"loop": {"true" if loop else "false"},\n'
            f'"name": &"{anim}",\n'
            f'"speed": {fps}\n'
            "}"
        )

    load_steps = len(ext_lines) + len(sub_lines) + 1
    body = [
        HEADER + f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]',
        "",
        "\n".join(ext_lines),
        "",
        "\n\n".join(sub_lines),
        "",
        "[resource]",
        "animations = [" + ", ".join(animation_entries) + "]",
        "",
    ]
    return "\n".join(body)


def main() -> int:
    for actor in ACTORS:
        output_path = REPO_ROOT / ACTORS[actor][0]
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(build(actor), encoding="utf-8")
        print(f"wrote {output_path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
