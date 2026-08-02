# Art V3 Production Source Boards

These transparent RGBA boards are the retained inputs for
`assets_v3/tools/build_production_assets.py`. They were generated with the
built-in image-generation workflow using only
`assets_v3/review/character_lineup.png` as the visual reference, then processed
from a flat `#FF00FF` chroma field to alpha.

Prompt set:

- Player: approved lineup identity; idle 4, walk 6, attack 4, hurt 2, death 6.
- Ghost Melee: approved lineup identity; idle, walk, attack, hurt, death only.
- Ghost Archer: approved lineup identity; idle, walk, bow attack, hurt, death only.
- Gate Warden: approved mounted identity; idle, walk, attack, hurt, death only.
- Environment: stone floor, fortress wall, fortress gate only.
- Effects: slash, hit, blood, ghost fire, death dissolve only.
- Icons: HP seal, Gate Warden Boss mark, sacrifice talisman only.

All prompts required production sprite isolation, consistent approved palette
and upper-left lighting, crisp pixel edges, wide gutters, no labels, no new
armour or character reinterpretation, and no unapproved animations.

Do not use the master-board crop bounds directly in Godot. The normalized
strips under the sibling production directories are the runtime deliverables.
