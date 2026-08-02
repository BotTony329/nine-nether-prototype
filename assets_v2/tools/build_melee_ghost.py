#!/usr/bin/env python3
"""Nine Nether V2 — Melee Ghost (近战鬼卒).

Hunched, heavy, dragging a rusty blade. Asymmetric broad shoulders, damaged
leg, ghost fire leaking from helmet and chest gaps. Silhouette: top-heavy,
leaning forward, not upright like the player.
"""

from __future__ import annotations
from pathlib import Path
from pixel_engine import bake_sheet
from humanoid import humanoid_config, render_humanoid

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets_v2" / "characters" / "melee_ghost"

MELEE_CFG = humanoid_config(
    fw=96, fh=96, cx=48, hip_y=70, torso_len=24, neck_len=5, head_r=11,
    upper_arm=17, lower_arm=14, arm_w=5, thigh=16, shin=14, leg_w=6,
    scale=1.05, lean=14, stance=6, style="melee_ghost", torso_hw=11, torso_hw_hip=9,
    weapon_len=52, ghost_fire=True, pauldrons=True,
    palette={
        "skin": (100, 112, 118), "skin_lt": (125, 140, 148), "skin_sh": (68, 78, 84),
        "armor": (72, 80, 84), "armor_lt": (105, 116, 122), "armor_dk": (44, 50, 54),
        "cloth": (55, 65, 68), "cloth_lt": (78, 90, 94), "cloth_dk": (36, 44, 46),
        "blade": (92, 78, 62), "blade_lt": (125, 105, 84), "blade_dk": (62, 52, 40),
        "grip": (58, 48, 38), "guard": (88, 74, 58),
        "outline": (12, 16, 18),
    },
)

A = lambda sa, ea: (sa, ea)

# Idle: hunched breathing + ghost-fire flicker. >=3px bob steps, no dup frames.
IDLE = [
    {"bob": 0, "arm_front": A(105, 115), "arm_back": A(95, 105), "leg_front": A(94, 95), "leg_back": A(86, 100), "weapon": 112, "fire_t": 0.0},
    {"bob": 3, "arm_front": A(104, 116), "arm_back": A(96, 106), "leg_front": A(93, 96), "leg_back": A(87, 100), "weapon": 116, "fire_t": 0.2},
    {"bob": 6, "arm_front": A(103, 117), "arm_back": A(97, 107), "leg_front": A(92, 97), "leg_back": A(88, 100), "weapon": 120, "fire_t": 0.4},
    {"bob": 3, "arm_front": A(104, 116), "arm_back": A(96, 106), "leg_front": A(93, 96), "leg_back": A(87, 100), "weapon": 117, "fire_t": 0.6},
    {"bob": 0, "arm_front": A(105, 115), "arm_back": A(95, 105), "leg_front": A(94, 95), "leg_back": A(86, 100), "weapon": 114, "fire_t": 0.8},
    {"bob": 3, "arm_front": A(104, 116), "arm_back": A(96, 106), "leg_front": A(93, 96), "leg_back": A(87, 100), "weapon": 118, "fire_t": 0.95},
]

WALK = [
    {"bob": 0, "arm_front": A(102, 112), "arm_back": A(98, 108), "leg_front": A(75, 105), "leg_back": A(115, 95), "weapon": 113, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(104, 114), "arm_back": A(96, 106), "leg_front": A(85, 100), "leg_back": A(105, 98), "weapon": 114, "fire_t": 0.12},
    {"bob": 1, "arm_front": A(106, 116), "arm_back": A(94, 104), "leg_front": A(95, 95), "leg_back": A(95, 95), "weapon": 115, "fire_t": 0.25},
    {"bob": 0, "arm_front": A(104, 114), "arm_back": A(96, 106), "leg_front": A(105, 98), "leg_back": A(85, 100), "weapon": 114, "fire_t": 0.37},
    {"bob": 0, "arm_front": A(102, 112), "arm_back": A(98, 108), "leg_front": A(115, 95), "leg_back": A(75, 105), "weapon": 113, "fire_t": 0.5},
    {"bob": 1, "arm_front": A(104, 114), "arm_back": A(96, 106), "leg_front": A(105, 98), "leg_back": A(85, 100), "weapon": 114, "fire_t": 0.62},
    {"bob": 1, "arm_front": A(106, 116), "arm_back": A(94, 104), "leg_front": A(95, 95), "leg_back": A(95, 95), "weapon": 115, "fire_t": 0.75},
    {"bob": 0, "arm_front": A(104, 114), "arm_back": A(96, 106), "leg_front": A(85, 100), "leg_back": A(105, 98), "weapon": 114, "fire_t": 0.87},
]

ATTACK = [
    {"bob": 0, "arm_front": A(105, 115), "arm_back": A(95, 105), "leg_front": A(94, 95), "leg_back": A(86, 100), "weapon": 115, "fire_t": 0.0},
    {"bob": 0, "arm_front": A(110, 110), "arm_back": A(90, 100), "leg_front": A(92, 98), "leg_back": A(88, 100), "weapon": 125, "fire_t": 0.1},
    {"bob": 1, "arm_front": A(120, 115), "arm_back": A(80, 100), "leg_front": A(90, 100), "leg_back": A(90, 100), "weapon": 145, "fire_t": 0.2},
    {"bob": 2, "arm_front": A(135, 120), "arm_back": A(70, 105), "leg_front": A(88, 105), "leg_back": A(92, 100), "weapon": 165, "fire_t": 0.3},
    {"bob": 1, "arm_front": A(110, 95), "arm_back": A(85, 100), "leg_front": A(85, 100), "leg_back": A(95, 100), "weapon": 95, "fire_t": 0.4},   # active start
    {"bob": 0, "arm_front": A(80, 80), "arm_back": A(95, 105), "leg_front": A(85, 98), "leg_back": A(95, 100), "weapon": 55, "fire_t": 0.5},    # active end (slam)
    {"bob": 0, "arm_front": A(70, 85), "arm_back": A(100, 110), "leg_front": A(88, 95), "leg_back": A(92, 100), "weapon": 50, "fire_t": 0.6},
    {"bob": 1, "arm_front": A(90, 100), "arm_back": A(95, 105), "leg_front": A(92, 95), "leg_back": A(88, 100), "weapon": 105, "fire_t": 0.7},
]

HURT = [
    {"bob": 0, "arm_front": A(115, 120), "arm_back": A(75, 110), "leg_front": A(96, 95), "leg_back": A(84, 102), "weapon": 130, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(125, 125), "arm_back": A(65, 115), "leg_front": A(100, 96), "leg_back": A(80, 105), "weapon": 140, "fire_t": 0.2},
    {"bob": 1, "arm_front": A(120, 122), "arm_back": A(70, 112), "leg_front": A(98, 95), "leg_back": A(82, 103), "weapon": 135, "fire_t": 0.4},
    {"bob": 0, "arm_front": A(110, 115), "arm_back": A(80, 108), "leg_front": A(94, 95), "leg_back": A(86, 101), "weapon": 120, "fire_t": 0.6},
]

DEATH = [
    {"bob": 0, "arm_front": A(110, 115), "arm_back": A(80, 108), "leg_front": A(94, 95), "leg_back": A(86, 101), "weapon": 120, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(120, 120), "arm_back": A(70, 112), "leg_front": A(98, 96), "leg_back": A(82, 104), "weapon": 130, "fire_t": 0.1},
    {"bob": 2, "arm_front": A(130, 125), "arm_back": A(60, 118), "leg_front": A(102, 98), "leg_back": A(78, 108), "weapon": 140, "fire_t": 0.2},
    {"bob": 3, "arm_front": A(125, 130), "arm_back": A(65, 122), "leg_front": A(100, 105), "leg_back": A(80, 112), "weapon": 145, "fire_t": 0.3},
    {"bob": 4, "arm_front": A(115, 135), "arm_back": A(75, 125), "leg_front": A(95, 110), "leg_back": A(85, 115), "weapon": 150, "fire_t": 0.4},
    {"bob": 5, "arm_front": A(105, 140), "arm_back": A(85, 130), "leg_front": A(90, 115), "leg_back": A(90, 118), "weapon": 155, "fire_t": 0.5},
    {"bob": 6, "arm_front": A(100, 145), "arm_back": A(90, 135), "leg_front": A(90, 118), "leg_back": A(90, 120), "weapon": 160, "fire_t": 0.6},
    {"bob": 7, "arm_front": A(95, 150), "arm_back": A(95, 140), "leg_front": A(90, 120), "leg_back": A(90, 120), "weapon": 165, "fire_t": 0.7},
]

ANIMS = {
    "melee_ghost_idle": (IDLE, 8.0, True),
    "melee_ghost_walk": (WALK, 8.0, True),
    "melee_ghost_attack": (ATTACK, 10.0, False),
    "melee_ghost_hurt": (HURT, 10.0, False),
    "melee_ghost_death": (DEATH, 8.0, False),
}


def build():
    for name, (poses, fps, loop) in ANIMS.items():
        fw, fh = MELEE_CFG["fw"], MELEE_CFG["fh"]
        bake_sheet(fw, fh, len(poses),
                   lambda d, i, fw, fh, poses=poses: render_humanoid(d, MELEE_CFG, poses[i], fw, fh),
                   str(OUT / f"{name}.png"))
        print(f"  ✓ {name}.png  ({len(poses)} frames)")


if __name__ == "__main__":
    build()
