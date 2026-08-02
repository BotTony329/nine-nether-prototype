#!/usr/bin/env python3
"""Nine Nether V2 — Player: nameless Yue-family infantryman (岳家军军士).

Flexible, battle-worn Southern-Song foot soldier. Not a hero general.
Low center of gravity, single Song dao (宋刀) in the right hand, dark-red
cloth strips as the identifying marker. Living skin keeps slight warmth;
no heavy ghost fire.
"""

from __future__ import annotations
from pathlib import Path
from PIL import ImageDraw
from pixel_engine import new_canvas, bake_sheet
from humanoid import humanoid_config, render_humanoid

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets_v2" / "characters" / "player"

PLAYER_CFG = humanoid_config(
    fw=96, fh=96, cx=48, hip_y=66, torso_len=26, neck_len=5, head_r=9,
    upper_arm=16, lower_arm=15, arm_w=4, thigh=17, shin=16, leg_w=5,
    scale=1.05, lean=3, stance=4, style="player", torso_hw=9, torso_hw_hip=7,
    weapon_len=46,
    palette={
        "skin": (205, 170, 140), "skin_lt": (232, 198, 168), "skin_sh": (150, 116, 92),
        "armor": (96, 87, 81), "armor_lt": (142, 130, 119), "armor_dk": (58, 52, 48),
        "cloth": (128, 40, 40), "cloth_lt": (168, 62, 56), "cloth_dk": (74, 24, 24),
        "blade": (152, 158, 168), "blade_lt": (208, 213, 222), "blade_dk": (96, 101, 111),
        "grip": (72, 54, 40), "guard": (132, 102, 74),
        "outline": (18, 14, 16),
    },
)

# angle convention: 0=down, +90=right, -90=left, 180=up
A = lambda sa, ea: (sa, ea)

# Idle: pronounced breathing + weight shift + sabre sway. Consecutive frames
# always differ by >=3px bob (or large weapon/limb delta) so no near-duplicate
# frames (V1 failure mode).
IDLE = [
    {"bob": 0, "arm_front": A(82, 96), "arm_back": A(98, 104), "leg_front": A(91, 93), "leg_back": A(89, 95), "weapon": 66, "cloth_sway": 0, "lean": 0},
    {"bob": 3, "arm_front": A(80, 95), "arm_back": A(100, 103), "leg_front": A(90, 94), "leg_back": A(90, 96), "weapon": 70, "cloth_sway": 1, "lean": 0},
    {"bob": 6, "arm_front": A(78, 94), "arm_back": A(102, 102), "leg_front": A(89, 95), "leg_back": A(91, 97), "weapon": 74, "cloth_sway": 2, "lean": 0},
    {"bob": 3, "arm_front": A(80, 95), "arm_back": A(100, 103), "leg_front": A(90, 94), "leg_back": A(90, 96), "weapon": 72, "cloth_sway": 1, "lean": 0},
    {"bob": 0, "arm_front": A(83, 96), "arm_back": A(97, 104), "leg_front": A(92, 93), "leg_back": A(88, 95), "weapon": 68, "cloth_sway": 0, "lean": 0},
    {"bob": 3, "arm_front": A(85, 97), "arm_back": A(95, 105), "leg_front": A(93, 92), "leg_back": A(87, 94), "weapon": 71, "cloth_sway": 1, "lean": 0},
    {"bob": 6, "arm_front": A(81, 95), "arm_back": A(99, 103), "leg_front": A(90, 95), "leg_back": A(91, 97), "weapon": 75, "cloth_sway": 2, "lean": 0},
    {"bob": 3, "arm_front": A(82, 96), "arm_back": A(98, 104), "leg_front": A(91, 94), "leg_back": A(89, 96), "weapon": 73, "cloth_sway": 1, "lean": 0},
]

RUN = [
    {"bob": 1, "lean": 9, "arm_front": A(70, 100), "arm_back": A(110, 96), "leg_front": A(68, 102), "leg_back": A(112, 96), "weapon": 60, "cloth_sway": 3},
    {"bob": 0, "lean": 9, "arm_front": A(74, 100), "arm_back": A(106, 98), "leg_front": A(78, 96), "leg_back": A(106, 100), "weapon": 58, "cloth_sway": 4},
    {"bob": 0, "lean": 9, "arm_front": A(80, 98), "arm_back": A(100, 100), "leg_front": A(90, 95), "leg_back": A(90, 95), "weapon": 56, "cloth_sway": 3},
    {"bob": 1, "lean": 9, "arm_front": A(86, 100), "arm_back": A(94, 102), "leg_front": A(110, 96), "leg_back": A(70, 100), "weapon": 58, "cloth_sway": 2},
    {"bob": 1, "lean": 9, "arm_front": A(88, 100), "arm_back": A(92, 102), "leg_front": A(112, 96), "leg_back": A(68, 102), "weapon": 60, "cloth_sway": 3},
    {"bob": 0, "lean": 9, "arm_front": A(84, 100), "arm_back": A(96, 100), "leg_front": A(106, 98), "leg_back": A(78, 96), "weapon": 58, "cloth_sway": 4},
    {"bob": 0, "lean": 9, "arm_front": A(80, 98), "arm_back": A(100, 100), "leg_front": A(90, 95), "leg_back": A(90, 95), "weapon": 56, "cloth_sway": 3},
    {"bob": 1, "lean": 9, "arm_front": A(74, 100), "arm_back": A(106, 98), "leg_front": A(70, 102), "leg_back": A(110, 96), "weapon": 58, "cloth_sway": 2},
]

JUMP = [
    {"bob": 2, "lean": 10, "arm_front": A(60, 80), "arm_back": A(120, 90), "leg_front": A(80, 120), "leg_back": A(100, 120), "weapon": 150, "cloth_sway": 2},
    {"bob": 2, "lean": 6, "arm_front": A(55, 70), "arm_back": A(125, 80), "leg_front": A(70, 135), "leg_back": A(110, 130), "weapon": 165, "cloth_sway": 3},
    {"bob": 2, "lean": 12, "arm_front": A(65, 85), "arm_back": A(115, 95), "leg_front": A(95, 110), "leg_back": A(85, 112), "weapon": 155, "cloth_sway": 2},
]

FALL = [
    {"bob": 1, "lean": -4, "arm_front": A(95, 100), "arm_back": A(85, 100), "leg_front": A(100, 100), "leg_back": A(80, 100), "weapon": 50, "cloth_sway": 3},
    {"bob": 1, "lean": -6, "arm_front": A(100, 105), "arm_back": A(80, 105), "leg_front": A(105, 108), "leg_back": A(75, 108), "weapon": 45, "cloth_sway": 4},
    {"bob": 1, "lean": -5, "arm_front": A(98, 102), "arm_back": A(82, 102), "leg_front": A(102, 104), "leg_back": A(78, 104), "weapon": 48, "cloth_sway": 3},
]

# Light attack 1: horizontal sabre slash, right-to-left sweep ending forward
LIGHT_ATTACK_1 = [
    {"bob": 0, "lean": 2,  "arm_front": A(84, 96), "arm_back": A(96, 100), "leg_front": A(90, 92), "leg_back": A(90, 96), "weapon": 70, "cloth_sway": 0},  # 0 neutral
    {"bob": 1, "lean": -4, "arm_front": A(95, 100), "arm_back": A(90, 100), "leg_front": A(86, 96), "leg_back": A(94, 98), "weapon": 110, "cloth_sway": 1},  # 1 sink
    {"bob": 1, "lean": -6, "arm_front": A(120, 120), "arm_back": A(85, 100), "leg_front": A(84, 98), "leg_back": A(96, 98), "weapon": 155, "cloth_sway": 1},  # 2 draw back
    {"bob": 0, "lean": 4,  "arm_front": A(150, 130), "arm_back": A(80, 100), "leg_front": A(82, 96), "leg_back": A(98, 98), "weapon": 175, "cloth_sway": 2},  # 3 waist turn
    {"bob": 0, "lean": 8,  "arm_front": A(60, 70), "arm_back": A(95, 100), "leg_front": A(80, 95), "leg_back": A(100, 100), "weapon": 20, "cloth_sway": 3},   # 4 ACTIVE start
    {"bob": 0, "lean": 10, "arm_front": A(40, 60), "arm_back": A(98, 102), "leg_front": A(78, 95), "leg_back": A(102, 100), "weapon": 0, "cloth_sway": 4},    # 5 ACTIVE end (max reach)
    {"bob": 0, "lean": 6,  "arm_front": A(20, 70), "arm_back": A(100, 104), "leg_front": A(80, 95), "leg_back": A(100, 100), "weapon": -25, "cloth_sway": 3},  # 6 follow
    {"bob": 0, "lean": 2,  "arm_front": A(70, 92), "arm_back": A(98, 102), "leg_front": A(90, 93), "leg_back": A(90, 96), "weapon": 60, "cloth_sway": 1},    # 7 recover
]

# Light attack 2: reverse diagonal / back horizontal slash (opposite rhythm)
LIGHT_ATTACK_2 = [
    {"bob": 0, "lean": 2,  "arm_front": A(84, 96), "arm_back": A(96, 100), "leg_front": A(90, 92), "leg_back": A(90, 96), "weapon": 70, "cloth_sway": 0},   # 0 neutral
    {"bob": 1, "lean": 6,  "arm_front": A(60, 80), "arm_back": A(96, 100), "leg_front": A(80, 95), "leg_back": A(100, 100), "weapon": -10, "cloth_sway": 1},  # 1 wind forward
    {"bob": 1, "lean": 8,  "arm_front": A(30, 70), "arm_back": A(98, 102), "leg_front": A(78, 95), "leg_back": A(102, 100), "weapon": -40, "cloth_sway": 2},  # 2 raise
    {"bob": 0, "lean": 2,  "arm_front": A(10, 75), "arm_back": A(100, 104), "leg_front": A(82, 96), "leg_back": A(98, 98), "weapon": -70, "cloth_sway": 2},   # 3 high
    {"bob": 0, "lean": -5, "arm_front": A(150, 80), "arm_back": A(90, 100), "leg_front": A(88, 96), "leg_back": A(92, 98), "weapon": 160, "cloth_sway": 3},   # 4 ACTIVE start (overhead to back)
    {"bob": 0, "lean": -7, "arm_front": A(175, 100), "arm_back": A(85, 100), "leg_front": A(92, 98), "leg_back": A(88, 96), "weapon": 190, "cloth_sway": 4},   # 5 ACTIVE end (behind)
    {"bob": 0, "lean": -3, "arm_front": A(160, 110), "arm_back": A(90, 100), "leg_front": A(90, 96), "leg_back": A(90, 96), "weapon": 200, "cloth_sway": 3},   # 6 follow
    {"bob": 0, "lean": 2,  "arm_front": A(84, 96), "arm_back": A(96, 100), "leg_front": A(90, 93), "leg_back": A(90, 96), "weapon": 70, "cloth_sway": 1},     # 7 recover
]

# Heavy attack: big wind-up, slow, late hit
HEAVY_ATTACK = [
    {"bob": 0, "lean": 2,  "arm_front": A(84, 96), "arm_back": A(96, 100), "leg_front": A(90, 92), "leg_back": A(90, 96), "weapon": 70, "cloth_sway": 0},    # 0 neutral
    {"bob": 2, "lean": -8, "arm_front": A(95, 100), "arm_back": A(90, 100), "leg_front": A(84, 100), "leg_back": A(96, 100), "weapon": 100, "cloth_sway": 1},  # 1 crouch
    {"bob": 3, "lean": -12, "arm_front": A(120, 120), "arm_back": A(85, 100), "leg_front": A(80, 105), "leg_back": A(98, 102), "weapon": 140, "cloth_sway": 1}, # 2 deep sink
    {"bob": 3, "lean": -14, "arm_front": A(150, 140), "arm_back": A(82, 100), "leg_front": A(78, 108), "leg_back": A(100, 104), "weapon": 170, "cloth_sway": 2}, # 3 draw way back
    {"bob": 2, "lean": -10, "arm_front": A(165, 150), "arm_back": A(80, 100), "leg_front": A(80, 104), "leg_back": A(98, 102), "weapon": 185, "cloth_sway": 2}, # 4 coil peak
    {"bob": 0, "lean": 12, "arm_front": A(30, 70), "arm_back": A(98, 104), "leg_front": A(76, 95), "leg_back": A(104, 100), "weapon": -10, "cloth_sway": 4},   # 5 RELEASE
    {"bob": 0, "lean": 16, "arm_front": A(10, 60), "arm_back": A(100, 106), "leg_front": A(74, 95), "leg_back": A(106, 100), "weapon": -40, "cloth_sway": 5},   # 6 ACTIVE (max reach)
    {"bob": 0, "lean": 10, "arm_front": A(0, 65), "arm_back": A(102, 108), "leg_front": A(78, 96), "leg_back": A(102, 100), "weapon": -55, "cloth_sway": 4},   # 7 follow
    {"bob": 1, "lean": 4,  "arm_front": A(40, 85), "arm_back": A(100, 104), "leg_front": A(84, 96), "leg_back": A(96, 98), "weapon": 10, "cloth_sway": 2},     # 8 recover 1
    {"bob": 0, "lean": 2,  "arm_front": A(84, 96), "arm_back": A(96, 100), "leg_front": A(90, 93), "leg_back": A(90, 96), "weapon": 70, "cloth_sway": 1},     # 9 recover 2
]

HURT = [
    {"bob": 0, "lean": -8, "arm_front": A(110, 110), "arm_back": A(70, 110), "leg_front": A(95, 95), "leg_back": A(85, 100), "weapon": 120, "cloth_sway": 2},  # 0 recoil
    {"bob": 0, "lean": -10, "arm_front": A(120, 115), "arm_back": A(65, 115), "leg_front": A(98, 96), "leg_back": A(82, 102), "weapon": 130, "cloth_sway": 3},  # 1 knocked
    {"bob": 1, "lean": -6, "arm_front": A(110, 110), "arm_back": A(70, 110), "leg_front": A(95, 95), "leg_back": A(85, 100), "weapon": 120, "cloth_sway": 2},  # 2 settle
    {"bob": 0, "lean": -3, "arm_front": A(100, 105), "arm_back": A(80, 108), "leg_front": A(92, 94), "leg_back": A(88, 98), "weapon": 100, "cloth_sway": 1},   # 3 recover
]

DEATH = [
    {"bob": 0, "lean": -6, "arm_front": A(100, 105), "arm_back": A(80, 108), "leg_front": A(92, 94), "leg_back": A(88, 98), "weapon": 100, "cloth_sway": 1},   # 0 hit
    {"bob": 1, "lean": -10, "arm_front": A(115, 115), "arm_back": A(65, 115), "leg_front": A(98, 96), "leg_back": A(82, 102), "weapon": 120, "cloth_sway": 2}, # 1 stagger
    {"bob": 1, "lean": -14, "arm_front": A(125, 120), "arm_back": A(60, 120), "leg_front": A(102, 98), "leg_back": A(80, 105), "weapon": 135, "cloth_sway": 2}, # 2 lose balance
    {"bob": 2, "lean": -16, "arm_front": A(130, 125), "arm_back": A(55, 125), "leg_front": A(105, 100), "leg_back": A(78, 108), "weapon": 145, "cloth_sway": 1}, # 3 fall back
    {"bob": 4, "lean": -18, "arm_front": A(120, 130), "arm_back": A(60, 130), "leg_front": A(100, 105), "leg_back": A(80, 110), "weapon": 150, "cloth_sway": 0}, # 4 kneel
    {"bob": 6, "lean": -20, "arm_front": A(110, 135), "arm_back": A(70, 135), "leg_front": A(95, 110), "leg_back": A(85, 112), "weapon": 158, "cloth_sway": 0}, # 5 weapon drops
    {"bob": 8, "lean": -22, "arm_front": A(100, 140), "arm_back": A(80, 140), "leg_front": A(90, 115), "leg_back": A(90, 115), "weapon": 165, "cloth_sway": 0}, # 6 down
    {"bob": 10, "lean": -24, "arm_front": A(95, 145), "arm_back": A(85, 145), "leg_front": A(90, 118), "leg_back": A(90, 118), "weapon": 170, "cloth_sway": 0}, # 7 collapse
    {"bob": 12, "lean": -26, "arm_front": A(90, 150), "arm_back": A(90, 150), "leg_front": A(90, 120), "leg_back": A(90, 120), "weapon": 175, "cloth_sway": 0}, # 8 corpse
    {"bob": 12, "lean": -26, "arm_front": A(89, 152), "arm_back": A(91, 148), "leg_front": A(88, 122), "leg_back": A(92, 118), "weapon": 186, "cloth_sway": 0}, # 9 corpse hold (distinct from f8)
]

ANIMS = {
    "player_idle": (IDLE, 8.0, True),
    "player_run": (RUN, 12.0, True),
    "player_jump": (JUMP, 10.0, False),
    "player_fall": (FALL, 10.0, False),
    "player_light_attack_1": (LIGHT_ATTACK_1, 12.0, False),
    "player_light_attack_2": (LIGHT_ATTACK_2, 12.0, False),
    "player_heavy_attack": (HEAVY_ATTACK, 10.0, False),
    "player_hurt": (HURT, 10.0, False),
    "player_death": (DEATH, 8.0, False),
}


def build():
    for name, (poses, fps, loop) in ANIMS.items():
        fw, fh = PLAYER_CFG["fw"], PLAYER_CFG["fh"]
        bake_sheet(fw, fh, len(poses),
                   lambda d, i, fw, fh, poses=poses: render_humanoid(d, PLAYER_CFG, poses[i], fw, fh),
                   str(OUT / f"{name}.png"))
        print(f"  ✓ {name}.png  ({len(poses)} frames)")


if __name__ == "__main__":
    build()
