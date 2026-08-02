#!/usr/bin/env python3
"""Nine Nether V2 — Gate Warden Boss (镇关鬼将).

Massive gate guardian, 2.5-3x player height. Upper body extremely wide,
asymmetric shoulders (one huge pauldron), short stable legs, hidden head in
empty helm with strong ghost fire. Great blade length >= 70% of body height.
"""

from __future__ import annotations
from pathlib import Path
from pixel_engine import bake_sheet
from humanoid import humanoid_config, render_humanoid

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets_v2" / "characters" / "gate_warden"

BOSS_CFG = humanoid_config(
    fw=192, fh=192, cx=96, hip_y=128, torso_len=54, neck_len=10, head_r=20,
    upper_arm=36, lower_arm=30, arm_w=8, thigh=34, shin=30, leg_w=10,
    scale=1.0, lean=4, stance=10, style="boss",
    torso_hw=22, torso_hw_hip=18,
    weapon_len=112, ghost_fire=True, pauldrons=True, asymmetric_pauldrons=True,
    palette={
        "skin": (82, 78, 88), "skin_lt": (105, 100, 112), "skin_sh": (55, 52, 62),
        "armor": (58, 50, 66), "armor_lt": (88, 78, 98), "armor_dk": (35, 30, 42),
        "cloth": (105, 32, 32), "cloth_lt": (145, 48, 44), "cloth_dk": (65, 18, 18),
        "gold": (130, 108, 58), "copper": (115, 78, 52),
        "blade": (82, 80, 92), "blade_lt": (132, 130, 148), "blade_dk": (48, 46, 56),
        "grip": (55, 45, 38), "guard": (125, 105, 62),
        "outline": (14, 12, 18),
    },
)

A = lambda sa, ea: (sa, ea)

# Idle: colossal breathing, >=3px bob steps (large canvas), ghost-fire flicker.
IDLE = [
    {"bob": 0, "arm_front": A(88, 98), "arm_back": A(92, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 83, "fire_t": 0.0},
    {"bob": 3, "arm_front": A(87, 98), "arm_back": A(93, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 86, "fire_t": 0.12},
    {"bob": 6, "arm_front": A(86, 97), "arm_back": A(94, 101), "leg_front": A(90, 93), "leg_back": A(90, 94), "weapon": 89, "fire_t": 0.25},
    {"bob": 3, "arm_front": A(87, 98), "arm_back": A(93, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 87, "fire_t": 0.37},
    {"bob": 0, "arm_front": A(88, 98), "arm_back": A(92, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 84, "fire_t": 0.5},
    {"bob": 3, "arm_front": A(89, 99), "arm_back": A(91, 103), "leg_front": A(92, 91), "leg_back": A(88, 95), "weapon": 86, "fire_t": 0.62},
    {"bob": 6, "arm_front": A(86, 97), "arm_back": A(94, 101), "leg_front": A(90, 93), "leg_back": A(90, 94), "weapon": 88, "fire_t": 0.75},
    {"bob": 3, "arm_front": A(88, 98), "arm_back": A(92, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 85, "fire_t": 0.87},
]

WALK = [
    {"bob": 0, "arm_front": A(88, 100), "arm_back": A(92, 104), "leg_front": A(78, 102), "leg_back": A(105, 95), "weapon": 88, "fire_t": 0.0},
    {"bob": 2, "arm_front": A(90, 102), "arm_back": A(90, 106), "leg_front": A(86, 98), "leg_back": A(98, 98), "weapon": 90, "fire_t": 0.12},
    {"bob": 3, "arm_front": A(92, 104), "arm_back": A(88, 108), "leg_front": A(94, 95), "leg_back": A(94, 95), "weapon": 92, "fire_t": 0.25},
    {"bob": 2, "arm_front": A(90, 102), "arm_back": A(90, 106), "leg_front": A(102, 98), "leg_back": A(86, 98), "weapon": 90, "fire_t": 0.37},
    {"bob": 0, "arm_front": A(88, 100), "arm_back": A(92, 104), "leg_front": A(108, 95), "leg_back": A(78, 102), "weapon": 88, "fire_t": 0.5},
    {"bob": 2, "arm_front": A(90, 102), "arm_back": A(90, 106), "leg_front": A(102, 98), "leg_back": A(86, 98), "weapon": 90, "fire_t": 0.62},
    {"bob": 3, "arm_front": A(92, 104), "arm_back": A(88, 108), "leg_front": A(94, 95), "leg_back": A(94, 95), "weapon": 92, "fire_t": 0.75},
    {"bob": 2, "arm_front": A(90, 102), "arm_back": A(90, 106), "leg_front": A(86, 98), "leg_back": A(98, 98), "weapon": 90, "fire_t": 0.87},
]

# Horizontal sweep
ATTACK_1 = [
    {"bob": 0, "arm_front": A(88, 98), "arm_back": A(92, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 85, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(95, 100), "arm_back": A(85, 100), "leg_front": A(88, 95), "leg_back": A(92, 95), "weapon": 100, "fire_t": 0.1},
    {"bob": 2, "arm_front": A(110, 110), "arm_back": A(75, 100), "leg_front": A(84, 98), "leg_back": A(96, 95), "weapon": 125, "fire_t": 0.2},
    {"bob": 2, "arm_front": A(125, 120), "arm_back": A(65, 105), "leg_front": A(80, 100), "leg_back": A(100, 95), "weapon": 150, "fire_t": 0.3},
    {"bob": 1, "arm_front": A(140, 125), "arm_back": A(60, 110), "leg_front": A(78, 102), "leg_back": A(102, 95), "weapon": 170, "fire_t": 0.4},  # active start
    {"bob": 0, "arm_front": A(80, 90), "arm_back": A(90, 105), "leg_front": A(76, 100), "leg_back": A(104, 95), "weapon": 30, "fire_t": 0.5},   # active end
    {"bob": 0, "arm_front": A(55, 80), "arm_back": A(100, 108), "leg_front": A(78, 98), "leg_back": A(102, 95), "weapon": 0, "fire_t": 0.6},
    {"bob": 0, "arm_front": A(40, 75), "arm_back": A(110, 110), "leg_front": A(82, 96), "leg_back": A(98, 95), "weapon": -25, "fire_t": 0.7},
    {"bob": 1, "arm_front": A(70, 90), "arm_back": A(100, 105), "leg_front": A(86, 94), "leg_back": A(94, 95), "weapon": 50, "fire_t": 0.8},
    {"bob": 0, "arm_front": A(88, 98), "arm_back": A(92, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 85, "fire_t": 0.9},
]

# Overhead slam / ground pound
ATTACK_2 = [
    {"bob": 0, "arm_front": A(88, 98), "arm_back": A(92, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 85, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(95, 100), "arm_back": A(85, 100), "leg_front": A(88, 95), "leg_back": A(92, 95), "weapon": 100, "fire_t": 0.08},
    {"bob": 2, "arm_front": A(105, 105), "arm_back": A(78, 98), "leg_front": A(85, 98), "leg_back": A(95, 95), "weapon": 120, "fire_t": 0.16},
    {"bob": 3, "arm_front": A(120, 110), "arm_back": A(70, 100), "leg_front": A(82, 100), "leg_back": A(98, 95), "weapon": 145, "fire_t": 0.24},
    {"bob": 4, "arm_front": A(140, 115), "arm_back": A(60, 105), "leg_front": A(80, 102), "leg_back": A(100, 95), "weapon": 170, "fire_t": 0.32},
    {"bob": 4, "arm_front": A(160, 120), "arm_back": A(55, 110), "leg_front": A(78, 104), "leg_back": A(102, 95), "weapon": 185, "fire_t": 0.40}, # top hold
    {"bob": 3, "arm_front": A(170, 115), "arm_back": A(50, 112), "leg_front": A(78, 104), "leg_back": A(102, 95), "weapon": 190, "fire_t": 0.48}, # active start
    {"bob": 0, "arm_front": A(110, 85), "arm_back": A(75, 105), "leg_front": A(76, 102), "leg_back": A(104, 95), "weapon": 120, "fire_t": 0.56}, # slam
    {"bob": 0, "arm_front": A(75, 75), "arm_back": A(95, 110), "leg_front": A(76, 100), "leg_back": A(104, 95), "weapon": 70, "fire_t": 0.64},  # impact
    {"bob": 1, "arm_front": A(60, 75), "arm_back": A(105, 112), "leg_front": A(80, 98), "leg_back": A(100, 95), "weapon": 50, "fire_t": 0.72},
    {"bob": 2, "arm_front": A(75, 85), "arm_back": A(100, 108), "leg_front": A(85, 96), "leg_back": A(95, 95), "weapon": 70, "fire_t": 0.80},
    {"bob": 0, "arm_front": A(88, 98), "arm_back": A(92, 102), "leg_front": A(91, 92), "leg_back": A(89, 94), "weapon": 85, "fire_t": 0.88},
]

HURT = [
    {"bob": 0, "arm_front": A(100, 105), "arm_back": A(80, 100), "leg_front": A(94, 92), "leg_back": A(86, 96), "weapon": 100, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(110, 110), "arm_back": A(70, 105), "leg_front": A(96, 93), "leg_back": A(84, 98), "weapon": 110, "fire_t": 0.2},
    {"bob": 1, "arm_front": A(105, 108), "arm_back": A(75, 102), "leg_front": A(94, 92), "leg_back": A(86, 96), "weapon": 105, "fire_t": 0.4},
    {"bob": 0, "arm_front": A(95, 100), "arm_back": A(85, 100), "leg_front": A(92, 91), "leg_back": A(88, 95), "weapon": 95, "fire_t": 0.6},
]

DEATH = [
    {"bob": 0, "arm_front": A(95, 100), "arm_back": A(85, 100), "leg_front": A(92, 91), "leg_back": A(88, 95), "weapon": 95, "fire_t": 0.0},
    {"bob": 1, "arm_front": A(105, 108), "arm_back": A(75, 105), "leg_front": A(95, 93), "leg_back": A(85, 98), "weapon": 105, "fire_t": 0.08},
    {"bob": 2, "arm_front": A(115, 115), "arm_back": A(65, 110), "leg_front": A(98, 95), "leg_back": A(82, 102), "weapon": 115, "fire_t": 0.16},
    {"bob": 3, "arm_front": A(120, 120), "arm_back": A(60, 115), "leg_front": A(100, 98), "leg_back": A(80, 105), "weapon": 120, "fire_t": 0.24},
    {"bob": 4, "arm_front": A(115, 125), "arm_back": A(65, 120), "leg_front": A(98, 105), "leg_back": A(82, 110), "weapon": 125, "fire_t": 0.32},
    {"bob": 5, "arm_front": A(110, 130), "arm_back": A(70, 125), "leg_front": A(95, 110), "leg_back": A(85, 115), "weapon": 130, "fire_t": 0.40},
    {"bob": 6, "arm_front": A(105, 135), "arm_back": A(75, 130), "leg_front": A(92, 115), "leg_back": A(88, 118), "weapon": 135, "fire_t": 0.48},
    {"bob": 7, "arm_front": A(100, 140), "arm_back": A(80, 135), "leg_front": A(90, 118), "leg_back": A(90, 120), "weapon": 140, "fire_t": 0.56},
    {"bob": 8, "arm_front": A(95, 145), "arm_back": A(85, 140), "leg_front": A(90, 120), "leg_back": A(90, 122), "weapon": 145, "fire_t": 0.64},
    {"bob": 9, "arm_front": A(90, 150), "arm_back": A(90, 145), "leg_front": A(90, 122), "leg_back": A(90, 124), "weapon": 150, "fire_t": 0.72},
    {"bob": 10, "arm_front": A(90, 155), "arm_back": A(90, 150), "leg_front": A(90, 124), "leg_back": A(90, 126), "weapon": 155, "fire_t": 0.80},
    {"bob": 10, "arm_front": A(90, 160), "arm_back": A(90, 155), "leg_front": A(90, 126), "leg_back": A(90, 128), "weapon": 160, "fire_t": 0.88},
]

ANIMS = {
    "gate_warden_idle": (IDLE, 6.0, True),
    "gate_warden_walk": (WALK, 8.0, True),
    "gate_warden_attack_1": (ATTACK_1, 9.0, False),
    "gate_warden_attack_2": (ATTACK_2, 8.0, False),
    "gate_warden_hurt": (HURT, 8.0, False),
    "gate_warden_death": (DEATH, 6.0, False),
}


def build():
    for name, (poses, fps, loop) in ANIMS.items():
        fw, fh = BOSS_CFG["fw"], BOSS_CFG["fh"]
        bake_sheet(fw, fh, len(poses),
                   lambda d, i, fw, fh, poses=poses: render_humanoid(d, BOSS_CFG, poses[i], fw, fh),
                   str(OUT / f"{name}.png"))
        print(f"  ✓ {name}.png  ({len(poses)} frames)")


if __name__ == "__main__":
    build()
