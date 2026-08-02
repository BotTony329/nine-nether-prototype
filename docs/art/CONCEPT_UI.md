# Concept: UI Elements — 界面元素

> **Type:** UI Sprites
> **Sizes:** Varies (see each)
> **Style:** Dark, ornate, Chinese underworld aesthetic

---

## Design Philosophy
- UI elements should feel like they belong in the underworld — dark, rusted, bone-like
- Bars use a frame + fill pattern (frame is static, fill scales with value)
- All UI elements share a base palette (dark steel + accent colors)
- Pixel-perfect edges — no anti-aliasing on UI borders

---

## UI Element Designs (4 total)

### 1. ui_health_bar.png — 生命条 (Health Bar)
- **Size:** 96 × 16 px
- **Description:** Player health bar — dark frame with red fill
- **Colors:** Frame `#2A2520`, frame highlight `#4A4035`, fill `#5A1818`, fill highlight `#8A2828`
- **Layout:** 1px frame border, 14px interior fill area
- **Notes:** The fill represents 100% HP. In-engine, the fill width is scaled by HP percentage. The frame stays static.
- **Engine usage:** 
  - Frame: drawn as 9-slice or static sprite
  - Fill: separate sprite scaled horizontally by `current_hp / max_hp`
- **Alternative:** Use as a single sprite and let engine handle fill via shader/modulate

### 2. ui_stamina_bar.png — 体力条 (Stamina Bar)
- **Size:** 96 × 16 px
- **Description:** Player stamina bar — dark frame with green fill
- **Colors:** Frame `#2A2520`, frame highlight `#4A4035`, fill `#1A4A2A`, fill highlight `#2A8A4A`
- **Layout:** Same as health bar
- **Notes:** Placed below or beside the health bar. Green distinguishes it from red HP.
- **Engine usage:** Same as health bar — frame static, fill scales with stamina value.

### 3. ui_frame.png — 通用边框 (Generic Frame)
- **Size:** 32 × 32 px
- **Description:** Decorative border frame for UI panels, icon backgrounds, tooltips
- **Colors:** Frame `#2A2520`, inner border `#4A4035`, corner accents `#5A4A3A`
- **Layout:** 3px ornate border, 26px transparent interior
- **Notes:** Designed as a 9-slice sprite — corners stay fixed, edges stretch. Used for inventory slots, dialogue boxes, menu panels.
- **Engine usage:** Import as 9-slice texture in Godot. Set margins to 3px on all sides.

### 4. ui_minimap_frame.png — 小地图边框 (Minimap Frame)
- **Size:** 64 × 64 px
- **Description:** Square frame for minimap display
- **Colors:** Frame `#2A2520`, inner border `#4A4035`, corner spikes `#5A4A3A`
- **Layout:** 4px border, 56px interior (for minimap rendering)
- **Notes:** Larger version of ui_frame with corner decorative spikes. Underworld aesthetic — bone/iron corners.
- **Engine usage:** Static sprite. Minimap renders inside the transparent interior area.

---

## UI Layout Reference (for Claude/Codex)
```
┌──────────────────────────────────────────┐
│ [HP████████░░░░]  [icon_hp]              │  ← Top-left: Health bar + icon
│ [STA██████████]  [icon_stamina]          │  ← Below HP: Stamina bar + icon
│                                          │
│                                          │
│           [ GAMEPLAY AREA ]              │
│                                          │
│                                          │
│                    [icon_ghostfire] ×3   │  ← Bottom-right: Resources
│                    [icon_coin] 999       │  ← Below: Currency
│                              [minimap]   │  ← Bottom-right: Minimap
└──────────────────────────────────────────┘
```

---

## Future UI Elements (Not Required for Prototype)
| Element | Description |
|---------|-------------|
| ui_boss_bar.png | Boss health bar (wider, more ornate) |
| ui_sacrifice_panel.png | Sacrifice selection panel background |
| ui_inventory_slot.png | Individual inventory slot (32×32) |
| ui_cursor.png | Custom mouse/cursor sprite |
| ui_dialogue_box.png | NPC dialogue text box background |
| ui_death_screen.png | Death overlay texture |
| ui_pause_menu.png | Pause menu background |

---

## Design Notes for AI Art Generation
1. **Bars are 96×16** — wide enough to read, thin enough to not block gameplay
2. **Frames use 9-slice** — corners must be identical, edges must tile seamlessly
3. **Colors must match the stat they represent** — HP=red, Stamina=green, Ghost Fire=blue-green
4. **No text in UI sprites** — all text is rendered by Godot's Label/Font system
5. **UI elements should feel "underworld"** — rusted iron, bone, dark metal, not clean modern UI
