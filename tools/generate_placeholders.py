#!/usr/bin/env python3
"""
Nine Nether (九幽) — Placeholder Sprite Generator
Generates all prototype placeholder PNGs with correct dimensions.
Each placeholder uses a colored silhouette + checkerboard to indicate
the intended content, sized as horizontal sprite sheets for Godot import.

Run: python3 generate_placeholders.py
"""

from PIL import Image, ImageDraw
import os

ASSETS = os.path.join(os.path.dirname(__file__), "..", "assets")

# ── Palette ──────────────────────────────────────────────────────────────────
# Chinese dark fantasy — muted, desaturated
C_BG         = (15, 12, 18)    # near-black background
C_PLAYER     = (90, 50, 45)    # dark red-brown (Yue army)
C_PLAYER_LT  = (140, 80, 65)   # highlight
C_GHOST      = (45, 55, 70)    # cold blue-grey (ghost soldier)
C_GHOST_LT   = (70, 85, 105)
C_ARCHER     = (50, 60, 55)    # sickly green-grey
C_ARCHER_LT  = (75, 95, 85)
C_BEAST      = (55, 40, 35)    # dark fleshy brown
C_BEAST_LT   = (85, 60, 50)
C_BOSS       = (50, 30, 55)    # dark purple
C_BOSS_LT    = (90, 50, 100)
C_FIRE       = (180, 100, 30)  # ghost fire orange
C_FIRE_LT    = (220, 160, 60)
C_TILE       = (40, 35, 30)    # stone
C_TILE_LT    = (65, 55, 45)
C_WOOD       = (60, 40, 25)    # wood
C_WOOD_LT    = (90, 65, 40)
C_ICON       = (50, 45, 50)    # icon base
C_ICON_LT    = (100, 90, 100)
C_UI         = (30, 28, 35)    # ui element
C_UI_LT      = (80, 75, 90)
C_BG_DEEP    = (10, 8, 14)     # deep background
C_BG_TREE    = (20, 18, 22)
C_BG_TREE_LT = (35, 30, 35)
C_CHECKER_A  = (20, 18, 24)    # checkerboard dark
C_CHECKER_B  = (28, 25, 32)    # checkerboard light
C_PLACEHOLDER= (255, 0, 255)   # magenta = "replace me"


def checkerboard(draw, x0, y0, w, h, cell=4):
    """Draw a checkerboard pattern to indicate placeholder."""
    for cy in range(0, h, cell):
        for cx in range(0, w, cell):
            c = C_CHECKER_A if ((cx // cell) + (cy // cell)) % 2 == 0 else C_CHECKER_B
            draw.rectangle([x0 + cx, y0 + cy, x0 + cx + cell - 1, y0 + cy + cell - 1], fill=c)


def silhouette_rect(draw, x0, y0, w, h, color, lt_color):
    """Draw a simple humanoid silhouette within the frame."""
    cx = x0 + w // 2
    # head
    hs = max(6, w // 6)
    draw.ellipse([cx - hs // 2, y0 + h // 8, cx + hs // 2, y0 + h // 8 + hs], fill=color, outline=lt_color)
    # body
    bw = max(8, w // 4)
    bh = max(12, h // 3)
    draw.rectangle([cx - bw // 2, y0 + h // 8 + hs, cx + bw // 2, y0 + h // 8 + hs + bh], fill=color, outline=lt_color)
    # legs
    lw = max(4, w // 8)
    lh = max(8, h // 4)
    draw.rectangle([cx - bw // 2 + 1, y0 + h // 8 + hs + bh, cx - bw // 2 + 1 + lw, y0 + h // 8 + hs + bh + lh], fill=color)
    draw.rectangle([cx + bw // 2 - 1 - lw, y0 + h // 8 + hs + bh, cx + bw // 2 - 1, y0 + h // 8 + hs + bh + lh], fill=color)


def silhouette_beast(draw, x0, y0, w, h, color, lt_color):
    """Draw a quadruped beast silhouette."""
    body_h = h // 3
    body_y = y0 + h // 3
    draw.rectangle([x0 + w // 8, body_y, x0 + w - w // 8, body_y + body_h], fill=color, outline=lt_color)
    # head
    hs = max(6, w // 8)
    draw.ellipse([x0 + w - w // 8 - hs, body_y - hs // 2, x0 + w - w // 8, body_y + hs], fill=color, outline=lt_color)
    # legs
    lw = max(3, w // 12)
    lh = max(6, h // 5)
    for lx in [x0 + w // 6, x0 + w // 3, x0 + w - w // 3, x0 + w - w // 5]:
        draw.rectangle([lx, body_y + body_h, lx + lw, body_y + body_h + lh], fill=color)


def silhouette_boss(draw, x0, y0, w, h, color, lt_color):
    """Draw a large imposing boss silhouette."""
    cx = x0 + w // 2
    # large head with horns
    hs = max(10, w // 5)
    draw.ellipse([cx - hs // 2, y0 + h // 12, cx + hs // 2, y0 + h // 12 + hs], fill=color, outline=lt_color)
    # horns
    draw.polygon([(cx - hs // 2, y0 + h // 12), (cx - hs, y0 + h // 20), (cx - hs // 2 + 2, y0 + h // 12 + 2)], fill=lt_color)
    draw.polygon([(cx + hs // 2, y0 + h // 12), (cx + hs, y0 + h // 20), (cx + hs // 2 - 2, y0 + h // 12 + 2)], fill=lt_color)
    # massive body
    bw = max(16, w // 3)
    bh = max(20, h // 2)
    draw.rectangle([cx - bw // 2, y0 + h // 12 + hs, cx + bw // 2, y0 + h // 12 + hs + bh], fill=color, outline=lt_color)
    # legs
    lw = max(6, w // 8)
    lh = max(10, h // 5)
    draw.rectangle([cx - bw // 2 + 2, y0 + h // 12 + hs + bh, cx - bw // 2 + 2 + lw, y0 + h // 12 + hs + bh + lh], fill=color)
    draw.rectangle([cx + bw // 2 - 2 - lw, y0 + h // 12 + hs + bh, cx + bw // 2 - 2, y0 + h // 12 + hs + bh + lh], fill=color)
    # ghost fire aura
    draw.ellipse([cx - bw // 2 - 3, y0 + h // 12 + hs - 2, cx - bw // 2 + 1, y0 + h // 12 + hs + 2], fill=C_FIRE)
    draw.ellipse([cx + bw // 2 - 1, y0 + h // 12 + hs - 2, cx + bw // 2 + 3, y0 + h // 12 + hs + 2], fill=C_FIRE)


def draw_icon_simple(draw, x0, y0, size, shape, color, lt_color):
    """Draw simple icon shapes."""
    cx = x0 + size // 2
    cy = y0 + size // 2
    s = size // 3
    if shape == "sword":
        draw.line([cx - s, cy + s, cx + s, cy - s], fill=lt_color, width=2)
        draw.line([cx - s - 2, cy + s, cx + s + 2, cy - s], fill=color, width=1)
        draw.rectangle([cx - s - 3, cy + s - 1, cx - s + 1, cy + s + 3], fill=color)
    elif shape == "spear":
        draw.line([cx - s, cy + s, cx + s, cy - s], fill=lt_color, width=2)
        draw.polygon([(cx + s, cy - s), (cx + s + 3, cy - s - 2), (cx + s + 2, cy - s + 3)], fill=lt_color)
    elif shape == "fire":
        draw.ellipse([cx - s // 2, cy - s, cx + s // 2, cy + s], fill=color)
        draw.ellipse([cx - s // 3, cy - s // 2, cx + s // 3, cy + s // 2], fill=lt_color)
    elif shape == "talisman":
        draw.rectangle([cx - s // 2, cy - s, cx + s // 2, cy + s], fill=color, outline=lt_color)
        draw.line([cx, cy - s, cx, cy + s], fill=lt_color, width=1)
    elif shape == "gourd":
        draw.ellipse([cx - s // 2, cy - s // 3, cx + s // 2, cy + s], fill=color)
        draw.rectangle([cx - 1, cy - s, cx + 1, cy - s // 3], fill=color)
    elif shape == "flag":
        draw.line([cx - s, cy - s, cx - s, cy + s], fill=lt_color, width=1)
        draw.polygon([(cx - s, cy - s), (cx + s, cy - s // 2), (cx - s, cy)], fill=color)
    elif shape == "heart":
        draw.ellipse([cx - s, cy - s // 2, cx, cy + s // 2], fill=color)
        draw.ellipse([cx, cy - s // 2, cx + s, cy + s // 2], fill=color)
        draw.polygon([(cx - s, cy), (cx + s, cy), (cx, cy + s)], fill=color)
    elif shape == "stamina":
        draw.ellipse([cx - s, cy - s, cx + s, cy + s], fill=color, outline=lt_color)
        draw.line([cx - s // 2, cy, cx + s // 2, cy], fill=lt_color, width=1)
    elif shape == "attack":
        draw.polygon([(cx, cy - s), (cx + s, cy + s), (cx - s, cy + s)], fill=color, outline=lt_color)
    elif shape == "armor":
        draw.polygon([(cx, cy - s), (cx + s, cy - s // 2), (cx + s // 2, cy + s), (cx - s // 2, cy + s), (cx - s, cy - s // 2)], fill=color, outline=lt_color)
    elif shape == "crit":
        draw.line([cx, cy - s, cx, cy + s], fill=lt_color, width=2)
        draw.line([cx - s, cy, cx + s, cy], fill=lt_color, width=2)
        draw.line([cx - s, cy - s, cx + s, cy + s], fill=color, width=1)
        draw.line([cx - s, cy + s, cx + s, cy - s], fill=color, width=1)
    elif shape == "speed":
        draw.polygon([(cx - s, cy - s), (cx + s, cy), (cx - s, cy + s)], fill=color, outline=lt_color)
    elif shape == "sacrifice":
        draw.ellipse([cx - s, cy - s, cx + s, cy + s], outline=lt_color, width=1)
        draw.line([cx, cy - s, cx, cy + s], fill=color, width=1)
        draw.line([cx - s, cy, cx + s, cy], fill=color, width=1)
    elif shape == "boss":
        draw.ellipse([cx - s, cy - s, cx + s, cy + s], fill=color, outline=lt_color)
        draw.line([cx - s, cy - s, cx - s - 2, cy - s - 3], fill=lt_color, width=1)
        draw.line([cx + s, cy - s, cx + s + 2, cy - s - 3], fill=lt_color, width=1)
    elif shape == "key":
        draw.ellipse([cx - s, cy - s, cx, cy], outline=lt_color, width=1)
        draw.line([cx, cy, cx + s, cy], fill=lt_color, width=1)
        draw.line([cx + s, cy, cx + s, cy + 2], fill=lt_color, width=1)
    elif shape == "coin":
        draw.ellipse([cx - s, cy - s, cx + s, cy + s], fill=color, outline=lt_color)
        draw.rectangle([cx - 1, cy - s // 2, cx + 1, cy + s // 2], fill=lt_color)


def draw_tile(draw, x0, y0, size, kind, color, lt_color):
    """Draw tile placeholders."""
    if kind == "floor":
        draw.rectangle([x0, y0, x0 + size - 1, y0 + size - 1], fill=color)
        draw.rectangle([x0 + 2, y0 + 2, x0 + size - 3, y0 + size - 3], outline=lt_color, width=1)
        draw.line([x0 + size // 2, y0 + 2, x0 + size // 2, y0 + size - 3], fill=lt_color, width=1)
    elif kind == "brick":
        draw.rectangle([x0, y0, x0 + size - 1, y0 + size - 1], fill=color)
        draw.line([x0, y0 + size // 2, x0 + size, y0 + size // 2], fill=lt_color, width=1)
        draw.line([x0 + size // 2, y0, x0 + size // 2, y0 + size // 2], fill=lt_color, width=1)
        draw.line([x0 + size // 4, y0 + size // 2, x0 + size // 4, y0 + size], fill=lt_color, width=1)
        draw.line([x0 + 3 * size // 4, y0 + size // 2, x0 + 3 * size // 4, y0 + size], fill=lt_color, width=1)
    elif kind == "wall":
        draw.rectangle([x0, y0, x0 + size - 1, y0 + size - 1], fill=color)
        for i in range(0, size, 4):
            draw.line([x0 + i, y0, x0 + i, y0 + size - 1], fill=lt_color, width=1)
    elif kind == "bridge":
        draw.rectangle([x0, y0, x0 + size - 1, y0 + size - 1], fill=color)
        for i in range(0, size, 6):
            draw.line([x0, y0 + i, x0 + size, y0 + i], fill=lt_color, width=1)
    elif kind == "brazier":
        draw.rectangle([x0 + size // 4, y0 + size // 3, x0 + 3 * size // 4, y0 + 2 * size // 3], fill=color, outline=lt_color)
        draw.ellipse([x0 + size // 3, y0 + size // 6, x0 + 2 * size // 3, y0 + size // 3], fill=C_FIRE)
    elif kind == "tombstone":
        draw.pieslice([x0 + size // 4, y0, x0 + 3 * size // 4, y0 + size], 180, 360, fill=color, outline=lt_color)
        draw.rectangle([x0 + size // 4, y0 + size // 2, x0 + 3 * size // 4, y0 + size - 2], fill=color)
    elif kind == "spike":
        for i in range(0, size, 8):
            draw.polygon([(x0 + i, y0 + size), (x0 + i + 4, y0 + size // 3), (x0 + i + 8, y0 + size)], fill=lt_color)


def draw_effect(draw, x0, y0, size, kind, color, lt_color):
    """Draw effect placeholders."""
    cx = x0 + size // 2
    cy = y0 + size // 2
    s = size // 3
    if kind == "slash":
        draw.line([cx - s, cy + s, cx + s, cy - s], fill=lt_color, width=3)
        draw.line([cx - s + 1, cy + s, cx + s + 1, cy - s], fill=color, width=1)
    elif kind == "blood":
        for dx in range(-s, s, 3):
            for dy in range(-s, s, 3):
                if (dx * dx + dy * dy) < s * s:
                    draw.point([cx + dx, cy + dy], fill=color)
    elif kind == "ghostfire":
        draw.ellipse([cx - s, cy - s, cx + s, cy + s], fill=color)
        draw.ellipse([cx - s // 2, cy - s // 2, cx + s // 2, cy + s // 2], fill=lt_color)
    elif kind == "deathfade":
        for i in range(size):
            alpha = max(0, 255 - i * 8)
            draw.line([x0 + i, y0, x0 + i, y0 + size - 1], fill=color)


def draw_background(draw, x0, y0, w, h, kind, color, lt_color):
    """Draw background element placeholders."""
    if kind == "tree":
        # trunk
        tw = max(4, w // 10)
        draw.rectangle([x0 + w // 2 - tw // 2, y0 + h // 2, x0 + w // 2 + tw // 2, y0 + h - 1], fill=color)
        # canopy
        draw.ellipse([x0 + w // 6, y0, x0 + 5 * w // 6, y0 + h // 2 + h // 8], fill=color, outline=lt_color)
    elif kind == "flag":
        draw.line([x0 + w // 4, y0, x0 + w // 4, y0 + h - 1], fill=lt_color, width=2)
        draw.polygon([(x0 + w // 4, y0 + h // 6), (x0 + 3 * w // 4, y0 + h // 4), (x0 + w // 4, y0 + h // 2)], fill=color)
        # ragged edge
        for i in range(0, w // 2, 6):
            draw.line([x0 + w // 4 + i, y0 + h // 2, x0 + w // 4 + i + 3, y0 + h // 2 + 4], fill=color, width=1)
    elif kind == "chains":
        for i in range(0, h, 8):
            draw.ellipse([x0 + w // 4, y0 + i, x0 + 3 * w // 4, y0 + i + 6], outline=lt_color, width=1)
    elif kind == "deep":
        draw.rectangle([x0, y0, x0 + w - 1, y0 + h - 1], fill=color)
        # distant mountains
        for mx in range(0, w, 40):
            draw.polygon([(x0 + mx, y0 + h), (x0 + mx + 20, y0 + h // 2), (x0 + mx + 40, y0 + h)], fill=lt_color)
        # mist
        for my in range(h // 2, h, 8):
            draw.line([x0, y0 + my, x0 + w, y0 + my], fill=(20, 18, 24), width=1)


def draw_ui(draw, x0, y0, w, h, kind, color, lt_color):
    """Draw UI element placeholders."""
    if kind == "bar":
        draw.rectangle([x0, y0, x0 + w - 1, y0 + h - 1], outline=lt_color, width=1)
        draw.rectangle([x0 + 1, y0 + 1, x0 + w // 2, y0 + h - 2], fill=color)
    elif kind == "frame":
        draw.rectangle([x0, y0, x0 + w - 1, y0 + h - 1], outline=lt_color, width=2)
        draw.rectangle([x0 + 3, y0 + 3, x0 + w - 4, y0 + h - 4], outline=color, width=1)


def save_img(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  ✓ {os.path.relpath(path, os.path.dirname(ASSETS))}")


# ═══════════════════════════════════════════════════════════════════════════════
# GENERATE SPRITE SHEETS
# ═══════════════════════════════════════════════════════════════════════════════

def gen_spritesheet(path, frame_w, frame_h, frames, color, lt_color, kind="human"):
    """Generate a horizontal sprite sheet with N frames."""
    total_w = frame_w * frames
    img = Image.new("RGBA", (total_w, frame_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for f in range(frames):
        x0 = f * frame_w
        checkerboard(draw, x0, 0, frame_w, frame_h, cell=4)
        # magenta border per frame
        draw.rectangle([x0, 0, x0 + frame_w - 1, frame_h - 1], outline=C_PLACEHOLDER, width=1)
        if kind == "human":
            silhouette_rect(draw, x0, 0, frame_w, frame_h, color, lt_color)
        elif kind == "beast":
            silhouette_beast(draw, x0, 0, frame_w, frame_h, color, lt_color)
        elif kind == "boss":
            silhouette_boss(draw, x0, 0, frame_w, frame_h, color, lt_color)
    save_img(img, path)


def gen_single(path, w, h, draw_fn, *args):
    """Generate a single-frame image."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_fn(draw, 0, 0, w, h, *args)
    save_img(img, path)


def gen_icon(path, shape, color=C_ICON, lt_color=C_ICON_LT):
    """Generate a 32x32 icon."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    checkerboard(draw, 0, 0, 32, 32, cell=4)
    draw.rectangle([0, 0, 31, 31], outline=C_PLACEHOLDER, width=1)
    draw_icon_simple(draw, 0, 0, 32, shape, color, lt_color)
    save_img(img, path)


def gen_tile(path, kind, color=C_TILE, lt_color=C_TILE_LT):
    """Generate a 32x32 tile."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    checkerboard(draw, 0, 0, 32, 32, cell=4)
    draw.rectangle([0, 0, 31, 31], outline=C_PLACEHOLDER, width=1)
    draw_tile(draw, 0, 0, 32, kind, color, lt_color)
    save_img(img, path)


def gen_effect(path, kind, color=C_FIRE, lt_color=C_FIRE_LT):
    """Generate a 48x48 effect."""
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    checkerboard(draw, 0, 0, 48, 48, cell=4)
    draw.rectangle([0, 0, 47, 47], outline=C_PLACEHOLDER, width=1)
    draw_effect(draw, 0, 0, 48, kind, color, lt_color)
    save_img(img, path)


# ── Player ───────────────────────────────────────────────────────────────────
print("\n=== Player Sprites ===")
P = os.path.join(ASSETS, "player")
gen_spritesheet(f"{P}/player_idle.png",   48, 48, 4, C_PLAYER, C_PLAYER_LT)
gen_spritesheet(f"{P}/player_run.png",    48, 48, 6, C_PLAYER, C_PLAYER_LT)
gen_spritesheet(f"{P}/player_jump.png",   48, 48, 2, C_PLAYER, C_PLAYER_LT)
gen_spritesheet(f"{P}/player_attack.png", 48, 48, 4, C_PLAYER, C_PLAYER_LT)
gen_spritesheet(f"{P}/player_hurt.png",   48, 48, 2, C_PLAYER, C_PLAYER_LT)
gen_spritesheet(f"{P}/player_death.png",  48, 48, 6, C_PLAYER, C_PLAYER_LT)

# ── Enemy: Ghost Soldier (鬼卒) ──────────────────────────────────────────────
print("\n=== Enemy: Ghost Soldier ===")
E = os.path.join(ASSETS, "enemy")
gen_spritesheet(f"{E}/ghost_melee_idle.png",   48, 48, 4, C_GHOST, C_GHOST_LT)
gen_spritesheet(f"{E}/ghost_melee_run.png",    48, 48, 6, C_GHOST, C_GHOST_LT)
gen_spritesheet(f"{E}/ghost_melee_attack.png", 48, 48, 4, C_GHOST, C_GHOST_LT)
gen_spritesheet(f"{E}/ghost_melee_hurt.png",   48, 48, 2, C_GHOST, C_GHOST_LT)
gen_spritesheet(f"{E}/ghost_melee_death.png",  48, 48, 4, C_GHOST, C_GHOST_LT)

# ── Enemy: Ghost Archer (鬼弓手) ─────────────────────────────────────────────
print("\n=== Enemy: Ghost Archer ===")
gen_spritesheet(f"{E}/ghost_archer_idle.png",   48, 48, 4, C_ARCHER, C_ARCHER_LT)
gen_spritesheet(f"{E}/ghost_archer_run.png",    48, 48, 6, C_ARCHER, C_ARCHER_LT)
gen_spritesheet(f"{E}/ghost_archer_attack.png", 48, 48, 4, C_ARCHER, C_ARCHER_LT)
gen_spritesheet(f"{E}/ghost_archer_hurt.png",   48, 48, 2, C_ARCHER, C_ARCHER_LT)
gen_spritesheet(f"{E}/ghost_archer_death.png",  48, 48, 4, C_ARCHER, C_ARCHER_LT)

# ── Enemy: Corpse Beast (尸兽) ───────────────────────────────────────────────
print("\n=== Enemy: Corpse Beast ===")
gen_spritesheet(f"{E}/corpse_beast_idle.png",   64, 48, 4, C_BEAST, C_BEAST_LT, kind="beast")
gen_spritesheet(f"{E}/corpse_beast_run.png",    64, 48, 6, C_BEAST, C_BEAST_LT, kind="beast")
gen_spritesheet(f"{E}/corpse_beast_attack.png", 64, 48, 4, C_BEAST, C_BEAST_LT, kind="beast")
gen_spritesheet(f"{E}/corpse_beast_hurt.png",   64, 48, 2, C_BEAST, C_BEAST_LT, kind="beast")
gen_spritesheet(f"{E}/corpse_beast_death.png",  64, 48, 4, C_BEAST, C_BEAST_LT, kind="beast")

# ── Boss: Gate Guardian Ghost General (镇关鬼将) ─────────────────────────────
print("\n=== Boss ===")
B = os.path.join(ASSETS, "boss")
gen_spritesheet(f"{B}/boss_idle.png",   96, 96, 4, C_BOSS, C_BOSS_LT, kind="boss")
gen_spritesheet(f"{B}/boss_run.png",    96, 96, 6, C_BOSS, C_BOSS_LT, kind="boss")
gen_spritesheet(f"{B}/boss_attack.png", 96, 96, 5, C_BOSS, C_BOSS_LT, kind="boss")
gen_spritesheet(f"{B}/boss_hurt.png",   96, 96, 2, C_BOSS, C_BOSS_LT, kind="boss")
gen_spritesheet(f"{B}/boss_death.png",  96, 96, 8, C_BOSS, C_BOSS_LT, kind="boss")

# ── Weapon Icons ─────────────────────────────────────────────────────────────
print("\n=== Weapon Icons ===")
W = os.path.join(ASSETS, "icons", "weapons")
gen_icon(f"{W}/weapon_songdao.png",     "sword")
gen_icon(f"{W}/weapon_spear.png",       "spear")
gen_icon(f"{W}/weapon_ghostfire.png",   "fire",     C_FIRE, C_FIRE_LT)
gen_icon(f"{W}/weapon_talisman.png",    "talisman")
gen_icon(f"{W}/weapon_gourd.png",       "gourd")
gen_icon(f"{W}/weapon_flag.png",        "flag")

# ── UI Icons ─────────────────────────────────────────────────────────────────
print("\n=== UI Icons ===")
U = os.path.join(ASSETS, "icons", "ui")
gen_icon(f"{U}/icon_hp.png",        "heart")
gen_icon(f"{U}/icon_stamina.png",   "stamina")
gen_icon(f"{U}/icon_attack.png",    "attack")
gen_icon(f"{U}/icon_armor.png",     "armor")
gen_icon(f"{U}/icon_crit.png",      "crit")
gen_icon(f"{U}/icon_speed.png",     "speed")
gen_icon(f"{U}/icon_sacrifice.png", "sacrifice", C_BOSS, C_BOSS_LT)
gen_icon(f"{U}/icon_ghostfire.png", "fire",      C_FIRE, C_FIRE_LT)
gen_icon(f"{U}/icon_boss.png",      "boss",      C_BOSS, C_BOSS_LT)
gen_icon(f"{U}/icon_key.png",       "key")
gen_icon(f"{U}/icon_coin.png",      "coin")

# ── Tiles ────────────────────────────────────────────────────────────────────
print("\n=== Tiles ===")
T = os.path.join(ASSETS, "tiles")
gen_tile(f"{T}/tile_floor.png",        "floor")
gen_tile(f"{T}/tile_stone_brick.png",  "brick")
gen_tile(f"{T}/tile_wall.png",         "wall",      C_TILE, C_TILE_LT)
gen_tile(f"{T}/tile_wood_bridge.png",  "bridge",    C_WOOD, C_WOOD_LT)
gen_tile(f"{T}/tile_brazier.png",      "brazier",   C_TILE, C_TILE_LT)
gen_tile(f"{T}/tile_tombstone.png",    "tombstone", C_TILE, C_TILE_LT)
gen_tile(f"{T}/tile_ground_spike.png", "spike",     C_TILE, C_TILE_LT)

# ── Effects ──────────────────────────────────────────────────────────────────
print("\n=== Effects ===")
F = os.path.join(ASSETS, "effects")
gen_effect(f"{F}/effect_hit_slash.png",    "slash",     (180, 180, 180), (220, 220, 220))
gen_effect(f"{F}/effect_blood_splash.png","blood",     (120, 20, 20),   (160, 40, 40))
gen_effect(f"{F}/effect_ghost_fire.png",  "ghostfire", C_FIRE,          C_FIRE_LT)
gen_effect(f"{F}/effect_death_fade.png",  "deathfade", (60, 50, 70),    (90, 80, 110))

# ── Background ───────────────────────────────────────────────────────────────
print("\n=== Background ===")
BG = os.path.join(ASSETS, "background")
gen_single(f"{BG}/bg_tree.png",        64, 128, draw_background, "tree", C_BG_TREE, C_BG_TREE_LT)
gen_single(f"{BG}/bg_broken_flag.png", 48,  96, draw_background, "flag", (50, 35, 30), (80, 55, 45))
gen_single(f"{BG}/bg_chains.png",      32,  96, draw_background, "chains", (40, 40, 45), (70, 70, 80))
gen_single(f"{BG}/bg_deep.png",       320, 180, draw_background, "deep",  C_BG_DEEP, (20, 18, 26))

# ── UI Elements ──────────────────────────────────────────────────────────────
print("\n=== UI Elements ===")
UI = os.path.join(ASSETS, "ui")
gen_single(f"{UI}/ui_health_bar.png",     96, 16, draw_ui, "bar",   (120, 20, 20),  (160, 40, 40))
gen_single(f"{UI}/ui_stamina_bar.png",    96, 16, draw_ui, "bar",   (20, 100, 60),  (40, 140, 80))
gen_single(f"{UI}/ui_frame.png",          32, 32, draw_ui, "frame", C_UI, C_UI_LT)
gen_single(f"{UI}/ui_minimap_frame.png",  64, 64, draw_ui, "frame", C_UI, C_UI_LT)

print("\n✅ All placeholder images generated.")
print(f"   Total files: {sum(1 for _ in os.walk(ASSETS) for __ in _[2])}")
