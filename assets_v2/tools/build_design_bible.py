#!/usr/bin/env python3
"""Nine Nether V2 — Design Bible + Comparison sheets.

Per character directory, emit:
  concept_front.png   idle frame (front-facing)
  concept_side.png    mid-run/walk frame (action profile)
  concept_back.png    mirrored front (back approximation; true 3/4 not feasible
                      in pure side-scroller pixel art — flagged in metadata)
  silhouette.png      solid-black silhouette of the front pose
  palette.png         material palette swatches (hex)
  contact_sheet.png   every animation frame in a labelled grid

Plus review/ comparison sheets:
  character_scale_comparison.png   all 5 characters bottom-aligned on one ground line
  silhouette_comparison.png        all 5 black silhouettes for distinction check
"""

from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from pixel_engine import new_canvas

# import build modules (module-level only; build() not auto-run)
from build_player import PLAYER_CFG, IDLE as P_IDLE, RUN as P_RUN, render_humanoid
from build_melee_ghost import MELEE_CFG, IDLE as M_IDLE, WALK as M_WALK, render_humanoid
from build_ghost_archer import ARCHER_CFG, IDLE as A_IDLE, RETREAT as A_RETREAT, render_humanoid
from build_boss import BOSS_CFG, IDLE as B_IDLE, WALK as B_WALK, render_humanoid
from build_corpse_beast import BEAST_CFG, IDLE as C_IDLE, RUN as C_RUN, render_beast

ROOT = Path(__file__).resolve().parent.parent.parent
CHAR_DIR = ROOT / "assets_v2" / "characters"
REVIEW_DIR = ROOT / "assets_v2" / "review"

FONT = ImageFont.load_default()

# char -> (cfg, front_pose, side_pose, fn, fw, fh)
CHARS = {
    "player":        (PLAYER_CFG, P_IDLE[0], P_RUN[3], render_humanoid, 96, 96),
    "melee_ghost":   (MELEE_CFG, M_IDLE[0], M_WALK[3], render_humanoid, 96, 96),
    "ghost_archer":  (ARCHER_CFG, A_IDLE[0], A_RETREAT[3], render_humanoid, 96, 96),
    "corpse_beast":  (BEAST_CFG, C_IDLE[0], C_RUN[3], render_beast, 128, 96),
    "gate_warden":   (BOSS_CFG, B_IDLE[0], B_WALK[3], render_humanoid, 192, 192),
}


def render_pose(cfg, pose, fw, fh, fn):
    img, d = new_canvas(fw, fh)
    fn(d, cfg, pose, fw, fh)
    return img


def to_silhouette(img):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src = img.load()
    dst = out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = src[x, y]
            if a > 16:
                dst[x, y] = (0, 0, 0, 255)
    return out


def make_palette(cfg):
    pal = cfg["palette"]
    keys = list(pal.keys())
    cols = 4
    sw = 44
    step = 52
    rows = (len(keys) + cols - 1) // cols
    W = cols * step + 10
    H = rows * step + 10
    img, d = new_canvas(W, H)
    d.rectangle([0, 0, W - 1, H - 1], outline=(60, 60, 60))
    for i, k in enumerate(keys):
        r, c = divmod(i, cols)
        x = 6 + c * step
        y = 6 + r * step
        col = pal[k]
        d.rectangle([x, y, x + sw, y + sw], fill=col, outline=(0, 0, 0))
        hexs = "#%02X%02X%02X" % col
        d.text((x, y + sw + 2), f"{k}:{hexs}", fill=(210, 210, 210), font=FONT)
    return img


def make_contact_sheet(char):
    d = CHAR_DIR / char
    fw = fh = None
    # discover frame size from any sprite
    sheets = []
    for p in sorted(d.glob("*.png")):
        if p.name.startswith(("concept_", "silhouette", "palette", "contact_sheet")):
            continue
        im = Image.open(p)
        # robust frame_w from a known char size
        w, h = im.size
        if char == "corpse_beast":
            _fw, _fh = 128, 96
        elif char == "gate_warden":
            _fw, _fh = 192, 192
        else:
            _fw, _fh = 96, 96
        n = w // _fw
        sheets.append((p.name, im, _fw, _fh, n))
        if fw is None:
            fw, fh = _fw, _fh
    gap = 2
    label_h = 12
    maxn = max(n for _, _, _, _, n in sheets)
    cell_w = fw + gap
    cell_h = fh + gap
    W = 6 + maxn * cell_w
    H = 6 + len(sheets) * (cell_h + label_h)
    img, dr = new_canvas(W, H)
    for ri, (name, im, _fw, _fh, n) in enumerate(sheets):
        y0 = 6 + ri * (cell_h + label_h)
        dr.text((6, y0), name, fill=(220, 220, 220), font=FONT)
        for f in range(n):
            x0 = 6 + f * cell_w
            frame = im.crop((f * _fw, 0, f * _fw + _fw, _fh))
            img.paste(frame, (x0, y0 + label_h), frame)
    return img


def per_character():
    for char, (cfg, front_pose, side_pose, fn, fw, fh) in CHARS.items():
        d = CHAR_DIR / char
        front = render_pose(cfg, front_pose, fw, fh, fn)
        side = render_pose(cfg, side_pose, fw, fh, fn)
        back = front.transpose(Image.FLIP_LEFT_RIGHT)
        sil = to_silhouette(front)
        pal = make_palette(cfg)
        front.save(str(d / "concept_front.png"))
        side.save(str(d / "concept_side.png"))
        back.save(str(d / "concept_back.png"))
        sil.save(str(d / "silhouette.png"))
        pal.save(str(d / "palette.png"))
        make_contact_sheet(char).save(str(d / "contact_sheet.png"))
        print(f"  ok {char}: front/side/back/silhouette/palette/contact_sheet")


def comparisons():
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    # gather front poses + foot positions
    rows = []
    for char, (cfg, front_pose, _, fn, fw, fh) in CHARS.items():
        img = render_pose(cfg, front_pose, fw, fh, fn)
        rows.append((char, img, fw, fh))

    # scale comparison: bottom-aligned on one ground line
    pad = 20
    gap = 40
    ground = 360
    total_w = pad * 2 + sum(fw + gap for _, _, fw, _ in rows)
    scale_img, sd = new_canvas(total_w, ground + 40)
    sd.rectangle([0, 0, total_w - 1, ground + 39], fill=(18, 20, 26))
    sd.line([(0, ground), (total_w, ground)], fill=(70, 74, 84), width=2)
    x = pad
    for char, img, fw, fh in rows:
        y = ground - fh
        scale_img.paste(img, (x, y), img)
        sd.text((x + fw // 2 - len(char) * 3, ground + 6), char, fill=(200, 200, 200), font=FONT)
        x += fw + gap
    scale_img.save(str(REVIEW_DIR / "character_scale_comparison.png"))
    print("  ok review/character_scale_comparison.png")

    # silhouette comparison
    sil_img, _ = new_canvas(total_w, ground + 40)
    x = pad
    for char, img, fw, fh in rows:
        y = ground - fh
        sil = to_silhouette(img)
        sil_img.paste(sil, (x, y), sil)
        x += fw + gap
    sil_img.save(str(REVIEW_DIR / "silhouette_comparison.png"))
    print("  ok review/silhouette_comparison.png")


if __name__ == "__main__":
    print("per-character bible:")
    per_character()
    print("comparisons:")
    comparisons()
    print("done.")
