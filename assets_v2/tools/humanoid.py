#!/usr/bin/env python3
"""Nine Nether V2 — Humanoid character renderer (enhanced).

Shared skeletal renderer for upright humanoid characters (player, melee ghost,
ghost archer). Produces pixel-art sprites with:

  * stable foot baseline
  * constant weapon geometry
  * distinct silhouettes per config
  * top-left light shading
  * armor/cloth/weapon detail layers
"""

from __future__ import annotations
import math
from pixel_engine import capsule, fill_circle, fill_poly, ghost_fire, ghost_fire_eye, _r


def humanoid_config(**over):
    cfg = {
        "fw": 96, "fh": 96,
        "cx": 48,
        "hip_y": 66,
        "scale": 1.0,
        "torso_len": 26, "neck_len": 5, "head_r": 9,
        "upper_arm": 16, "lower_arm": 15, "arm_w": 4,
        "thigh": 17, "shin": 16, "leg_w": 5,
        "lean": 0, "stance": 4,
        "style": "player",
        "palette": {},
        "ghost_fire": False,
        "pauldrons": True,
        "torso_hw": 9,
        "torso_hw_hip": 7,
        "weapon_len": 44,
    }
    cfg.update(over)
    s = cfg["scale"]
    for k in ["torso_len", "neck_len", "head_r", "upper_arm", "lower_arm", "arm_w",
              "thigh", "shin", "leg_w", "stance", "torso_hw", "torso_hw_hip", "weapon_len"]:
        cfg[k] = cfg[k] * s
    return cfg


def _seg(joint, length, angle_deg):
    a = math.radians(angle_deg)
    return (joint[0] + length * math.sin(a), joint[1] + length * math.cos(a))


def _perp(v):
    L = math.hypot(v[0], v[1])
    return (-v[1] / L, v[0] / L)


def solve_joints(cfg, pose):
    bob = pose.get("bob", 0)
    lean = cfg["lean"] + pose.get("lean", 0)
    hip = (cfg["cx"], cfg["hip_y"] + bob)
    torso_angle = 180 - lean
    shoulder = _seg(hip, cfg["torso_len"], torso_angle)
    neck = _seg(shoulder, cfg["neck_len"], torso_angle)
    head_c = _seg(neck, cfg["head_r"] + 2, torso_angle)

    sh_b = (shoulder[0] - cfg["arm_w"] * 0.6, shoulder[1])
    sh_f = (shoulder[0] + cfg["arm_w"] * 0.6, shoulder[1])
    hip_b = (hip[0] - cfg["stance"], hip[1])
    hip_f = (hip[0] + cfg["stance"], hip[1])

    def arm(sh, p):
        ea = _seg(sh, cfg["upper_arm"], p[0])
        ha = _seg(ea, cfg["lower_arm"], p[1])
        return sh, ea, ha
    def leg(hp, p):
        kn = _seg(hp, cfg["thigh"], p[0])
        ft = _seg(kn, cfg["shin"], p[1])
        return hp, kn, ft

    return {
        "hip": hip, "shoulder": shoulder, "neck": neck, "head_c": head_c,
        "arms": {"back": arm(sh_b, pose.get("arm_back", (95, 100))),
                 "front": arm(sh_f, pose.get("arm_front", (85, 95)))},
        "legs": {"back": leg(hip_b, pose.get("leg_back", (88, 92))),
                 "front": leg(hip_f, pose.get("leg_front", (92, 88)))},
        "lean": lean, "bob": bob, "torso_angle": torso_angle,
    }


def _draw_arm(draw, cfg, pal, p_arm, p_elbow, p_hand, side):
    base, lt, out = pal["skin"], pal["skin_lt"], pal["outline"]
    if side == "back":
        base, lt = pal["skin_sh"], pal["skin_sh"]
    aw = cfg["arm_w"]
    capsule(draw, p_arm, p_elbow, aw, base, outline=out, light=lt)
    capsule(draw, p_elbow, p_hand, max(2, aw - 1), base, outline=out, light=lt)
    fill_circle(draw, p_hand, aw - 1, base)
    draw.ellipse((_r(p_hand)[0] - aw, _r(p_hand)[1] - aw,
                  _r(p_hand)[0] + aw + 1, _r(p_hand)[1] + aw + 1), outline=out)


def _draw_leg(draw, cfg, pal, p_hip, p_knee, p_foot, side):
    base, lt, out = pal["armor"], pal["armor_lt"], pal["outline"]
    if side == "back":
        base = pal["armor_dk"]
    w = cfg["leg_w"]
    capsule(draw, p_hip, p_knee, w, base, outline=out, light=lt)
    capsule(draw, p_knee, p_foot, max(2, w - 1), base, outline=out, light=lt)
    # knee pad
    fill_circle(draw, p_knee, int(w * 0.9) + 1, pal["armor_dk"])
    fill_circle(draw, p_knee, int(w * 0.6), pal["armor_lt"])
    # boot
    fd = (p_foot[0] - p_knee[0], p_foot[1] - p_knee[1])
    fl = math.hypot(*fd) or 1
    fx, fy = fd[0] / fl, fd[1] / fl
    nx, ny = -fy, fx
    boot_pts = [
        (p_foot[0] - nx * (w - 1), p_foot[1] - ny * (w - 1)),
        (p_foot[0] + nx * (w - 1), p_foot[1] + ny * (w - 1)),
        (p_foot[0] + nx * (w - 1) + fx * 7, p_foot[1] + ny * (w - 1) + fy * 7),
        (p_foot[0] - nx * (w - 1) + fx * 7, p_foot[1] - ny * (w - 1) + fy * 7),
    ]
    fill_poly(draw, boot_pts, pal.get("boot", base))
    draw.line(boot_pts + [boot_pts[0]], fill=out, width=1)


def _draw_torso(draw, j, cfg, pal):
    hip, sh, neck = j["hip"], j["shoulder"], j["neck"]
    ta = j["torso_angle"]
    hw = cfg["torso_hw"]
    hw_h = cfg["torso_hw_hip"]
    perp = (math.sin(math.radians(ta + 90)), math.cos(math.radians(ta + 90)))
    top_l = (sh[0] + perp[0] * hw, sh[1] + perp[1] * hw)
    top_r = (sh[0] - perp[0] * hw, sh[1] - perp[1] * hw)
    bot_l = (hip[0] + perp[0] * hw_h, hip[1] + perp[1] * hw_h)
    bot_r = (hip[0] - perp[0] * hw_h, hip[1] - perp[1] * hw_h)
    fill_poly(draw, [top_l, top_r, bot_r, bot_l], pal["armor_dk"])
    fill_poly(draw, [top_l, top_r, (sh[0], sh[1]), (hip[0], hip[1]), bot_l], pal["armor"])
    # chest plate (central lighter panel)
    ct = (sh[0] + perp[0] * (hw * 0.35), sh[1] + perp[1] * (hw * 0.35))
    cb = (hip[0] + perp[0] * (hw_h * 0.35), hip[1] + perp[1] * (hw_h * 0.35))
    fill_poly(draw, [ct, (sh[0] - perp[0] * (hw * 0.25), sh[1] - perp[1] * (hw * 0.25)),
                     (hip[0] - perp[0] * (hw_h * 0.25), hip[1] - perp[1] * (hw_h * 0.25)), cb], pal["armor_lt"])
    # outline
    for a, b in [(top_l, top_r), (top_r, bot_r), (bot_r, bot_l), (bot_l, top_l)]:
        draw.line([_r(a), _r(b)], fill=pal["outline"])
    # pauldrons
    if cfg.get("pauldrons"):
        pl = (sh[0] + perp[0] * (hw + 1), sh[1] + perp[1] * (hw + 1))
        pr = (sh[0] - perp[0] * (hw + 1), sh[1] - perp[1] * (hw + 1))
        if cfg.get("asymmetric_pauldrons"):
            # left (front) massive, right damaged/small
            fill_circle(draw, pl, int(hw * 1.0), pal["armor_dk"])
            fill_circle(draw, (pl[0] - 1, pl[1] - 1), int(hw * 0.7), pal.get("gold", pal["armor_lt"]))
            fill_poly(draw, [pr, (pr[0] + 2, pr[1] - 2), (pr[0] + 3, pr[1] + 3), (pr[0] - 1, pr[1] + 2)], pal["armor_dk"])
        else:
            for p in [pl, pr]:
                fill_circle(draw, p, int(hw * 0.65), pal["armor_dk"])
                fill_circle(draw, (p[0] - 1, p[1] - 1), int(hw * 0.4), pal["armor_lt"])
    # belt / cloth
    if "cloth" in pal:
        bx = hip[0] + perp[0] * (hw_h + 1)
        by = hip[1] + perp[1] * (hw_h + 1)
        fill_circle(draw, (bx, by), 3, pal["cloth"])
        fill_circle(draw, (hip[0] - perp[0] * (hw_h + 1), hip[1] - perp[1] * (hw_h + 1)), 3, pal["cloth"])


def _draw_head(draw, j, cfg, pal, pose):
    head_c = j["head_c"]
    r = int(round(cfg["head_r"]))
    out = pal["outline"]
    if cfg["style"] == "boss":
        # empty great helm with strong ghost fire
        fill_circle(draw, head_c, r, pal["skin_sh"])
        fill_poly(draw, [
            (head_c[0] - r, head_c[1] - r),
            (head_c[0] + r, head_c[1] - r),
            (head_c[0] + r - 2, head_c[1] + r // 2),
            (head_c[0] - r + 2, head_c[1] + r // 2),
        ], pal["armor_dk"])
        # horns / crown
        fill_poly(draw, [
            (head_c[0] - r + 2, head_c[1] - r),
            (head_c[0] - r - 4, head_c[1] - r - 6),
            (head_c[0] - r + 6, head_c[1] - r + 2),
        ], pal.get("gold", pal["armor_lt"]))
        draw.ellipse((_r(head_c)[0] - r, _r(head_c)[1] - r,
                      _r(head_c)[0] + r + 1, _r(head_c)[1] + r + 1), outline=out)
        if cfg.get("ghost_fire"):
            t = pose.get("fire_t", 0)
            ghost_fire(draw, head_c[0], head_c[1], r * 0.55, t)
            ghost_fire_eye(draw, head_c[0] - r * 0.3, head_c[1] + 2, r * 0.28, (t + 0.2) % 1.0)
            ghost_fire_eye(draw, head_c[0] + r * 0.3, head_c[1] + 2, r * 0.28, (t + 0.5) % 1.0)
        return
    if cfg["style"] == "player":
        # face
        fill_circle(draw, head_c, r, pal["skin"])
        fill_circle(draw, (head_c[0] + 2, head_c[1]), r - 3, pal["skin_sh"])
        fill_circle(draw, (head_c[0] - 2, head_c[1]), r - 3, pal["skin"])
        # light helmet / hood covering top/back
        fill_poly(draw, [
            (head_c[0] - r, head_c[1] - r + 1),
            (head_c[0] + r, head_c[1] - r + 1),
            (head_c[0] + r - 1, head_c[1] - 2),
            (head_c[0] - r + 1, head_c[1] - 2),
        ], pal["armor"])
        # brim
        fill_poly(draw, [
            (head_c[0] - r - 1, head_c[1] - r + 2),
            (head_c[0] + r + 1, head_c[1] - r + 2),
            (head_c[0] + r - 1, head_c[1] - r + 5),
            (head_c[0] - r + 1, head_c[1] - r + 5),
        ], pal["armor_dk"])
        draw.ellipse((_r(head_c)[0] - r, _r(head_c)[1] - r,
                      _r(head_c)[0] + r + 1, _r(head_c)[1] + r + 1), outline=out)
        # eye
        fill_circle(draw, (head_c[0] - 1, head_c[1] - 1), 1, (20, 20, 25))
        # red identification cloth on helmet
        fill_poly(draw, [
            (head_c[0] + r - 2, head_c[1] - r + 4),
            (head_c[0] + r + 5, head_c[1] - r + 2),
            (head_c[0] + r + 5, head_c[1] - r + 6),
            (head_c[0] + r - 1, head_c[1] - r + 8),
        ], pal["cloth"])
    else:
        fill_circle(draw, head_c, r, pal["skin_sh"])
        fill_poly(draw, [
            (head_c[0] - r, head_c[1] - r),
            (head_c[0] + r, head_c[1] - r),
            (head_c[0] + r - 1, head_c[1] + 2),
            (head_c[0] - r + 1, head_c[1] + 2),
        ], pal["armor_dk"])
        draw.ellipse((_r(head_c)[0] - r, _r(head_c)[1] - r,
                      _r(head_c)[0] + r + 1, _r(head_c)[1] + r + 1), outline=out)
        if cfg.get("ghost_fire"):
            t = pose.get("fire_t", 0)
            ghost_fire_eye(draw, head_c[0] - r * 0.35, head_c[1], r * 0.22, t)
            ghost_fire_eye(draw, head_c[0] + r * 0.35, head_c[1], r * 0.22, (t + 0.3) % 1.0)


def draw_sabre(draw, hand, angle_deg, length, pal, curve=0.12):
    out = pal["outline"]
    a = math.radians(angle_deg)
    dx, dy = math.sin(a), math.cos(a)
    hilt_end = (hand[0] - dx * 8, hand[1] - dy * 8)
    capsule(draw, hand, hilt_end, 2, pal.get("grip", (60, 45, 35)), outline=out)
    fill_circle(draw, hand, 3, pal.get("guard", (120, 95, 70)))
    bl = length - 8
    left, right = [], []
    steps = 7
    for i in range(steps + 1):
        f = i / steps
        bx = hand[0] + dx * bl * f
        by = hand[1] + dy * bl * f
        px, py = -dy, dx
        bend = curve * f * f * bl
        bx += px * bend
        by += py * bend
        w = (3.6 if f < 0.6 else (2.0 if f < 0.9 else 0.8))
        left.append((bx + px * w, by + py * w))
        right.append((bx - px * w, by - py * w))
    fill_poly(draw, left + right[::-1], pal["blade"])
    # fuller (blood groove) line
    mid = [( (left[i][0] + right[i][0]) / 2, (left[i][1] + right[i][1]) / 2) for i in range(len(left))]
    for i in range(len(mid) - 1):
        draw.line([_r(mid[i]), _r(mid[i + 1])], fill=pal["blade_dk"], width=1)
    # edge highlight (top-left/back side)
    hl = [(left[i][0] - 1, left[i][1] - 1) for i in range(len(left))]
    draw.line([_r(p) for p in hl], fill=pal["blade_lt"], width=1)
    # outlines
    draw.line([_r(left[0]), _r(left[-1])], fill=out)
    draw.line([_r(right[0]), _r(right[-1])], fill=out)
    return left[-1]


def draw_great_blade(draw, hand, angle_deg, length, pal):
    """Massive ghost-head great blade (斩马刀 / 鬼头大刀) for the Gate Warden."""
    out = pal["outline"]
    a = math.radians(angle_deg)
    dx, dy = math.sin(a), math.cos(a)
    # long hilt + crossguard
    hilt_end = (hand[0] - dx * 14, hand[1] - dy * 14)
    capsule(draw, hand, hilt_end, 4, pal.get("grip", (50, 40, 35)), outline=out)
    fill_circle(draw, hand, 6, pal.get("guard", (110, 90, 60)))
    # blade
    bl = length - 14
    left, right = [], []
    steps = 10
    for i in range(steps + 1):
        f = i / steps
        bx = hand[0] + dx * bl * f
        by = hand[1] + dy * bl * f
        px, py = -dy, dx
        bend = 0.10 * f * f * bl
        bx += px * bend
        by += py * bend
        w = (8.0 if f < 0.5 else (5.0 if f < 0.85 else 1.5))
        left.append((bx + px * w, by + py * w))
        right.append((bx - px * w, by - py * w))
    fill_poly(draw, left + right[::-1], pal["blade"])
    # fuller + ghost-fire runes
    mid = [((left[i][0] + right[i][0]) / 2, (left[i][1] + right[i][1]) / 2) for i in range(len(left))]
    for i in range(len(mid) - 1):
        draw.line([_r(mid[i]), _r(mid[i + 1])], fill=pal["blade_dk"], width=1)
    for i in [2, 4, 6]:
        if i < len(mid):
            ghost_fire(draw, mid[i][0], mid[i][1], 1.5, (i * 0.1) % 1.0)
    # edge highlight
    hl = [(left[i][0] - 1, left[i][1] - 1) for i in range(len(left))]
    draw.line([_r(p) for p in hl], fill=pal["blade_lt"], width=1)
    draw.line([_r(left[0]), _r(left[-1])], fill=out)
    draw.line([_r(right[0]), _r(right[-1])], fill=out)
    return left[-1]


def draw_bow(draw, grip, aim, pal, bow_len=34, facing=1):
    out = pal["outline"]
    top = (grip[0] - facing * 4, grip[1] - bow_len)
    bot = (grip[0] - facing * 4, grip[1] + bow_len)
    mid = (grip[0] - facing * (bow_len * 0.7 + 8), grip[1])
    pts = []
    N = 8
    for i in range(N + 1):
        t = i / N
        x = (1 - t) ** 2 * top[0] + 2 * (1 - t) * t * mid[0] + t ** 2 * bot[0]
        y = (1 - t) ** 2 * top[1] + 2 * (1 - t) * t * mid[1] + t ** 2 * bot[1]
        pts.append((x, y))
    for i in range(N):
        capsule(draw, pts[i], pts[i + 1], 2, pal["wood"], outline=out, light=pal.get("wood_lt"))
    draw_arm_x = grip[0] + facing * (6 + aim * 10)
    draw.line([_r(top), _r((draw_arm_x, grip[1]))], fill=(180, 200, 190), width=1)
    draw.line([_r(bot), _r((draw_arm_x, grip[1]))], fill=(180, 200, 190), width=1)
    if aim > 0.05:
        arrow_tip = (grip[0] + facing * (bow_len * 0.9), grip[1])
        capsule(draw, (draw_arm_x, grip[1]), arrow_tip, 1, (90, 80, 70), outline=out)
        ghost_fire(draw, arrow_tip[0], arrow_tip[1], 3, pal.get("fire_t", 0))
    return (draw_arm_x, grip[1])


def render_humanoid(draw, cfg, pose, fw, fh):
    j = solve_joints(cfg, pose)
    pal = cfg["palette"]
    out = pal["outline"]

    _draw_leg(draw, cfg, pal, *j["legs"]["back"], "back")
    sh, el, ha = j["arms"]["back"]
    _draw_arm(draw, cfg, pal, sh, el, ha, "back")
    _draw_torso(draw, j, cfg, pal)
    _draw_head(draw, j, cfg, pal, pose)

    if cfg.get("ghost_fire"):
        ghost_fire(draw, j["shoulder"][0] - 3, j["shoulder"][1] + 4, 3, pose.get("fire_t", 0))

    _draw_leg(draw, cfg, pal, *j["legs"]["front"], "front")
    sh, el, ha = j["arms"]["front"]
    _draw_arm(draw, cfg, pal, sh, el, ha, "front")

    if cfg["style"] == "player":
        draw_sabre(draw, ha, pose.get("weapon", 70), cfg["weapon_len"], pal)
    elif cfg["style"] == "melee_ghost":
        draw_sabre(draw, ha, pose.get("weapon", 110), cfg["weapon_len"], pal, curve=0.05)
    elif cfg["style"] == "ghost_archer":
        draw_bow(draw, ha, pose.get("aim", 0), pal, bow_len=cfg.get("bow_len", 34))
    elif cfg["style"] == "boss":
        draw_great_blade(draw, ha, pose.get("weapon", 80), cfg["weapon_len"], pal)

    # cloth strips / sashes swaying
    if "cloth" in pal:
        sway = pose.get("cloth_sway", 0)
        count = 4 if cfg["style"] == "boss" else 3
        for k in range(count):
            sy = j["hip"][1] - 4 + k * 3
            sx = j["hip"][0] + (3 if cfg["style"] == "ghost_archer" else -4)
            if cfg["style"] == "boss":
                sx = j["hip"][0] + (5 if k % 2 == 0 else -5)
            fill_poly(draw, [
                (sx, sy),
                (sx - 8 - sway, sy + 10 + k * 2),
                (sx - 7 - sway, sy + 13 + k * 2),
                (sx + 1, sy + 2),
            ], pal["cloth"])
