#!/usr/bin/env python3
"""Nine Nether V2 — Weapon / Stat Icons (64x64), transparent background.

10 icons that must read instantly at small HUD size and stay distinct from
each other. Unified palette: steel/iron, dark-red cloth, ghost-green energy,
dark-gold sacred, deep-red danger. White outline rim for HUD legibility.
"""

from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageDraw
from pixel_engine import new_canvas, capsule, fill_circle, fill_poly, rect, ghost_fire

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets_v2" / "icons"
SZ = 64

# palette
O = (14, 12, 16)            # outline
STEEL = (150, 156, 168)
STEEL_LT = (200, 205, 216)
STEEL_DK = (92, 98, 110)
WOOD = (96, 70, 48)
WOOD_DK = (62, 44, 30)
RED = (120, 32, 32)
RED_LT = (170, 52, 48)
GOLD = (200, 170, 90)
GOLD_DK = (130, 108, 58)
GHOST = (110, 240, 160)
GHOST_DK = (30, 150, 100)
CYAN = (90, 200, 230)
BRONZE = (120, 96, 56)
BRONZE_DK = (78, 60, 34)
PAPER = (210, 190, 120)
PAPER_DK = (160, 140, 80)


def rdot(draw, p, r, c):
    fill_circle(draw, p, r, c)


# ── 1. Songdao (宋刀) — curved saber ─────────────────────────────────────────
def icon_songdao(d):
    # blade: curved polygon lower-left handle -> upper-right tip
    blade = [(16, 50), (20, 46), (40, 24), (46, 18), (50, 20), (30, 44), (24, 50)]
    fill_poly(d, blade, STEEL)
    fill_poly(d, [(20, 46), (40, 24), (46, 18), (50, 20), (47, 23), (42, 28), (23, 49)], STEEL_LT)  # edge light
    fill_poly(d, [(16, 50), (20, 46), (24, 50)], STEEL_DK)
    # guard
    rect(d, 14, 48, 10, 5, GOLD_DK)
    # handle
    capsule(d, (10, 52), (16, 50), 3, WOOD, outline=O)
    rdot(d, (9, 53), 3, RED)  # pommel wrap
    # outline rim
    fill_poly(d, blade, None)
    draw_edges(d, blade)


def draw_edges(d, pts):
    d.line([(int(round(x)), int(round(y))) for x, y in pts] + [(int(round(pts[0][0])), int(round(pts[0][1])))],
           fill=O, width=1)


# ── 2. Spear (沥泉枪) — shaft + leaf blade + tassel ──────────────────────────
def icon_spear(d):
    # shaft
    capsule(d, (32, 14), (32, 54), 3, WOOD, outline=O)
    # leaf blade tip
    tip = [(32, 6), (28, 16), (32, 20), (36, 16)]
    fill_poly(d, tip, STEEL)
    fill_poly(d, [(32, 6), (36, 16), (32, 20)], STEEL_LT)
    draw_edges(d, tip)
    # red tassel below blade
    for i in range(4):
        x = 32 + (i - 1.5) * 2
        capsule(d, (x, 22), (x + (i - 1) * 2, 30), 1, RED_LT if i % 2 else RED, outline=O)


# ── 3. Ghost fire (鬼火) ─────────────────────────────────────────────────────
def icon_ghostfire(d):
    ghost_fire(d, 32, 40, 16, t=0.5)
    rdot(d, (32, 44), 4, GHOST)
    rdot(d, (32, 40), 2, (220, 255, 235))


# ── 4. Talisman (护符) — yellow paper strip ─────────────────────────────────
def icon_talisman(d):
    paper = [(24, 12), (40, 12), (40, 54), (24, 54)]
    fill_poly(d, paper, PAPER)
    # notched top
    draw_edges(d, paper)
    # red vertical seal script (simplified bars)
    rect(d, 30, 18, 4, 4, RED)
    rect(d, 30, 26, 4, 8, RED)
    rect(d, 26, 40, 12, 3, RED)
    rect(d, 30, 46, 4, 5, RED)
    # shading
    fill_poly(d, [(24, 12), (28, 12), (28, 54), (24, 54)], PAPER_DK)


# ── 5. Gourd (酒葫芦) — wine gourd ──────────────────────────────────────────
def icon_gourd(d):
    # lower bulb
    rdot(d, (32, 42), 13, WOOD)
    # upper bulb
    rdot(d, (32, 24), 9, WOOD)
    # neck
    rect(d, 29, 32, 6, 5, WOOD_DK)
    # cork
    rect(d, 30, 14, 4, 5, (150, 120, 80))
    # highlight
    rdot(d, (27, 38), 4, (130, 100, 66))
    rdot(d, (29, 22), 3, (130, 100, 66))
    # outline
    d.ellipse((19, 29, 45, 55), outline=O, width=1)
    d.ellipse((23, 15, 41, 33), outline=O, width=1)


# ── 6. Broken flag (残破军旗) — torn battle standard ───────────────────────
def icon_flag(d):
    # pole
    capsule(d, (18, 8), (18, 56), 2, (110, 96, 70), outline=O)
    # torn flag (dark red) waving right with a notch
    flag = [(20, 12), (50, 16), (46, 22), (52, 28), (46, 34), (50, 42), (20, 40)]
    fill_poly(d, flag, RED)
    fill_poly(d, [(20, 12), (50, 16), (46, 22), (30, 20), (20, 22)], RED_LT)
    draw_edges(d, flag)
    # ragged hole
    rdot(d, (38, 28), 3, O)
    # emblem mark
    rect(d, 28, 22, 6, 6, GOLD)


# ── 7. Yin coin (阴钱) — underworld coin ────────────────────────────────────
def icon_coin(d):
    rdot(d, (32, 32), 18, BRONZE)
    rdot(d, (32, 32), 18, None)
    d.ellipse((14, 14, 50, 50), outline=O, width=1)
    d.ellipse((18, 18, 46, 46), outline=BRONZE_DK, width=1)
    # square hole
    rect(d, 28, 28, 8, 8, (30, 24, 16))
    d.rectangle((28, 28, 35, 35), outline=O, width=1)
    # ghost tint
    rdot(d, (24, 24), 3, GHOST_DK)


# ── 8. Yang life (阳寿) — warm sun disc ─────────────────────────────────────
def icon_yang(d):
    # rays
    for a in range(0, 360, 45):
        import math
        rad = math.radians(a)
        x = 32 + 22 * math.sin(rad)
        y = 32 - 22 * math.cos(rad)
        x2 = 32 + 14 * math.sin(rad)
        y2 = 32 - 14 * math.cos(rad)
        d.line([(int(x2), int(y2)), (int(x), int(y))], fill=(220, 120, 50), width=2)
    rdot(d, (32, 32), 12, (220, 90, 50))
    rdot(d, (32, 32), 12, None)
    d.ellipse((20, 20, 44, 44), outline=O, width=1)
    rdot(d, (28, 28), 4, (245, 150, 80))


# ── 9. Qi / blood (气血) — red swirl orb ────────────────────────────────────
def icon_qi(d):
    rdot(d, (32, 34), 15, RED)
    rdot(d, (32, 34), 15, None)
    d.ellipse((17, 19, 47, 49), outline=O, width=1)
    # swirl highlight
    fill_poly(d, [(26, 30), (38, 26), (40, 32), (28, 38)], RED_LT)
    rdot(d, (27, 28), 3, (220, 110, 100))


# ── 10. Obsession (执念) — chained red knot ─────────────────────────────────
def icon_obsession(d):
    # chain loop
    import math
    pts = []
    cx, cy = 32, 32
    for i in range(28):
        a = i / 28 * math.pi * 2
        rr = 16 + 3 * math.sin(a * 3)
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    for i in range(len(pts) - 1):
        capsule(d, pts[i], pts[i + 1], 3, (120, 124, 134), outline=O)
    # red glowing core
    rdot(d, (32, 32), 7, RED)
    rdot(d, (32, 32), 3, (240, 90, 70))
    # eye slit
    rect(d, 29, 31, 6, 2, O)


ICONS = {
    "icon_songdao": icon_songdao,
    "icon_spear": icon_spear,
    "icon_ghostfire": icon_ghostfire,
    "icon_talisman": icon_talisman,
    "icon_gourd": icon_gourd,
    "icon_flag": icon_flag,
    "icon_coin": icon_coin,
    "icon_yang": icon_yang,
    "icon_qi": icon_qi,
    "icon_obsession": icon_obsession,
}


def build():
    for name, fn in ICONS.items():
        img, d = new_canvas(SZ, SZ)
        fn(d)
        OUT.mkdir(parents=True, exist_ok=True)
        img.save(str(OUT / f"{name}.png"))
        print(f"  ok {name}.png")


if __name__ == "__main__":
    build()
