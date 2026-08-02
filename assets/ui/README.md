# assets/ui/ — UI Elements

## Files
| File | Name | Size | Purpose |
|------|------|------|---------|
| ui_health_bar.png | 生命条 | 96×16 | Player HP bar (frame + red fill) |
| ui_stamina_bar.png | 体力条 | 96×16 | Player stamina bar (frame + green fill) |
| ui_frame.png | 通用边框 | 32×32 | 9-slice frame for panels/slots |
| ui_minimap_frame.png | 小地图边框 | 64×64 | Minimap border frame |

## Notes
- Bars: 1px frame border, 14px interior fill area
- `ui_frame.png` is a 9-slice sprite — corners stay fixed, edges stretch
- `ui_minimap_frame.png` has 4px border, 56px interior for minimap rendering

## Concept Reference
See `docs/art/CONCEPT_UI.md` for full design descriptions.
