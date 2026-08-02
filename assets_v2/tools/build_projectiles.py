#!/usr/bin/env python3
"""Nine Nether V2 — Projectiles (32x32), transparent background.

ghost_fire_arrow: a ghost-fire tipped arrow pointing RIGHT (flip in-engine for
left travel). Green flame head + trailing wisp.
"""

from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageDraw
from pixel_engine import new_canvas, fill_circle, fill_poly, ghost_fire

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets_v2" / "projectiles"
SZ = 32
O = (14, 12, 16)
STEEL = (150, 156, 168)
STEEL_LT = (205, 210, 220)
GHOST = (110, 240, 160)
GHOST_DK = (30, 150, 100)


def build():
    img, d = new_canvas(SZ, SZ)
    # shaft
    d.line([(6, 18), (24, 18)], fill=STEEL, width=2)
    d.line([(6, 16), (24, 16)], fill=STEEL_LT, width=1)
    # arrowhead (right)
    head = [(24, 18), (30, 14), (30, 22)]
    fill_poly(d, head, STEEL)
    fill_poly(d, [(24, 18), (30, 14), (29, 16)], STEEL_LT)
    d.line([(24, 18), (30, 14), (30, 22), (24, 18)], fill=O, width=1)
    # fletching
    fill_poly(d, [(6, 18), (2, 13), (4, 18)], GHOST_DK)
    fill_poly(d, [(6, 18), (2, 23), (4, 18)], GHOST_DK)
    # ghost-fire wisp trailing left
    ghost_fire(d, 12, 18, 7, t=0.3)
    fill_circle(d, (24, 18), 2, GHOST)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(str(OUT / "ghost_fire_arrow.png"))
    print("  ok ghost_fire_arrow.png (32x32)")


if __name__ == "__main__":
    build()
