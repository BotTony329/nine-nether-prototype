#!/usr/bin/env python3
"""Nine Nether V2 — Procedural Pixel-Art Engine.

Low-level drawing primitives for crisp, frame-consistent pixel art.
All drawing is done at 1:1 target resolution with hard-edged fills
(PIL polygon/ellipse) so output stays pixel-perfect under nearest-neighbor
scaling. No anti-aliasing, no blur, no supersampling.

Shading model: single directional light from the upper-left. Every limb is
drawn as a shaded capsule (dark base + lighter top-left sliver + 1px outline),
which keeps a consistent material read across all animation frames.
"""

from __future__ import annotations
import math
from PIL import Image, ImageDraw


# ── canvas ────────────────────────────────────────────────────────────────────
def new_canvas(w: int, h: int):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


# ── geometry helpers ────────────────────────────────────────────────────────
def _r(p):
    return (int(round(p[0])), int(round(p[1])))


def circ_bbox(p, r):
    x, y = _r(p)
    return (x - r, y - r, x + r + 1, y + r + 1)


def capsule_polygon(p0, p1, r):
    x0, y0 = _r(p0)
    x1, y1 = _r(p1)
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy)
    if L == 0:
        nx, ny = 1.0, 0.0
    else:
        nx, ny = -dy / L, dx / L
    return [
        (x0 + nx * r, y0 + ny * r),
        (x1 + nx * r, y1 + ny * r),
        (x1 - nx * r, y1 - ny * r),
        (x0 - nx * r, y0 - ny * r),
    ]


def fill_circle(draw, p, r, color):
    draw.ellipse(circ_bbox(p, r), fill=color)


def fill_poly(draw, pts, color):
    draw.polygon([_r(p) for p in pts], fill=color)


# ── shaded limb (capsule) ───────────────────────────────────────────────────
def capsule(draw, p0, p1, r, color, outline=None, light=None, loff=(-1, -1)):
    """Draw a shaded capsule limb from p0 to p1.

    color   : base (shadow) tone
    outline : 1px darker rim, drawn behind
    light   : top-left highlight sliver (narrower, offset up-left)
    """
    if outline is not None:
        fill_poly(draw, capsule_polygon(p0, p1, r + 1), outline)
        fill_circle(draw, p0, r + 1, outline)
        fill_circle(draw, p1, r + 1, outline)
    fill_poly(draw, capsule_polygon(p0, p1, r), color)
    fill_circle(draw, p0, r, color)
    fill_circle(draw, p1, r, color)
    if light is not None:
        p0b = (p0[0] + loff[0], p0[1] + loff[1])
        p1b = (p1[0] + loff[0], p1[1] + loff[1])
        fill_poly(draw, capsule_polygon(p0b, p1b, max(1, r - 1)), light)
        fill_circle(draw, p0b, max(1, r - 1), light)
        fill_circle(draw, p1b, max(1, r - 1), light)


def hline_limb(draw, p0, p1, w, color, outline=None, light=None):
    """Convenience: limb with half-width w (thickness = 2w)."""
    capsule(draw, p0, p1, w, color, outline=outline, light=light)


# ── ghost fire ────────────────────────────────────────────────────────────────
def ghost_fire(draw, cx, cy, size, t=0, palette=None):
    """Flickering underworld flame. t in [0,1) phase per frame.

    Returns nothing; draws in place. Used for enemy eye/gap fire, braziers,
    projectiles, and ambient VFX.
    """
    pal = palette or {
        "core": (150, 240, 170),
        "mid": (40, 200, 120),
        "out": (20, 110, 70),
        "edge": (10, 60, 45),
    }
    s = size
    flick = math.sin(t * math.pi * 2) * 0.18 + 1.0
    # outer glow
    fill_circle(draw, (cx, cy - s * 0.2), int(s * 0.9 * flick), pal["edge"])
    # body
    fill_circle(draw, (cx, cy - s * 0.25), int(s * 0.62 * flick), pal["out"])
    # teardrop tip
    tip = (cx, cy - s * (0.9 + 0.15 * flick))
    fill_poly(draw, [
        (cx - s * 0.4, cy),
        (cx + s * 0.4, cy),
        (cx + s * 0.18, cy - s * (1.5 + 0.2 * flick)),
        (cx - s * 0.18, cy - s * (1.5 + 0.2 * flick)),
    ], pal["out"])
    # inner
    fill_circle(draw, (cx, cy - s * 0.3), int(s * 0.4 * flick), pal["mid"])
    # core
    fill_circle(draw, (cx, cy - s * 0.35), int(s * 0.22 * flick), pal["core"])


def ghost_fire_eye(draw, cx, cy, size, t=0):
    ghost_fire(draw, cx, cy, size, t)


# ── small helpers ─────────────────────────────────────────────────────────────
def rect(draw, x, y, w, h, color):
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


def bake_sheet(frame_w, frame_h, frames, draw_fn, path):
    """Render a horizontal sprite sheet by calling draw_fn(draw, frame_index, ox, oy)."""
    from pathlib import Path
    sheet = Image.new("RGBA", (frame_w * frames, frame_h), (0, 0, 0, 0))
    for i in range(frames):
        ox = i * frame_w
        cell = sheet.crop((ox, 0, ox + frame_w, frame_h))
        d = ImageDraw.Draw(cell)
        draw_fn(d, i, frame_w, frame_h)
        sheet.paste(cell, (ox, 0))
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    return sheet
