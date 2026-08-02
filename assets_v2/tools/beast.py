#!/usr/bin/env python3
"""Nine Nether V2 — Corpse Beast (冲锋尸兽) renderer.

Low, wide, quadrupedal (or near-quadrupedal) charge enemy. Distinct from all
humanoid characters: horizontal silhouette, four limbs, arched back, head
thrust forward. Glowing red eyes/chest during charge wind-up.
"""

from __future__ import annotations
import math
from pixel_engine import capsule, fill_circle, fill_poly, _r


def beast_config(**over):
    cfg = {
        "fw": 128, "fh": 96,
        "cx": 64,
        "body_y": 58,
        "body_len": 58,
        "body_h": 18,
        "back_arch": 8,
        "head_x": 34, "head_y": 38,
        "head_len": 22, "head_h": 12,
        "leg_f_len": 20, "leg_b_len": 18,
        "leg_w": 5,
        "palette": {},
    }
    cfg.update(over)
    return cfg


def _seg(joint, length, angle_deg):
    a = math.radians(angle_deg)
    return (joint[0] + length * math.sin(a), joint[1] + length * math.cos(a))


def render_beast(draw, cfg, pose, fw, fh):
    pal = cfg["palette"]
    out = pal["outline"]
    body_y = cfg["body_y"] + pose.get("bob", 0)
    arch = cfg["back_arch"] + pose.get("arch", 0)
    body_len = cfg["body_len"] + pose.get("stretch", 0)
    cx = cfg["cx"] + pose.get("dx", 0)
    # body as arched spine: back -> mid -> shoulder
    back = (cx - body_len * 0.45, body_y - arch * 0.6)
    mid = (cx, body_y - arch)
    shoulder = (cx + body_len * 0.4, body_y - arch * 0.4)
    hip = (cx - body_len * 0.45, body_y)
    # body fill (tapered polygon)
    bh = cfg["body_h"]
    fill_poly(draw, [
        (back[0], back[1] - bh * 0.2),
        (mid[0], mid[1] - bh),
        (shoulder[0], shoulder[1] - bh * 0.3),
        (shoulder[0], shoulder[1] + bh * 0.6),
        (mid[0], mid[1] + bh * 0.4),
        (back[0], back[1] + bh * 0.7),
    ], pal["body"])
    # spine highlight
    draw.line([_r(back), _r(mid), _r(shoulder)], fill=pal["body_lt"], width=2)
    # outline
    pts = [(back[0], back[1] - bh * 0.2), (mid[0], mid[1] - bh), (shoulder[0], shoulder[1] - bh * 0.3),
           (shoulder[0], shoulder[1] + bh * 0.6), (mid[0], mid[1] + bh * 0.4), (back[0], back[1] + bh * 0.7)]
    draw.line([_r(p) for p in pts] + [_r(pts[0])], fill=out, width=1)

    # leg attachment points
    fl_hip = (shoulder[0] - 2, shoulder[1] + bh * 0.3)
    fr_hip = (shoulder[0] + 2, shoulder[1] + bh * 0.3)
    bl_hip = (back[0] + 4, back[1] + bh * 0.3)
    br_hip = (back[0] - 2, back[1] + bh * 0.3)

    def draw_leg(hip_pt, knee_a, ankle_a, side):
        w = cfg["leg_w"] * (0.85 if side == "far" else 1.0)
        knee = _seg(hip_pt, cfg["leg_f_len"] * 0.55, knee_a)
        foot = _seg(knee, cfg["leg_f_len"] * 0.55, ankle_a)
        base = pal["leg_dk"] if side == "far" else pal["leg"]
        capsule(draw, hip_pt, knee, w, base, outline=out, light=pal["leg_lt"])
        capsule(draw, knee, foot, max(2, w - 1), base, outline=out, light=pal["leg_lt"])
        # claw
        claw = (foot[0] + 4, foot[1] + 2)
        fill_poly(draw, [foot, claw, (foot[0] + 1, foot[1] - 2)], pal["claw"])
        return foot

    # back far leg
    draw_leg(br_hip, pose.get("leg_br_knee", 95), pose.get("leg_br_ankle", 80), "far")
    # front far leg
    draw_leg(fr_hip, pose.get("leg_fr_knee", 85), pose.get("leg_fr_ankle", 100), "far")

    # body again for overlap? no, keep simple

    # head / neck
    neck = (shoulder[0] + 8, shoulder[1] - 6)
    head_c = (neck[0] + cfg["head_x"] * 0.5, neck[1] - 6 + pose.get("head_y", 0))
    # neck
    capsule(draw, shoulder, neck, 5, pal["body_dk"], outline=out, light=pal["body_lt"])
    # head (elongated)
    fill_poly(draw, [
        (head_c[0] - cfg["head_len"] * 0.5, head_c[1] - cfg["head_h"]),
        (head_c[0] + cfg["head_len"] * 0.5, head_c[1] - cfg["head_h"] * 0.6),
        (head_c[0] + cfg["head_len"] * 0.5, head_c[1] + cfg["head_h"] * 0.5),
        (head_c[0] - cfg["head_len"] * 0.3, head_c[1] + cfg["head_h"]),
    ], pal["body"])
    draw.line([
        _r((head_c[0] - cfg["head_len"] * 0.5, head_c[1] - cfg["head_h"])),
        _r((head_c[0] + cfg["head_len"] * 0.5, head_c[1] - cfg["head_h"] * 0.6)),
        _r((head_c[0] + cfg["head_len"] * 0.5, head_c[1] + cfg["head_h"] * 0.5)),
        _r((head_c[0] - cfg["head_len"] * 0.3, head_c[1] + cfg["head_h"])),
        _r((head_c[0] - cfg["head_len"] * 0.5, head_c[1] - cfg["head_h"])),
    ], fill=out, width=1)
    # eye(s)
    glow = pose.get("charge_glow", 0)
    eye_c = (head_c[0] + cfg["head_len"] * 0.25, head_c[1] - 2)
    fill_circle(draw, eye_c, 3 + glow * 2, (140, 20, 20))
    fill_circle(draw, eye_c, 2 + glow, (220, 60, 40))
    # chest glow when charging
    if glow > 0.3:
        fill_circle(draw, (shoulder[0], shoulder[1] - 2), 4 + glow * 3, (140, 20, 20))
        fill_circle(draw, (shoulder[0], shoulder[1] - 2), 2 + glow, (220, 60, 40))

    # front near leg
    draw_leg(fl_hip, pose.get("leg_fl_knee", 85), pose.get("leg_fl_ankle", 100), "near")
    # back near leg
    draw_leg(bl_hip, pose.get("leg_bl_knee", 95), pose.get("leg_bl_ankle", 80), "near")

    # tail
    tail_base = (back[0] - 6, back[1])
    tail_tip = (back[0] - 22, back[1] - 4 + pose.get("tail", 0))
    capsule(draw, tail_base, tail_tip, 3, pal["body_dk"], outline=out)
