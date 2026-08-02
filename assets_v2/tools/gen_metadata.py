#!/usr/bin/env python3
"""Nine Nether V2 — Generate frame_map.json, metadata.md, and Godot .tres.

Run from repo root:  python3 assets_v2/tools/gen_metadata.py

Produces, per character directory:
  * frame_map.json   — startup/active/recovery phases, pivot, foot_position,
                       projectile_release_frame / charge_ready_frame.
  * metadata.md      — human-readable animation + spec sheet.
And into assets_v2/godot/:
  * <char>_frames.tres — SpriteFrames resources (mirror of tools/generate_sprite_frames.py
    but for assets_v2 paths/sizes; AtlasTexture + horizontal strips).

Phase boundaries are transcribed from the pose comments in the build_*.py files.
"""

from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CHAR_DIR = ROOT / "assets_v2" / "characters"
GODOT_DIR = ROOT / "assets_v2" / "godot"

# fmt: char -> dict(frame_w, frame_h, pivot, foot, anims)
# anim -> dict(frames, fps, loop, startup, active, recovery, projectile_release_frame,
#              charge_ready_frame, note)
CHARS = {
    "player": {
        "frame_w": 96, "frame_h": 96, "pivot": [48, 66], "foot": [48, 88],
        "anims": {
            "player_idle":         (8, 8.0, True,  [], [], [], None, None, "breathing idle"),
            "player_run":          (8, 12.0, True, [], [], [], None, None, "forward run, cloth trailing"),
            "player_jump":         (3, 10.0, False, [], [], [], None, None, "rise"),
            "player_fall":         (3, 10.0, False, [], [], [], None, None, "descent"),
            "player_light_attack_1": (8, 12.0, False, [0,1,2,3], [4,5], [6,7], None, None, "horizontal sabre slash R->L"),
            "player_light_attack_2": (8, 12.0, False, [0,1,2,3], [4,5], [6,7], None, None, "reverse diagonal overhead->back"),
            "player_heavy_attack": (10, 10.0, False, [0,1,2,3,4,5], [6,7], [8,9], None, None, "deep coil, late big hit"),
            "player_hurt":         (4, 10.0, False, [], [], [], None, None, "recoil"),
            "player_death":        (10, 8.0, False, [], [], [], None, None, "stagger and collapse"),
        },
    },
    "melee_ghost": {
        "frame_w": 96, "frame_h": 96, "pivot": [48, 70], "foot": [48, 90],
        "anims": {
            "melee_ghost_idle":    (6, 8.0, True,  [], [], [], None, None, "hunched sway, ghost fire leak"),
            "melee_ghost_walk":    (8, 8.0, True,  [], [], [], None, None, "lumbering gait"),
            "melee_ghost_attack":  (8, 10.0, False, [0,1,2,3], [4,5], [6,7], None, None, "overhead slam"),
            "melee_ghost_hurt":    (4, 10.0, False, [], [], [], None, None, "recoil"),
            "melee_ghost_death":   (8, 8.0, False,  [], [], [], None, None, "dissolve"),
        },
    },
    "ghost_archer": {
        "frame_w": 96, "frame_h": 96, "pivot": [48, 64], "foot": [48, 88],
        "anims": {
            "ghost_archer_idle":    (6, 8.0, True,  [], [], [], None, None, "still draw, ghost fire"),
            "ghost_archer_retreat": (8, 10.0, True, [], [], [], None, None, "back-step kiting"),
            "ghost_archer_aim":     (6, 8.0, False, [0,1,2,3,4], [], [5], None, 5, "draw bow, charge_ready at 5"),
            "ghost_archer_shoot":   (4, 14.0, False, [0], [1], [2,3], 1, None, "release; projectile at frame 1"),
            "ghost_archer_hurt":    (4, 10.0, False, [], [], [], None, None, "recoil"),
            "ghost_archer_death":   (8, 8.0, False,  [], [], [], None, None, "dissolve"),
        },
    },
    "corpse_beast": {
        "frame_w": 128, "frame_h": 96, "pivot": [64, 58], "foot": [64, 86],
        "anims": {
            "corpse_beast_idle":        (6, 5.0, True,  [], [], [], None, None, "low breathing"),
            "corpse_beast_run":         (8, 10.0, True, [], [], [], None, None, "gallop"),
            "corpse_beast_charge_windup": (6, 8.0, False, [0,1,2,3,4], [], [5], None, 5, "coil; charge_ready at 5"),
            "corpse_beast_charge":      (4, 12.0, False, [], [0,1,2,3], [], None, None, "full-speed contact"),
            "corpse_beast_wall_impact": (4, 8.0, False, [], [0,1], [2,3], None, None, "slam into wall"),
            "corpse_beast_hurt":        (4, 10.0, False, [], [], [], None, None, "scramble"),
            "corpse_beast_death":       (8, 6.0, False,  [], [], [], None, None, "collapse"),
        },
    },
    "gate_warden": {
        "frame_w": 192, "frame_h": 192, "pivot": [96, 128], "foot": [96, 176],
        "anims": {
            "gate_warden_idle":     (8, 6.0, True,  [], [], [], None, None, "heavy breathing"),
            "gate_warden_walk":     (8, 8.0, True,  [], [], [], None, None, "earth-shaking steps"),
            "gate_warden_attack_1": (10, 9.0, False, [0,1,2,3], [4,5], [6,7,8,9], None, None, "horizontal great-blade sweep"),
            "gate_warden_attack_2": (12, 8.0, False, [0,1,2,3,4,5], [6,7], [8,9,10,11], None, None, "overhead ground pound"),
            "gate_warden_hurt":     (4, 8.0, False,  [], [], [], None, None, "recoil"),
            "gate_warden_death":    (12, 6.0, False, [], [], [], None, None, "colossal collapse"),
        },
    },
}


def write_frame_maps():
    for char, spec in CHARS.items():
        anims = {}
        for name, (frames, fps, loop, startup, active, recovery, proj, ready, note) in spec["anims"].items():
            anims[name] = {
                "frames": frames,
                "fps": fps,
                "loop": loop,
                "phases": {
                    "startup": startup,
                    "active": active,
                    "recovery": recovery,
                },
                "pivot": spec["pivot"],
                "foot_position": spec["foot"],
                "frame_size": [spec["frame_w"], spec["frame_h"]],
                "projectile_release_frame": proj,
                "charge_ready_frame": ready,
                "note": note,
            }
        data = {
            "character": char,
            "frame_size": [spec["frame_w"], spec["frame_h"]],
            "pivot": spec["pivot"],
            "foot_position": spec["foot"],
            "animations": anims,
        }
        out = CHAR_DIR / char / "frame_map.json"
        out.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"  ok {char}/frame_map.json  ({len(anims)} anims)")


def write_metadata():
    for char, spec in CHARS.items():
        lines = [f"# {char} — Animation & Spec Sheet (V2)", ""]
        lines.append(f"- **Frame size:** {spec['frame_w']}x{spec['frame_h']} px")
        lines.append(f"- **Pivot (rotation/hitbox anchor):** {spec['pivot']}")
        lines.append(f"- **Foot baseline (y):** {spec['foot'][1]}")
        lines.append("")
        lines.append("| Animation | Frames | FPS | Loop | Startup | Active | Recovery | Proj/Charge |")
        lines.append("|---|---|---|---|---|---|---|---|")
        for name, (frames, fps, loop, startup, active, recovery, proj, ready, note) in spec["anims"].items():
            su = ",".join(map(str, startup)) or "-"
            ac = ",".join(map(str, active)) or "-"
            rc = ",".join(map(str, recovery)) or "-"
            pc = proj if proj is not None else (f"ready@{ready}" if ready is not None else "-")
            lines.append(f"| {name} | {frames} | {fps} | {loop} | {su} | {ac} | {rc} | {pc} |")
        lines.append("")
        lines.append("**Legend:** frames are 0-indexed. `Active` = hitbox/projectile window. "
                     "`projectile_release_frame` = frame the ghost arrow spawns. "
                     "`charge_ready_frame` = frame a charge/aim state is fully wound (transition out).")
        lines.append("")
        lines.append(f"Generated by `assets_v2/tools/gen_metadata.py`. Source: pose comments in "
                     f"`assets_v2/tools/build_*.py`.")
        out = CHAR_DIR / char / "metadata.md"
        out.write_text("\n".join(lines), encoding="utf-8")
        print(f"  ok {char}/metadata.md")


# ── V2 SpriteFrames .tres (mirror of tools/generate_sprite_frames.py) ────────
HEADER = (
    "; Generated by assets_v2/tools/gen_metadata.py for the V2 (Steam Alpha) art set.\n"
    "; Do not hand-edit: re-run the generator instead.\n"
)


def build_tres(char: str, spec: dict) -> str:
    fw, fh = spec["frame_w"], spec["frame_h"]
    anims = spec["anims"]
    ext_lines, sub_lines, entries = [], [], []
    for idx, (name, (frames, fps, loop, *_)) in enumerate(anims.items()):
        ext_id = f"{idx + 1}_{name}"
        sheet = f"assets_v2/characters/{char}/{name}.png"
        ext_lines.append(f'[ext_resource type="Texture2D" path="res://{sheet}" id="{ext_id}"]')
        refs = []
        for f in range(frames):
            sub_id = f"AtlasTexture_{name}_{f}"
            sub_lines.append(
                f'[sub_resource type="AtlasTexture" id="{sub_id}"]\n'
                f'atlas = ExtResource("{ext_id}")\n'
                f"region = Rect2({f * fw}, 0, {fw}, {fh})"
            )
            refs.append('{\n"duration": 1.0,\n' f'"texture": SubResource("{sub_id}")\n}}')
        entries.append(
            "{\n" + f'"frames": [{", ".join(refs)}],\n'
            f'"loop": {"true" if loop else "false"},\n'
            f'"name": &"{name}",\n' f'"speed": {fps}\n}}'
        )
    load_steps = len(ext_lines) + len(sub_lines) + 1
    return "\n".join([
        HEADER + f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]',
        "", "\n".join(ext_lines), "", "\n\n".join(sub_lines), "",
        "[resource]", "animations = [" + ", ".join(entries) + "]", "",
    ])


def write_tres():
    GODOT_DIR.mkdir(parents=True, exist_ok=True)
    for char, spec in CHARS.items():
        out = GODOT_DIR / f"{char}_frames.tres"
        out.write_text(build_tres(char, spec), encoding="utf-8")
        print(f"  ok godot/{char}_frames.tres")


if __name__ == "__main__":
    print("frame_map.json:")
    write_frame_maps()
    print("metadata.md:")
    write_metadata()
    print(".tres:")
    write_tres()
    print("done.")
