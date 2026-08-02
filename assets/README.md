# assets/ — Art Resource Directory

This directory contains all visual art assets for the 九幽 (Nine Nether) prototype.

## Structure

| Directory | Contents | Count |
|-----------|----------|-------|
| `player/` | Player character sprite sheets | 6 sheets |
| `enemy/` | Enemy sprite sheets (3 enemy types) | 15 sheets |
| `boss/` | Boss sprite sheets | 5 sheets |
| `icons/weapons/` | 32×32 weapon icons | 6 icons |
| `icons/ui/` | 32×32 UI stat icons | 11 icons |
| `tiles/` | 32×32 tilemap tiles | 7 tiles |
| `effects/` | 48×48 VFX sprites | 4 effects |
| `background/` | Parallax background elements | 4 elements |
| `ui/` | UI elements (bars, frames) | 4 elements |

## Key Documents
- **Master spec:** `docs/ART_SPEC.md`
- **Concept docs:** `docs/art/CONCEPT_*.md`
- **Import guide:** `docs/art/GODOT_IMPORT_GUIDE.md`
- **Naming rules:** `docs/art/NAMING_CONVENTION.md`

## Placeholder Status
All PNGs are currently **placeholders** (marked with magenta border). Replace each with final pixel art using the same filename and dimensions. See `docs/ART_SPEC.md` Section 5 for replacement workflow.

## Regenerating Placeholders
```bash
python3 tools/generate_placeholders.py
```
