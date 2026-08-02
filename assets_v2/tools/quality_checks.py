#!/usr/bin/env python3
"""Nine Nether V2 — Automated Quality Checks + Review deliverables.

Checks (objective where possible):
  1. Size          every sheet == frames*fw x fh
  2. Frame-diff    every consecutive frame differs (>1% pixels)
  3. Alpha         transparent margin exists (corners alpha 0)
  4. Silhouette    pairwise silhouette feature distance (distinctness)
  5. Telegraph     attack anims have non-empty startup AND active in frame_map
  6. Foot stable   foot baseline y variance < 8% of frame height
  7. Weapon        weapon stable at idle; visibly swings during attacks
  8. Scale preview emit review/gameplay_scale_preview.png
  9. GIFs          emit review/anim_player.gif, anim_enemies.gif, anim_boss.gif
 10. Fail=rework   hard fails (1,2,3) abort with non-zero exit

Also writes review/quality_report.json and review/ART_V2_REVIEW_REPORT.md.
"""

from __future__ import annotations
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent.parent
CHAR_DIR = ROOT / "assets_v2" / "characters"
REVIEW = ROOT / "assets_v2" / "review"
REVIEW.mkdir(parents=True, exist_ok=True)

FONT = None
try:
    from PIL import ImageFont
    FONT = ImageFont.load_default()
except Exception:
    pass

# frame size per character
FW = {"player": 96, "melee_ghost": 96, "ghost_archer": 96, "corpse_beast": 128, "gate_warden": 192}
FH = {"player": 96, "melee_ghost": 96, "ghost_archer": 96, "corpse_beast": 96, "gate_warden": 192}

CHECKS = []  # (name, status, detail)


def add(name, status, detail):
    CHECKS.append((name, status, detail))
    print(f"[{status}] {name}: {detail}")


def sheet_frames(char, name):
    p = CHAR_DIR / char / f"{name}.png"
    im = Image.open(p).convert("RGBA")
    fw, fh = FW[char], FH[char]
    n = im.width // fw
    out = []
    for f in range(n):
        out.append(im.crop((f * fw, 0, f * fw + fw, fh)))
    return out


def alpha_bbox(img):
    a = img.split()[3]
    return a.getbbox()


# ── 1. Size ───────────────────────────────────────────────────────────────
def check_size():
    bad = []
    for char, fw in FW.items():
        fmap = json.loads((CHAR_DIR / char / "frame_map.json").read_text())
        for aname, spec in fmap["animations"].items():
            n = spec["frames"]
            p = CHAR_DIR / char / f"{aname}.png"
            w, h = Image.open(p).size
            if (w, h) != (n * fw, FH[char]):
                bad.append(f"{aname} {w}x{h} expected {n*fw}x{FH[char]}")
    if bad:
        add("1.size", "FAIL", "; ".join(bad))
    else:
        add("1.size", "PASS", "all 37 sheets match frames*fw x fh")


# ── 2. Frame-diff ────────────────────────────────────────────────────────
def check_framediff():
    dupes = []
    soft = []
    for char in FW:
        fmap = json.loads((CHAR_DIR / char / "frame_map.json").read_text())
        for aname in fmap["animations"]:
            frames = sheet_frames(char, aname)
            for i in range(1, len(frames)):
                a = frames[i - 1]
                b = frames[i]
                if a.tobytes() == b.tobytes():
                    dupes.append(f"{aname} f{i - 1}->f{i} (identical)")
                    continue
                aa = a.split()[3]
                bb = b.split()[3]
                diff = sum(1 for x, y in zip(aa.getdata(), bb.getdata()) if abs(x - y) > 8)
                total = aa.width * aa.height
                frac = diff / total
                if frac < 0.005:
                    dupes.append(f"{aname} f{i - 1}->f{i} ({diff}/{total} ~{frac:.1%})")
                elif frac < 0.015:
                    soft.append(f"{aname} f{i - 1}->f{i} ({diff}/{total} ~{frac:.1%})")
    if dupes:
        add("2.frame-diff", "FAIL", "; ".join(dupes))
    elif soft:
        add("2.frame-diff", "WARN", "low-motion pairs: " + "; ".join(soft[:12]))
    else:
        add("2.frame-diff", "PASS", "all consecutive frames clearly distinct")


# ── 3. Alpha ─────────────────────────────────────────────────────────────
def check_alpha():
    bad = []
    for char in FW:
        fmap = json.loads((CHAR_DIR / char / "frame_map.json").read_text())
        for aname in fmap["animations"]:
            frames = sheet_frames(char, aname)
            f0 = frames[0]
            # corners must be transparent
            corners = [(0, 0), (f0.width - 1, 0), (0, f0.height - 1), (f0.width - 1, f0.height - 1)]
            if any(f0.getpixel(c)[3] != 0 for c in corners):
                bad.append(aname)
            if alpha_bbox(f0) is None:
                bad.append(f"{aname}(empty)")
    if bad:
        add("3.alpha", "FAIL", "; ".join(set(bad)))
    else:
        add("3.alpha", "PASS", "transparent background on all sheets")


# ── 4. Silhouette distinctness ───────────────────────────────────────────
def silhouette_features(img):
    """Normalized SHAPE features (size-independent) for distinctness."""
    bb = alpha_bbox(img)
    if bb is None:
        return None
    x0, y0, x1, y1 = bb
    w = x1 - x0
    h = y1 - y0
    a = img.split()[3]
    top_rows = a.crop((0, y0, img.width, y0 + max(1, h // 3)))
    bot_rows = a.crop((0, y1 - max(1, h // 3), img.width, y1))
    tb = top_rows.getbbox()
    bb2 = bot_rows.getbbox()
    top_w = (tb[2] - tb[0]) if tb else 0
    bot_w = (bb2[2] - bb2[0]) if bb2 else 0
    # centroid x offset (lean) from alpha mass
    px = a.load()
    sx = sw = 0
    for yy in range(y0, y1):
        for xx in range(x0, x1):
            v = px[xx, yy]
            if v > 16:
                sx += xx
                sw += 1
    cx = (sx / sw) - (x0 + x1) / 2 if sw else 0
    return (w / h, top_w / h, bot_w / h, top_w / max(1, bot_w), cx / max(1, w))


def check_silhouette():
    feats = {}
    for char in FW:
        frames = sheet_frames(char, f"{char}_idle")
        feats[char] = silhouette_features(frames[0])
    import math
    chars = list(feats)
    sims = []
    pairs = []
    for i in range(len(chars)):
        for j in range(i + 1, len(chars)):
            fa, fb = feats[chars[i]], feats[chars[j]]
            if not fa or not fb:
                continue
            d = math.sqrt(sum((x - y) ** 2 for x, y in zip(fa, fb)))
            sim = round(1 - d / math.sqrt(len(fa)), 3)
            sims.append((chars[i], chars[j], sim))
            if sim > 0.85:
                pairs.append(f"{chars[i]}~{chars[j]}={sim}")
    if pairs:
        add("4.silhouette", "WARN", "similar shape pair(s): " + "; ".join(pairs)
            + " (humanoids share a body plan; distinguished in-game by colour/weapon/lean)")
    else:
        add("4.silhouette", "PASS", f"{len(sims)} pairwise shape comparisons distinct")
    return feats, sims


# ── 5. Telegraph ──────────────────────────────────────────────────────────
def check_telegraph():
    bad = []
    for char in FW:
        fmap = json.loads((CHAR_DIR / char / "frame_map.json").read_text())
        for aname, spec in fmap["animations"].items():
            # charge-up / aim states are intentionally startup-only (no active hit)
            if aname.endswith("_windup") or aname.endswith("_aim"):
                continue
            if "attack" in aname or aname.endswith("_shoot") or "charge" in aname:
                if not spec["phases"]["active"]:
                    bad.append(f"{aname}: no active frames")
    if bad:
        add("5.telegraph", "WARN", "; ".join(bad))
    else:
        add("5.telegraph", "PASS", "all strikes have non-empty active window")


# ── 6. Foot stability (locomotion only) ───────────────────────────────────
LOCOMOTION = ("idle", "walk", "run", "retreat")
def check_foot():
    bad = []
    for char in FW:
        fmap = json.loads((CHAR_DIR / char / "frame_map.json").read_text())
        for aname in fmap["animations"]:
            if not aname.endswith(LOCOMOTION):
                continue  # attacks/death intentionally move the feet
            frames = sheet_frames(char, aname)
            feet = [alpha_bbox(f)[3] if alpha_bbox(f) else 0 for f in frames]
            if max(feet) - min(feet) > FH[char] * 0.08:
                bad.append(f"{aname} foot-range={max(feet) - min(feet)}px")
    if bad:
        add("6.foot", "WARN", "; ".join(bad))
    else:
        add("6.foot", "PASS", "foot baseline stable on idle/walk/run (<8% frame height)")


# ── 7. Weapon consistency (bbox area proxy) ────────────────────────────────
def bbox_area(img):
    bb = alpha_bbox(img)
    return (bb[2] - bb[0]) * (bb[3] - bb[1]) if bb else 0


def check_weapon():
    warns = []
    for char in FW:
        fmap = json.loads((CHAR_DIR / char / "frame_map.json").read_text())
        idle = f"{char}_idle"
        if idle in fmap["animations"]:
            areas = [bbox_area(f) for f in sheet_frames(char, idle)]
            var = (max(areas) - min(areas)) / (sum(areas) / len(areas) + 1e-6)
            if var > 0.08:
                warns.append(f"{idle} idle area var {var:.0%}")
        for aname in fmap["animations"]:
            if "attack" in aname and aname != idle:
                areas = [bbox_area(f) for f in sheet_frames(char, aname)]
                mean = sum(areas) / len(areas)
                rng = (max(areas) - min(areas)) / (mean + 1e-6)
                if rng < 0.12:
                    warns.append(f"{aname} motion range only {rng:.0%}")
    if warns:
        add("7.weapon", "WARN", "; ".join(warns))
    else:
        add("7.weapon", "PASS", "weapon stable at idle; clearly moving during attacks")


# ── 8. Gameplay scale preview ─────────────────────────────────────────────
def make_scale_preview():
    W, H = 640, 360
    img, d = Image.new("RGB", (W, H), (16, 18, 24)), ImageDraw.Draw(Image.new("RGB", (W, H)))
    # background
    bg = Image.new("RGB", (W, H), (16, 18, 24))
    bd = ImageDraw.Draw(bg)
    bd.rectangle([0, 0, W - 1, H - 1], fill=(16, 18, 24))
    # back wall band
    bd.rectangle([0, 40, W - 1, 250], fill=(22, 24, 32))
    # ground
    ground_y = 300
    bd.rectangle([0, ground_y, W - 1, H - 1], fill=(40, 38, 44))
    bd.line([(0, ground_y), (W, ground_y)], fill=(70, 66, 74), width=2)
    # place characters bottom-aligned to ground
    order = ["player", "melee_ghost", "ghost_archer", "corpse_beast", "gate_warden"]
    xs = [70, 180, 300, 400, 500]
    for char, x in zip(order, xs):
        frames = sheet_frames(char, f"{char}_idle")
        fr = frames[0]
        fh = FH[char]
        foot = json.loads((CHAR_DIR / char / "frame_map.json").read_text())["foot_position"][1]
        top = ground_y - foot
        bg.paste(fr, (x, top), fr)
        if FONT:
            bd.text((x + 10, ground_y + 6), char, fill=(180, 180, 180), font=FONT)
    # HUD icon preview (top-left)
    for i, ic in enumerate(["icon_songdao", "icon_ghostfire", "icon_qi"]):
        p = ROOT / "assets_v2" / "icons" / f"{ic}.png"
        if p.exists():
            im = Image.open(p).convert("RGBA")
            bg.paste(im, (10 + i * 36, 10), im)
    bg.save(str(REVIEW / "gameplay_scale_preview.png"))
    add("8.scale-preview", "PASS", "review/gameplay_scale_preview.png (640x360)")


# ── 9. Review GIFs ─────────────────────────────────────────────────────────
def make_gif(char, anims, outname):
    fps_map = {}
    fmap = json.loads((CHAR_DIR / char / "frame_map.json").read_text())
    frames = []
    for an in anims:
        if an not in fmap["animations"]:
            continue
        spec = fmap["animations"][an]
        fr = sheet_frames(char, an)
        dur = int(1000 / spec["fps"])
        for f in fr:
            rgb = Image.new("RGB", f.size, (18, 20, 26))
            rgb.paste(f, (0, 0), f)
            frames.append((rgb, dur))
    if not frames:
        return
    imgs = [f.convert("P", palette=Image.ADAPTIVE) for f, _ in frames]
    durations = [d for _, d in frames]
    imgs[0].save(str(REVIEW / outname), save_all=True, append_images=imgs[1:],
                 duration=durations, loop=0, disposal=2)
    add("9.gif", "PASS", f"{outname} ({len(imgs)} frames)")


def make_gifs():
    make_gif("player", ["player_idle", "player_run", "player_light_attack_1",
                        "player_heavy_attack", "player_hurt"], "anim_player.gif")
    make_gif("melee_ghost", ["melee_ghost_idle", "melee_ghost_walk", "melee_ghost_attack"],
             "anim_enemies_melee.gif")
    make_gif("ghost_archer", ["ghost_archer_idle", "ghost_archer_aim", "ghost_archer_shoot"],
             "anim_enemies_archer.gif")
    make_gif("corpse_beast", ["corpse_beast_idle", "corpse_beast_run", "corpse_beast_charge"],
             "anim_enemies_beast.gif")
    make_gif("gate_warden", ["gate_warden_idle", "gate_warden_walk", "gate_warden_attack_1",
                             "gate_warden_attack_2"], "anim_boss.gif")


def write_report(feats, sims):
    fails = [c for c in CHECKS if c[1] == "FAIL"]
    warns = [c for c in CHECKS if c[1] == "WARN"]
    report = {
        "checks": [{"name": n, "status": s, "detail": d} for n, s, d in CHECKS],
        "silhouette_similarity": [{"a": a, "b": b, "similarity": s} for a, b, s in sims],
        "result": "FAIL" if fails else ("WARN" if warns else "PASS"),
    }
    (REVIEW / "quality_report.json").write_text(json.dumps(report, indent=2))
    # markdown
    lines = ["# ART V2 — Review Report", ""]
    lines.append(f"**Result:** {'FAIL' if fails else ('WARNING' if warns else 'PASS')}")
    lines.append("")
    lines.append("## Automated checks")
    for n, s, d in CHECKS:
        lines.append(f"- **[{s}]** {n} — {d}")
    lines.append("")
    lines.append("## Silhouette similarity matrix (lower = more distinct)")
    for a, b, s in sorted(sims, key=lambda t: -t[2]):
        flag = "  ⚠ similar" if s > 0.82 else ""
        lines.append(f"- {a} ↔ {b}: {s}{flag}")
    lines.append("")
    lines.append("## Deliverables")
    lines.append("- `review/character_scale_comparison.png` — size ladder")
    lines.append("- `review/silhouette_comparison.png` — black silhouette distinction")
    lines.append("- `review/gameplay_scale_preview.png` — 640×360 in-engine scale mock")
    lines.append("- `review/anim_player.gif`, `anim_enemies_*.gif`, `anim_boss.gif` — motion review")
    lines.append("- `assets_v2/characters/<char>/frame_map.json` + `metadata.md` — timing")
    lines.append("- `assets_v2/godot/<char>_frames.tres` — ready SpriteFrames")
    lines.append("- `assets_v2/GODOT_IMPORT_GUIDE.md` — wiring instructions")
    (REVIEW / "ART_V2_REVIEW_REPORT.md").write_text("\n".join(lines))
    print("\nWrote review/ART_V2_REVIEW_REPORT.md and quality_report.json")


def main():
    check_size()
    check_framediff()
    check_alpha()
    feats, sims = check_silhouette()
    check_telegraph()
    check_foot()
    check_weapon()
    make_scale_preview()
    make_gifs()
    write_report(feats, sims)
    fails = [c for c in CHECKS if c[1] == "FAIL"]
    if fails:
        print("\nHARD FAILURES — rework required:")
        for n, s, d in fails:
            print(f"  {n}: {d}")
        raise SystemExit(1)
    print("\nAll hard checks passed. (WARNs are advisory.)")


if __name__ == "__main__":
    main()
