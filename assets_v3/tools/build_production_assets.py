#!/usr/bin/env python3
"""Build Godot-ready Art V3 assets from the approved production master sheets.

The source sheets are already chroma-keyed to RGBA.  This script only performs
deterministic cropping, nearest-neighbour pixel scaling, foot-baseline
normalisation, strip assembly, and metadata generation.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets_v3" / "production" / "source"
OUTPUT = ROOT / "assets_v3" / "production"

ANIMATIONS = ("idle", "walk", "attack", "hurt", "death")


CHARACTERS = {
    "player": {
        "source": "player_master.png",
        "frame_size": (192, 160),
        "foot_y": 150,
        "target_height": 144,
        "fps": {"idle": 6, "walk": 10, "attack": 12, "hurt": 8, "death": 8},
        "rows": {
            "idle": ((18, 202), [(36, 163), (224, 351), (412, 539), (602, 731)]),
            "walk": ((221, 397), [(49, 174), (238, 370), (418, 554), (622, 732), (801, 917), (1026, 1127)]),
            "attack": ((421, 595), [(33, 154), (246, 389), (449, 633), (670, 856)]),
            "hurt": ((614, 747), [(33, 171), (250, 387)]),
            "death": ((771, 905), [(40, 152), (264, 380), (459, 611), (690, 868), (938, 1111), (1181, 1354)]),
        },
        "events": {"attack": {"hit_frame": 2, "recovery_frame": 3}},
    },
    "ghost_melee": {
        "source": "ghost_melee_master.png",
        "frame_size": (192, 160),
        "foot_y": 150,
        "target_height": 144,
        "fps": {"idle": 6, "walk": 9, "attack": 10, "hurt": 8, "death": 7},
        "rows": {
            # The approved board contains three unique idle poses.  The first is
            # repeated to retain the framework's four-frame idle timing.
            "idle": ((19, 236), [(104, 246), (314, 455), (524, 665), (524, 665)]),
            "walk": ((250, 464), [(111, 270), (332, 491), (549, 696), (784, 941), (1010, 1166), (1223, 1381)]),
            "attack": ((473, 675), [(131, 330), (438, 561), (657, 900), (1002, 1184)]),
            "hurt": ((688, 856), [(150, 292), (396, 524)]),
            "death": ((869, 995), [(127, 308), (389, 612), (697, 979), (1027, 1289)]),
        },
        "events": {"attack": {"hit_frame": 2, "recovery_frame": 3}},
    },
    "ghost_archer": {
        "source": "ghost_archer_master.png",
        "frame_size": (192, 160),
        "foot_y": 150,
        "target_height": 144,
        "fps": {"idle": 6, "walk": 9, "attack": 10, "hurt": 8, "death": 7},
        "rows": {
            "idle": ((47, 373), [(42, 220), (266, 444), (490, 667), (697, 875)]),
            "walk": ((424, 686), [(16, 143), (180, 307), (347, 479), (523, 657), (691, 817), (860, 989)]),
            "attack": ((733, 1028), [(16, 184), (253, 422), (449, 696), (795, 962)]),
            "hurt": ((1069, 1279), [(46, 165), (257, 386)]),
            "death": ((1332, 1487), [(43, 189), (284, 456), (531, 715), (787, 1001)]),
        },
        "events": {"attack": {"projectile_frame": 2, "recovery_frame": 3}},
    },
    "gate_warden": {
        "source": "gate_warden_master.png",
        "frame_size": (320, 256),
        "foot_y": 248,
        "target_height": 236,
        "fps": {"idle": 5, "walk": 7, "attack": 9, "hurt": 7, "death": 6},
        "rows": {
            "idle": ((10, 221), [(175, 354), (365, 543), (550, 720), (550, 720)]),
            "walk": ((221, 418), [(170, 350), (360, 540), (550, 720), (725, 910), (915, 1110), (1115, 1310)]),
            "attack": ((418, 630), [(150, 350), (350, 575), (575, 815), (815, 1055), (1055, 1280)]),
            "hurt": ((630, 805), [(135, 315), (315, 625)]),
            # Seven unique collapse poses are present; repeat the settled final
            # pose so the existing eight-frame death timing remains unchanged.
            "death": ((805, 952), [(20, 270), (285, 520), (535, 750), (760, 1000), (995, 1220), (1210, 1430), (1420, 1652), (1420, 1652)]),
        },
        "events": {"attack": {"hit_frame": 2, "recovery_frame": 4}},
    },
}


EFFECTS = {
    "slash": ((86, 183), [(132, 324), (477, 702), (829, 1076), (1183, 1435)], (96, 64), 12),
    "hit": ((267, 369), [(192, 293), (528, 637), (905, 1009), (1240, 1360)], (64, 64), 16),
    "blood": ((448, 538), [(126, 349), (496, 709), (866, 1046), (1198, 1367)], (96, 64), 14),
    "ghost_fire": ((602, 734), [(176, 241), (404, 471), (632, 700), (863, 928), (1090, 1154), (1312, 1380)], (64, 64), 10),
    "death": ((793, 946), [(166, 251), (394, 481), (622, 709), (849, 937), (1080, 1164), (1304, 1392)], (64, 80), 10),
}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Frame contains no visible pixels")
    return bbox


def crop_frame(master: Image.Image, y_range: tuple[int, int], x_range: tuple[int, int]) -> Image.Image:
    frame = master.crop((x_range[0], y_range[0], x_range[1], y_range[1]))
    return frame.crop(alpha_bbox(frame))


def place_frame(frame: Image.Image, size: tuple[int, int], scale: float, baseline: int) -> Image.Image:
    width = max(1, round(frame.width * scale))
    height = max(1, round(frame.height * scale))
    if width > size[0] - 4:
        fit = (size[0] - 4) / width
        width = max(1, round(width * fit))
        height = max(1, round(height * fit))
    resized = frame.resize((width, height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", size)
    x = (size[0] - width) // 2
    y = baseline - height
    canvas.alpha_composite(resized, (x, y))
    # Nearest-neighbour reduction can discard a sparse final alpha row. Measure
    # the composed result and snap its actual lowest visible pixel to baseline.
    visible = alpha_bbox(canvas)
    if visible[3] != baseline:
        snapped = Image.new("RGBA", size)
        snapped.alpha_composite(canvas, (0, baseline - visible[3]))
        canvas = snapped
    return canvas


def write_strip(path: Path, frames: list[Image.Image], frame_size: tuple[int, int]) -> None:
    strip = Image.new("RGBA", (frame_size[0] * len(frames), frame_size[1]))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * frame_size[0], 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    strip.save(path, optimize=True)


def build_characters() -> None:
    for character, spec in CHARACTERS.items():
        master = Image.open(SOURCE / spec["source"]).convert("RGBA")
        destination = OUTPUT / character
        frame_map: dict[str, object] = {
            "character": character,
            "frame_size": list(spec["frame_size"]),
            "pivot": [spec["frame_size"][0] // 2, spec["foot_y"]],
            "foot_position": [spec["frame_size"][0] // 2, spec["foot_y"]],
            "animations": {},
        }
        for animation in ANIMATIONS:
            y_range, x_ranges = spec["rows"][animation]
            crops = [crop_frame(master, y_range, x_range) for x_range in x_ranges]
            scale = spec["target_height"] / crops[0].height
            frames = [place_frame(crop, spec["frame_size"], scale, spec["foot_y"]) for crop in crops]
            write_strip(destination / f"{character}_{animation}.png", frames, spec["frame_size"])
            events = spec.get("events", {}).get(animation, {})
            frame_map["animations"][animation] = {
                "frames": len(frames),
                "fps": spec["fps"][animation],
                "loop": animation in ("idle", "walk"),
                **events,
            }
        destination.mkdir(parents=True, exist_ok=True)
        (destination / "frame_map.json").write_text(json.dumps(frame_map, indent=2) + "\n")
        (destination / "metadata.md").write_text(
            f"# {character.replace('_', ' ').title()} Production Metadata\n\n"
            f"- Frame size: `{spec['frame_size'][0]} x {spec['frame_size'][1]}`\n"
            f"- Pivot: `{spec['frame_size'][0] // 2}, {spec['foot_y']}`\n"
            f"- Foot position: `{spec['frame_size'][0] // 2}, {spec['foot_y']}`\n"
            "- Lighting: upper-left, approved Art V3 palette\n"
            "- Import: nearest filtering, no mipmaps, lossless RGBA\n"
            "- Baseline policy: all frames are bottom-anchored; death collapse retains the first death frame scale.\n\n"
            "Animation timing and combat event frames are recorded in `frame_map.json`.\n"
        )


def build_effects() -> None:
    master = Image.open(SOURCE / "effects_master.png").convert("RGBA")
    destination = OUTPUT / "effects"
    metadata: dict[str, object] = {"effects": {}}
    for name, (y_range, x_ranges, frame_size, fps) in EFFECTS.items():
        crops = [crop_frame(master, y_range, x_range) for x_range in x_ranges]
        scale = min((frame_size[0] - 4) / crops[0].width, (frame_size[1] - 4) / crops[0].height)
        frames = [place_frame(crop, frame_size, scale, frame_size[1] - 2) for crop in crops]
        write_strip(destination / f"{name}.png", frames, frame_size)
        metadata["effects"][name] = {"frame_size": list(frame_size), "frames": len(frames), "fps": fps}
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "frame_map.json").write_text(json.dumps(metadata, indent=2) + "\n")
    (destination / "metadata.md").write_text(
        "# Combat Effect Metadata\n\n"
        "Transparent RGBA pixel effects using the approved Art V3 palette. Frame sizes, counts, and FPS are in `frame_map.json`.\n"
    )


def fit_asset(master: Image.Image, box: tuple[int, int, int, int], size: tuple[int, int], baseline: bool = False) -> Image.Image:
    crop = master.crop(box)
    crop = crop.crop(alpha_bbox(crop))
    scale = min(size[0] / crop.width, size[1] / crop.height)
    resized = crop.resize((max(1, round(crop.width * scale)), max(1, round(crop.height * scale))), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", size)
    x = (size[0] - resized.width) // 2
    y = size[1] - resized.height if baseline else (size[1] - resized.height) // 2
    canvas.alpha_composite(resized, (x, y))
    return canvas


def build_environment_and_icons() -> None:
    environment = Image.open(SOURCE / "environment_master.png").convert("RGBA")
    env_out = OUTPUT / "environment"
    env_out.mkdir(parents=True, exist_ok=True)
    fit_asset(environment, (25, 335, 650, 640), (256, 128), True).save(env_out / "stone_floor.png")
    fit_asset(environment, (710, 195, 1185, 700), (256, 256), True).save(env_out / "stone_wall.png")
    fit_asset(environment, (1230, 95, 1890, 700), (384, 384), True).save(env_out / "fortress_gate.png")

    # Low-resolution deterministic alpha fog: presentation-only, no gameplay data.
    fog = Image.new("RGBA", (320, 96))
    pixels = fog.load()
    for y in range(fog.height):
        for x in range(fog.width):
            wave = ((x * 13 + y * 29 + (x // 17) * 31) % 73) / 72.0
            vertical = max(0.0, 1.0 - abs(y - 58) / 48.0)
            alpha = round(38 * wave * vertical)
            pixels[x, y] = (126, 157, 163, alpha)
    fog.save(env_out / "battlefield_fog.png", optimize=True)

    icons = Image.open(SOURCE / "icons_master.png").convert("RGBA")
    icon_out = OUTPUT / "icons"
    icon_out.mkdir(parents=True, exist_ok=True)
    for name, box in {
        "icon_hp": (245, 285, 570, 680),
        "icon_boss": (785, 145, 1120, 690),
        "icon_sacrifice": (1320, 230, 1700, 680),
    }.items():
        fit_asset(icons, box, (64, 64)).save(icon_out / f"{name}.png", optimize=True)
    (icon_out / "metadata.md").write_text(
        "# UI Icon Metadata\n\n64 x 64 transparent RGBA icons, nearest-filtered, approved Art V3 palette and upper-left lighting.\n"
    )

    projectile_out = OUTPUT / "projectiles"
    projectile_out.mkdir(parents=True, exist_ok=True)
    arrow = Image.new("RGBA", (32, 8))
    px = arrow.load()
    # Palette sampled from the approved Ghost Archer: dark iron shaft, aged
    # bronze fletching, and a restrained spectral-cyan arrowhead highlight.
    for x in range(4, 25):
        px[x, 3] = (55, 45, 38, 255)
        px[x, 4] = (109, 82, 50, 255)
    for x, y in ((1, 1), (2, 2), (3, 3), (1, 6), (2, 5), (3, 4)):
        px[x, y] = (123, 76, 49, 255)
    for x, y in ((25, 2), (26, 2), (27, 1), (28, 0), (25, 5), (26, 5), (27, 6), (28, 7)):
        px[x, y] = (77, 176, 146, 255)
    for x in range(25, 31):
        px[x, 3] = (177, 226, 187, 255)
        px[x, 4] = (91, 201, 164, 255)
    arrow.save(projectile_out / "ghost_arrow.png", optimize=True)
    (projectile_out / "metadata.md").write_text(
        "# Ghost Arrow Metadata\n\n- Size: `32 x 8`\n- Pivot: `16, 4`\n- Transparent RGBA; authored facing right; no animation, homing, or spread.\n"
    )


def main() -> None:
    build_characters()
    build_effects()
    build_environment_and_icons()
    print(f"Built Art V3 production assets in {OUTPUT}")


if __name__ == "__main__":
    main()
