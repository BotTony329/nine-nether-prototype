#!/usr/bin/env python3
"""Nine Nether V2 — Ghost Archer (鬼弓手).

Tall, thin, rear-leaning spectral archer. Long asymmetrical bow with ghost-fire
arrows. Distinct silhouette: vertical height, big bow arc, slender legs.
"""

from __future__ import annotations
from pathlib import Path
from pixel_engine import bake_sheet
from humanoid import humanoid_config, render_humanoid

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets_v2" / "characters" / "ghost_archer"

ARCHER_CFG = humanoid_config(
    fw=96, fh=96, cx=48, hip_y=64, torso_len=29, neck_len=6, head_r=8,
    upper_arm=19, lower_arm=17, arm_w=3, thigh=20, shin=18, leg_w=4,
    scale=1.05, lean=-4, stance=3, style="ghost_archer", torso_hw=7, torso_hw_hip=5,
    bow_len=44, ghost_fire=True, pauldrons=False,
    palette={
        "skin": (105, 115, 110), "skin_lt": (132, 145, 138), "skin_sh": (74, 84, 78),
        "armor": (64, 76, 82), "armor_lt": (95, 110, 118), "armor_dk": (40, 50, 54),
        "cloth": (58, 72, 68), "cloth_lt": (82, 98, 92), "cloth_dk": (38, 48, 44),
        "wood": (72, 58, 48), "wood_lt": (100, 82, 68),
        "blade": (90, 80, 70), "blade_lt": (120, 108, 95), "blade_dk": (62, 54, 46),
        "grip": (58, 48, 38), "guard": (88, 74, 58),
        "outline": (12, 16, 18),
    },
)

A = lambda sa, ea: (sa, ea)

# Idle: tall thin stance, >=3px bob steps, ghost-fire flicker. No dup frames.
IDLE = [
    {"bob": 0, "arm_front": A(50, 160), "arm_back": A(130, 110), "leg_front": A(92, 90), "leg_back": A(88, 92), "aim": 0.0, "fire_t": 0.0},
    {"bob": 3, "arm_front": A(49, 160), "arm_back": A(131, 110), "leg_front": A(91, 91), "leg_back": A(89, 92), "aim": 0.0, "fire_t": 0.2},
    {"bob": 6, "arm_front": A(48, 160), "arm_back": A(132, 110), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 0.0, "fire_t": 0.4},
    {"bob": 3, "arm_front": A(49, 160), "arm_back": A(131, 110), "leg_front": A(91, 91), "leg_back": A(89, 92), "aim": 0.0, "fire_t": 0.6},
    {"bob": 0, "arm_front": A(50, 160), "arm_back": A(130, 110), "leg_front": A(92, 90), "leg_back": A(88, 92), "aim": 0.0, "fire_t": 0.8},
    {"bob": 3, "arm_front": A(49, 160), "arm_back": A(131, 110), "leg_front": A(91, 91), "leg_back": A(89, 92), "aim": 0.0, "fire_t": 0.95},
]

RETREAT = [
    {"bob": 0, "arm_front": A(55, 160), "arm_back": A(125, 110), "leg_front": A(95, 92), "leg_back": A(85, 95), "aim": 0.1, "fire_t": 0.0},
    {"bob": 0, "arm_front": A(54, 160), "arm_back": A(126, 110), "leg_front": A(100, 90), "leg_back": A(80, 100), "aim": 0.1, "fire_t": 0.12},
    {"bob": 1, "arm_front": A(53, 160), "arm_back": A(127, 110), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 0.1, "fire_t": 0.25},
    {"bob": 1, "arm_front": A(54, 160), "arm_back": A(126, 110), "leg_front": A(80, 100), "leg_back": A(100, 90), "aim": 0.1, "fire_t": 0.37},
    {"bob": 0, "arm_front": A(55, 160), "arm_back": A(125, 110), "leg_front": A(85, 95), "leg_back": A(95, 92), "aim": 0.1, "fire_t": 0.5},
    {"bob": 0, "arm_front": A(54, 160), "arm_back": A(126, 110), "leg_front": A(80, 100), "leg_back": A(100, 90), "aim": 0.1, "fire_t": 0.62},
    {"bob": 1, "arm_front": A(53, 160), "arm_back": A(127, 110), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 0.1, "fire_t": 0.75},
    {"bob": 1, "arm_front": A(54, 160), "arm_back": A(126, 110), "leg_front": A(100, 90), "leg_back": A(80, 100), "aim": 0.1, "fire_t": 0.87},
]

AIM = [
    {"bob": 0, "arm_front": A(45, 165), "arm_back": A(135, 115), "leg_front": A(92, 90), "leg_back": A(88, 92), "aim": 0.0, "fire_t": 0.0},
    {"bob": 0, "arm_front": A(42, 168), "arm_back": A(138, 108), "leg_front": A(91, 91), "leg_back": A(89, 92), "aim": 0.25, "fire_t": 0.15},
    {"bob": 1, "arm_front": A(38, 170), "arm_back": A(142, 100), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 0.5, "fire_t": 0.3},
    {"bob": 1, "arm_front": A(35, 172), "arm_back": A(145, 95), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 0.75, "fire_t": 0.45},
    {"bob": 1, "arm_front": A(32, 175), "arm_back": A(148, 90), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 1.0, "fire_t": 0.6},
    {"bob": 0, "arm_front": A(32, 175), "arm_back": A(148, 90), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 1.0, "fire_t": 0.75},
]

SHOOT = [
    {"bob": 0, "arm_front": A(32, 175), "arm_back": A(148, 90), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 1.0, "fire_t": 0.0},
    {"bob": 0, "arm_front": A(40, 170), "arm_back": A(120, 100), "leg_front": A(90, 92), "leg_back": A(90, 92), "aim": 0.4, "fire_t": 0.2},
    {"bob": 1, "arm_front": A(48, 165), "arm_back": A(110, 110), "leg_front": A(91, 91), "leg_back": A(89, 92), "aim": 0.05, "fire_t": 0.4},
    {"bob": 0, "arm_front": A(50, 160), "arm_back": A(115, 108), "leg_front": A(92, 90), "leg_back": A(88, 92), "aim": 0.0, "fire_t": 0.6},
]

HURT = [
    {"bob": 0, "arm_front": A(60, 150), "arm_back": A(120, 120), "leg_front": A(95, 90), "leg_back": A(85, 95), "aim": 0.0, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(70, 140), "arm_back": A(110, 130), "leg_front": A(100, 92), "leg_back": A(80, 98), "aim": 0.0, "fire_t": 0.2},
    {"bob": 1, "arm_front": A(65, 145), "arm_back": A(115, 125), "leg_front": A(98, 91), "leg_back": A(82, 96), "aim": 0.0, "fire_t": 0.4},
    {"bob": 0, "arm_front": A(55, 155), "arm_back": A(125, 115), "leg_front": A(94, 90), "leg_back": A(86, 94), "aim": 0.0, "fire_t": 0.6},
]

DEATH = [
    {"bob": 0, "arm_front": A(55, 155), "arm_back": A(125, 115), "leg_front": A(94, 90), "leg_back": A(86, 94), "aim": 0.0, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(70, 140), "arm_back": A(110, 130), "leg_front": A(98, 92), "leg_back": A(82, 98), "aim": 0.0, "fire_t": 0.1},
    {"bob": 2, "arm_front": A(85, 130), "arm_back": A(95, 140), "leg_front": A(102, 94), "leg_back": A(78, 102), "aim": 0.0, "fire_t": 0.2},
    {"bob": 3, "arm_front": A(95, 125), "arm_back": A(85, 145), "leg_front": A(105, 98), "leg_back": A(75, 108), "aim": 0.0, "fire_t": 0.3},
    {"bob": 4, "arm_front": A(105, 120), "arm_back": A(75, 150), "leg_front": A(100, 105), "leg_back": A(80, 112), "aim": 0.0, "fire_t": 0.4},
    {"bob": 5, "arm_front": A(110, 115), "arm_back": A(70, 155), "leg_front": A(95, 110), "leg_back": A(85, 115), "aim": 0.0, "fire_t": 0.5},
    {"bob": 6, "arm_front": A(115, 110), "arm_back": A(65, 160), "leg_front": A(90, 115), "leg_back": A(90, 118), "aim": 0.0, "fire_t": 0.6},
    {"bob": 7, "arm_front": A(120, 105), "arm_back": A(60, 165), "leg_front": A(90, 118), "leg_back": A(90, 120), "aim": 0.0, "fire_t": 0.7},
]

ANIMS = {
    "ghost_archer_idle": (IDLE, 8.0, True),
    "ghost_archer_retreat": (RETREAT, 10.0, True),
    "ghost_archer_aim": (AIM, 8.0, False),
    "ghost_archer_shoot": (SHOOT, 14.0, False),
    "ghost_archer_hurt": (HURT, 10.0, False),
    "ghost_archer_death": (DEATH, 8.0, False),
}


def build():
    for name, (poses, fps, loop) in ANIMS.items():
        fw, fh = ARCHER_CFG["fw"], ARCHER_CFG["fh"]
        bake_sheet(fw, fh, len(poses),
                   lambda d, i, fw, fh, poses=poses: render_humanoid(d, ARCHER_CFG, poses[i], fw, fh),
                   str(OUT / f"{name}.png"))
        print(f"  ✓ {name}.png  ({len(poses)} frames)")


if __name__ == "__main__":
    build()
