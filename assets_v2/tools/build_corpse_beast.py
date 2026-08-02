#!/usr/bin/env python3
"""Nine Nether V2 — Corpse Beast (冲锋尸兽) build script.

Low, wide, quadrupedal charge enemy. Distinct horizontal silhouette from all
humanoid characters. Glowing red eyes/chest during charge wind-up.

Animations (per brief):
  idle          6   subtle breathing / tail sway
  run           8   gallop cycle
  charge_windup 6   coil + red charge glow builds 0 -> 1
  charge        4   full extension, glow max, legs locked forward
  wall_impact   4   compressed against wall, glow fading
  hurt          4   recoil scramble
  death         8   collapse, legs fold, sink down
"""

from __future__ import annotations
from pathlib import Path
from pixel_engine import bake_sheet
from beast import beast_config, render_beast

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets_v2" / "characters" / "corpse_beast"

# Decayed cold palette — distinct from the warm humanoids and the green ghost
# fire of the bow/melee ghosts. Eyes/chest use fixed red (see beast.render_beast).
BEAST_CFG = beast_config(
    fw=128, fh=96,
    palette={
        "outline": (16, 13, 15),
        "body": (70, 62, 56), "body_lt": (104, 94, 84), "body_dk": (48, 42, 38),
        "leg": (62, 54, 50), "leg_dk": (42, 36, 34), "leg_lt": (92, 84, 76),
        "claw": (150, 22, 22),
    },
)

# ── pose helpers ─────────────────────────────────────────────────────────────
def leg(fl, fra, bl, bra):
    """Front-left / front-right / back-left / back-right (knee, ankle)."""
    return {
        "leg_fl_knee": fl[0], "leg_fl_ankle": fl[1],
        "leg_fr_knee": fra[0], "leg_fr_ankle": fra[1],
        "leg_bl_knee": bl[0], "leg_bl_ankle": bl[1],
        "leg_br_knee": bra[0], "leg_br_ankle": bra[1],
    }

# Idle: low quadruped breathing, >=3px bob/arch steps, no dup frames.
IDLE = [
    {"bob": 0, "arch": 0, "tail": 0, **leg((85, 100), (85, 100), (95, 80), (95, 80))},
    {"bob": 3, "arch": 3, "tail": 3, **leg((82, 102), (88, 98), (92, 82), (98, 78))},
    {"bob": 6, "arch": 6, "tail": -2, **leg((88, 98), (82, 102), (98, 78), (92, 82))},
    {"bob": 3, "arch": 3, "tail": 3, **leg((84, 101), (86, 99), (94, 81), (96, 79))},
    {"bob": 0, "arch": 0, "tail": 0, **leg((86, 99), (84, 101), (96, 79), (94, 81))},
    {"bob": 3, "arch": 3, "tail": 2, **leg((83, 102), (87, 98), (93, 82), (97, 78))},
]

RUN = [
    {"bob": 2, "arch": 3, "stretch": 2, "head_y": -2, "tail": -3, **leg((70, 95), (70, 95), (110, 80), (110, 80))},
    {"bob": 1, "arch": 4, "stretch": 4, "head_y": -1, "tail": -5, **leg((80, 100), (80, 100), (120, 70), (120, 70))},
    {"bob": 2, "arch": 3, "stretch": 3, "head_y": 0, "tail": -2, **leg((95, 105), (95, 105), (100, 85), (100, 85))},
    {"bob": 0, "arch": 2, "stretch": 5, "head_y": -3, "tail": -6, **leg((65, 90), (65, 90), (115, 75), (115, 75))},
    {"bob": 1, "arch": 3, "stretch": 4, "head_y": -1, "tail": -4, **leg((75, 96), (75, 96), (125, 68), (125, 68))},
    {"bob": 2, "arch": 3, "stretch": 3, "head_y": 0, "tail": -2, **leg((92, 104), (92, 104), (102, 84), (102, 84))},
    {"bob": 1, "arch": 4, "stretch": 4, "head_y": -1, "tail": -5, **leg((82, 101), (82, 101), (122, 72), (122, 72))},
    {"bob": 2, "arch": 2, "stretch": 3, "head_y": -2, "tail": -3, **leg((72, 94), (72, 94), (112, 78), (112, 78))},
]

CHARGE_WINDUP = [
    {"bob": 0, "arch": 2, "stretch": -2, "head_y": 2, "charge_glow": 0.10, "tail": 2, **leg((90, 100), (90, 100), (95, 80), (95, 80))},
    {"bob": 1, "arch": 4, "stretch": -3, "head_y": 3, "charge_glow": 0.30, "tail": 1, **leg((94, 102), (94, 102), (98, 82), (98, 82))},
    {"bob": 2, "arch": 6, "stretch": -4, "head_y": 4, "charge_glow": 0.50, "tail": 0, **leg((98, 103), (98, 103), (100, 84), (100, 84))},
    {"bob": 3, "arch": 8, "stretch": -6, "head_y": 5, "charge_glow": 0.70, "tail": -1, **leg((102, 104), (102, 104), (103, 86), (103, 86))},
    {"bob": 4, "arch": 10, "stretch": -7, "head_y": 6, "charge_glow": 0.85, "tail": -2, **leg((104, 106), (104, 106), (105, 88), (105, 88))},
    {"bob": 5, "arch": 12, "stretch": -9, "head_y": 7, "charge_glow": 1.00, "tail": -3, **leg((106, 108), (106, 108), (107, 90), (107, 90))},
]

CHARGE = [
    {"bob": 0, "arch": -2, "stretch": 10, "head_y": -6, "charge_glow": 1.0, "tail": -8, **leg((60, 88), (60, 88), (130, 64), (130, 64))},
    {"bob": 0, "arch": -3, "stretch": 12, "head_y": -7, "charge_glow": 1.0, "tail": -9, **leg((62, 90), (62, 90), (132, 62), (132, 62))},
    {"bob": 0, "arch": -2, "stretch": 11, "head_y": -6, "charge_glow": 1.0, "tail": -8, **leg((61, 89), (61, 89), (131, 63), (131, 63))},
    {"bob": 0, "arch": -3, "stretch": 12, "head_y": -7, "charge_glow": 1.0, "tail": -9, **leg((63, 91), (63, 91), (133, 61), (133, 61))},
]

WALL_IMPACT = [
    {"bob": 6, "arch": 6, "stretch": -8, "head_y": 8, "charge_glow": 0.60, "tail": 4, **leg((120, 96), (120, 96), (80, 92), (80, 92))},
    {"bob": 8, "arch": 8, "stretch": -10, "head_y": 10, "charge_glow": 0.40, "tail": 6, **leg((130, 98), (130, 98), (72, 95), (72, 95))},
    {"bob": 7, "arch": 7, "stretch": -9, "head_y": 9, "charge_glow": 0.25, "tail": 5, **leg((125, 97), (125, 97), (76, 93), (76, 93))},
    {"bob": 6, "arch": 6, "stretch": -8, "head_y": 8, "charge_glow": 0.15, "tail": 4, **leg((122, 96), (122, 96), (78, 92), (78, 92))},
]

HURT = [
    {"bob": 1, "arch": 1, "stretch": -1, "head_y": 3, **leg((100, 100), (100, 100), (98, 82), (98, 82))},
    {"bob": 3, "arch": 3, "stretch": -2, "head_y": 5, **leg((108, 104), (108, 104), (104, 86), (104, 86))},
    {"bob": 2, "arch": 2, "stretch": -1, "head_y": 4, **leg((104, 102), (104, 102), (101, 84), (101, 84))},
    {"bob": 1, "arch": 1, "stretch": 0, "head_y": 2, **leg((102, 101), (102, 101), (99, 83), (99, 83))},
]

DEATH = [
    {"bob": 2, "arch": 0, "stretch": 0, "head_y": 4, "charge_glow": 0.2, "tail": 2, **leg((100, 100), (100, 100), (98, 82), (98, 82))},
    {"bob": 4, "arch": -2, "stretch": -2, "head_y": 6, "charge_glow": 0.1, "tail": 4, **leg((110, 100), (110, 100), (105, 84), (105, 84))},
    {"bob": 6, "arch": -4, "stretch": -4, "head_y": 8, "tail": 6, **leg((120, 100), (120, 100), (112, 86), (112, 86))},
    {"bob": 8, "arch": -6, "stretch": -6, "head_y": 10, "tail": 8, **leg((128, 102), (128, 102), (118, 88), (118, 88))},
    {"bob": 10, "arch": -8, "stretch": -8, "head_y": 12, "tail": 10, **leg((132, 104), (132, 104), (122, 90), (122, 90))},
    {"bob": 12, "arch": -10, "stretch": -10, "head_y": 14, "tail": 12, **leg((134, 106), (134, 106), (124, 92), (124, 92))},
    {"bob": 14, "arch": -12, "stretch": -12, "head_y": 16, "tail": 14, **leg((135, 108), (135, 108), (126, 94), (126, 94))},
    {"bob": 16, "arch": -14, "stretch": -14, "head_y": 18, "tail": 16, **leg((136, 110), (136, 110), (128, 96), (128, 96))},
]

ANIMS = {
    "corpse_beast_idle": (IDLE, 5.0, True),
    "corpse_beast_run": (RUN, 10.0, True),
    "corpse_beast_charge_windup": (CHARGE_WINDUP, 8.0, False),
    "corpse_beast_charge": (CHARGE, 12.0, False),
    "corpse_beast_wall_impact": (WALL_IMPACT, 8.0, False),
    "corpse_beast_hurt": (HURT, 10.0, False),
    "corpse_beast_death": (DEATH, 6.0, False),
}


def build():
    fw, fh = BEAST_CFG["fw"], BEAST_CFG["fh"]
    for name, (poses, fps, loop) in ANIMS.items():
        bake_sheet(fw, fh, len(poses),
                   lambda d, i, fw, fh, poses=poses: render_beast(d, BEAST_CFG, poses[i], fw, fh),
                   str(OUT / f"{name}.png"))
        print(f"  ok {name}.png  ({len(poses)} frames)")


if __name__ == "__main__":
    build()
