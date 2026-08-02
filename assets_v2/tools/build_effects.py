#!/usr/bin/env python3
"""Nine Nether V2 — Combat Effects, transparent background.

  blade_slash     128x128 / 6f   sweeping crescent (cyan-white + ghost-green core)
  hit             96x96  / 4f    expanding impact starburst
  ghost_fire      64x64  / 8f   looping ghost flame (idle/emitter)
  death_dissolve  96x96  / 8f   rising fading motes (death VFX)

All use nearest-neighbor-friendly hard fills; no blur.
"""

from __future__ import annotations
from pathlib import Path
import math
from pixel_engine import new_canvas, fill_circle, fill_poly, ghost_fire, bake_sheet

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets_v2" / "effects"

CYAN = (150, 225, 245)
CYAN_LT = (220, 250, 255)
GHOST = (110, 240, 160)
GHOST_DK = (30, 150, 100)
WHITE = (235, 240, 248)
SPARK = (255, 230, 150)
RED = (200, 60, 50)


def crescent(d, cx, cy, R, t, a0, a1, color):
    """Filled crescent between outer radius R and inner R-t, from a0->a1 (deg)."""
    N = 18
    outer, inner = [], []
    for i in range(N + 1):
        a = math.radians(a0 + (a1 - a0) * i / N)
        outer.append((cx + R * math.cos(a), cy + R * math.sin(a)))
    for i in range(N + 1):
        a = math.radians(a0 + (a1 - a0) * (N - i) / N)
        inner.append((cx + (R - t) * math.cos(a), cy + (R - t) * math.sin(a)))
    fill_poly(d, outer + inner, color)


def blade_slash(d, i, fw, fh):
    cx, cy = fw // 2, fh // 2
    # arc sweeps from upper-left to lower-right across frames
    base = -120 + i * 38
    span = 70
    crescent(d, cx, cy, 54, 16, base, base + span, CYAN)
    crescent(d, cx, cy, 52, 7, base + 4, base + span - 4, CYAN_LT)
    crescent(d, cx, cy, 50, 3, base + 10, base + span - 10, WHITE)
    # ghost-green edge accent
    crescent(d, cx, cy, 56, 3, base - 2, base + 8, GHOST)


def hit(d, i, fw, fh):
    cx, cy = fw // 2, fh // 2
    grow = 8 + i * 16
    # central flash fades
    fill_circle(d, (cx, cy), max(2, 18 - i * 4), SPARK)
    fill_circle(d, (cx, cy), max(1, 9 - i * 2), WHITE)
    # radial sparks
    n = 8
    for k in range(n):
        a = math.radians(k * 360 / n + i * 20)
        x2 = cx + grow * math.cos(a)
        y2 = cy + grow * math.sin(a)
        d.line([(cx, cy), (int(x2), int(y2))], fill=SPARK if i < 2 else RED, width=2)
        fill_circle(d, (x2, y2), 2, SPARK if i < 2 else RED)


def ghost_fire_loop(d, i, fw, fh):
    ghost_fire(d, fw // 2, fh // 2 + 6, 14, t=i / 8.0)


def death_dissolve(d, i, fw, fh):
    # motes rise and fade
    import random
    random.seed(7)
    cx, cy = fw // 2, fh // 2 + 10
    motes = []
    for _ in range(22):
        ang = random.uniform(0, math.pi * 2)
        rad = random.uniform(4, 36)
        motes.append((math.cos(ang) * rad, math.sin(ang) * rad, random.uniform(1.5, 3.5)))
    for mx, my, r in motes:
        rise = i * (6 + r)
        yy = cy + my - rise
        alpha = max(0, 200 - i * 26)
        if yy < -10 or alpha <= 0:
            continue
        fill_circle(d, (cx + mx, yy), r, (GHOST[0], GHOST[1], GHOST[2], alpha))
        fill_circle(d, (cx + mx, yy), max(1, r - 1), (GHOST_DK[0], GHOST_DK[1], GHOST_DK[2], alpha // 2))


EFFECTS = [
    ("blade_slash", 128, 128, 6, blade_slash),
    ("hit", 96, 96, 4, hit),
    ("ghost_fire", 64, 64, 8, ghost_fire_loop),
    ("death_dissolve", 96, 96, 8, death_dissolve),
]


def build():
    for name, fw, fh, n, fn in EFFECTS:
        bake_sheet(fw, fh, n, fn, str(OUT / f"{name}.png"))
        print(f"  ok {name}.png  ({fw}x{fh}, {n}f)")


if __name__ == "__main__":
    build()
