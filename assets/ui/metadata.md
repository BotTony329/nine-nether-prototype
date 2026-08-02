# assets/ui/ — Metadata

## UI Element Specifications

### ui_health_bar.png
- Size: 96 × 16 px
- Type: UI bar (frame + fill)
- Layout: 1px frame border, 14px interior
- Colors: Frame `#2A2520`, fill `#5A1818` (dark red), highlight `#8A2828`
- Purpose: Player health bar — fill scales with HP percentage
- Engine: Use as TextureProgressBar or split frame/fill textures

### ui_stamina_bar.png
- Size: 96 × 16 px
- Type: UI bar (frame + fill)
- Layout: 1px frame border, 14px interior
- Colors: Frame `#2A2520`, fill `#1A4A2A` (dark green), highlight `#2A8A4A`
- Purpose: Player stamina bar — fill scales with stamina percentage
- Engine: Use as TextureProgressBar or split frame/fill textures

### ui_frame.png
- Size: 32 × 32 px
- Type: 9-slice frame
- Layout: 3px ornate border, 26px transparent interior
- Colors: Frame `#2A2520`, highlight `#4A4035`, corners `#5A4A3A`
- Purpose: Generic UI panel frame — inventory slots, dialogue boxes, menus
- Engine: Import as 9-slice texture, set margins to 3px

### ui_minimap_frame.png
- Size: 64 × 64 px
- Type: 9-slice frame
- Layout: 4px border, 56px interior
- Colors: Frame `#2A2520`, highlight `#4A4035`, corner spikes `#5A4A3A`
- Purpose: Minimap display frame — minimap renders inside transparent interior
- Engine: Static sprite, minimap renders as child node inside frame

## Godot Import Settings
- Filter: Off (Nearest)
- Mipmaps: Off
- Compression: Lossless
- Format: RGBA
