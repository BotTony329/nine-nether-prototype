# ART V2 — Review Report

**Result:** WARNING

## Automated checks
- **[PASS]** 1.size — all 37 sheets match frames*fw x fh
- **[WARN]** 2.frame-diff — low-motion pairs: player_run f3->f4 (114/9216 ~1.2%); melee_ghost_attack f0->f1 (109/9216 ~1.2%); corpse_beast_charge_windup f0->f1 (129/12288 ~1.0%); corpse_beast_charge_windup f1->f2 (170/12288 ~1.4%); corpse_beast_charge_windup f3->f4 (147/12288 ~1.2%); corpse_beast_charge_windup f4->f5 (168/12288 ~1.4%); corpse_beast_wall_impact f2->f3 (163/12288 ~1.3%); corpse_beast_hurt f2->f3 (167/12288 ~1.4%)
- **[PASS]** 3.alpha — transparent background on all sheets
- **[WARN]** 4.silhouette — similar shape pair(s): player~melee_ghost=0.967; player~gate_warden=0.934; melee_ghost~gate_warden=0.921 (humanoids share a body plan; distinguished in-game by colour/weapon/lean)
- **[PASS]** 5.telegraph — all strikes have non-empty active window
- **[PASS]** 6.foot — foot baseline stable on idle/walk/run (<8% frame height)
- **[WARN]** 7.weapon — gate_warden_attack_2 motion range only 9%
- **[PASS]** 8.scale-preview — review/gameplay_scale_preview.png (640x360)
- **[PASS]** 9.gif — anim_player.gif (38 frames)
- **[PASS]** 9.gif — anim_enemies_melee.gif (22 frames)
- **[PASS]** 9.gif — anim_enemies_archer.gif (16 frames)
- **[PASS]** 9.gif — anim_enemies_beast.gif (18 frames)
- **[PASS]** 9.gif — anim_boss.gif (38 frames)

## Silhouette similarity matrix (lower = more distinct)
- player ↔ melee_ghost: 0.967  ⚠ similar
- player ↔ gate_warden: 0.934  ⚠ similar
- melee_ghost ↔ gate_warden: 0.921  ⚠ similar
- player ↔ ghost_archer: 0.841  ⚠ similar
- melee_ghost ↔ ghost_archer: 0.826  ⚠ similar
- ghost_archer ↔ gate_warden: 0.795
- corpse_beast ↔ gate_warden: -0.226
- player ↔ corpse_beast: -0.269
- melee_ghost ↔ corpse_beast: -0.277
- ghost_archer ↔ corpse_beast: -0.399

## Deliverables
- `review/character_scale_comparison.png` — size ladder
- `review/silhouette_comparison.png` — black silhouette distinction
- `review/gameplay_scale_preview.png` — 640×360 in-engine scale mock
- `review/anim_player.gif`, `anim_enemies_*.gif`, `anim_boss.gif` — motion review
- `assets_v2/characters/<char>/frame_map.json` + `metadata.md` — timing
- `assets_v2/godot/<char>_frames.tres` — ready SpriteFrames
- `assets_v2/GODOT_IMPORT_GUIDE.md` — wiring instructions