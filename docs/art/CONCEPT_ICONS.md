# Concept: Icons — Weapons & UI Stats

> **Type:** Icon Assets
> **Size:** 32 × 32 px (all unified)
> **Style:** Pixel art, dark fantasy, limited palette

---

## Design Philosophy
- Icons should be **instantly recognizable** at 32×32
- Use 3-4 colors max per icon (silhouette + 1-2 highlights + outline)
- All icons share a unified palette (see ART_SPEC.md)
- Background: transparent
- No text/numbers in icons — those are rendered by UI code

---

## Weapon Icons (6 total)

### 1. weapon_songdao.png — 宋刀 (Song Sword)
- **Description:** Straight-backed single-edged dao, blade pointing up-right
- **Colors:** Dark iron blade `#4A4035`, steel edge `#6A5A4A`, dark handle `#2A2018`
- **Notes:** Blade takes up ~70% of icon. Handle wraps at bottom-left. Small tassel (red) optional.

### 2. weapon_spear.png — 长枪 (Spear)
- **Description:** Long spear diagonal bottom-left to top-right
- **Colors:** Wood shaft `#5A4025`, iron tip `#4A4035`, red tassel below tip `#5A1818`
- **Notes:** Tassel is the Song dynasty military identifier. Shaft is thin (2px wide).

### 3. weapon_ghostfire.png — 鬼火 (Ghost Fire)
- **Description:** Floating orb of blue-green flame with wisps
- **Colors:** Core `#4AE68A`, outer `#1EB464`, wisp `#0A8040`
- **Notes:** Not a weapon per se — represents the ghost fire power/element. Used in skill icons.

### 4. weapon_talisman.png — 护符 (Talisman)
- **Description:** Rectangular paper talisman with seal script, hanging string
- **Colors:** Paper `#8A7A5A`, seal ink `#5A1818`, string `#3A3028`
- **Notes:** Vertical orientation. Red seal mark in center. Torn bottom edge.

### 5. weapon_gourd.png — 酒葫芦 (Wine Gourd)
- **Description:** Traditional gourd shape with stopper
- **Colors:** Gourd body `#6A5028`, highlight `#8A6838`, stopper `#3A2818`
- **Notes:** Healing/consumable item icon. Two-bulb gourd shape.

### 6. weapon_flag.png — 残破军旗 (Broken Battle Flag)
- **Description:** Broken flag pole with tattered flag
- **Colors:** Pole `#4A3828`, flag cloth `#5A322B` (dried blood red), frayed edges `#3A221B`
- **Notes:** Flag should look torn — ragged bottom edge. Pole is snapped at top.

---

## UI Stat Icons (11 total)

### 1. icon_hp.png — 生命值 (HP)
- **Shape:** Heart (organic, not geometric)
- **Colors:** Dark red `#5A1818`, bright red `#8A2828`, outline `#2A0808`
- **Notes:** Slightly stylized — not a perfect heart, more like a torn flesh shape

### 2. icon_stamina.png — 体力 (Stamina)
- **Shape:** Circular gauge with lightning bolt
- **Colors:** Dark green `#1A4A2A`, bright green `#2A8A4A`, outline `#0A2A1A`
- **Notes:** Represents physical endurance. Green = vitality.

### 3. icon_attack.png — 攻击 (Attack)
- **Shape:** Downward-pointing sword/triangle
- **Colors:** Iron `#4A4035`, steel `#6A5A4A`, outline `#2A2520`
- **Notes:** Simple crossed swords or single sword pointing down

### 4. icon_armor.png — 护甲 (Armor)
- **Shape:** Shield outline
- **Colors:** Dark steel `#3A3530`, highlight `#5A5045`, outline `#2A2520`
- **Notes:** Song dynasty shield shape (rounded top, pointed bottom)

### 5. icon_crit.png — 暴击 (Critical Hit)
- **Shape:** Starburst / explosion
- **Colors:** Orange `#B4641E`, yellow `#E6A030`, outline `#8A4810`
- **Notes:** 4-point starburst. Should feel "explosive."

### 6. icon_speed.png — 速度 (Speed)
- **Shape:** Wing / chevron pointing right
- **Colors:** Grey `#5A5A5A`, light grey `#8A8A8A`, outline `#3A3A3A`
- **Notes:** Movement speed indicator. Forward-leaning chevron.

### 7. icon_sacrifice.png — 献祭 (Sacrifice)
- **Shape:** Circle with dripping blood / chalice
- **Colors:** Purple `#321E37`, dark red `#5A1818`, outline `#1A0E1F`
- **Notes:** Core mechanic icon. Should feel ominous — drop of blood falling into a vessel.

### 8. icon_ghostfire.png — 鬼火 (Ghost Fire - UI)
- **Shape:** Flame orb (same as weapon_ghostfire but framed for UI)
- **Colors:** Core `#4AE68A`, outer `#1EB464`, outline `#0A5030`
- **Notes:** Resource/element indicator. Same visual language as weapon version.

### 9. icon_boss.png — Boss
- **Shape:** Skull with horns
- **Colors:** Bone `#A0987A`, shadow `#3A3028`, horns `#5A4A3A`
- **Notes:** Used in boss health bar / boss intro. Should feel threatening even at 32px.

### 10. icon_key.png — 钥匙 (Key)
- **Shape:** Ancient Chinese key (skeleton key style)
- **Colors:** Bronze `#8A6A32`, highlight `#AA8A4A`, outline `#5A4220`
- **Notes:** Skeleton key — ring at top, teeth at bottom. Used for locked doors/chests.

### 11. icon_coin.png — 金币/阴钱 (Yin Coin)
- **Shape:** Round coin with square hole (Chinese cash coin)
- **Colors:** Bronze gold `#8B7332`, highlight `#AB9350`, shadow `#5A4A1A`
- **Notes:** Traditional Chinese coin (圆形方孔). Square hole in center. Yin money for the underworld.

---

## Design Notes for AI Art Generation
1. All icons must be readable at 32×32 — no fine details that disappear at this size
2. Use bold silhouettes — if you squint, you should still tell what it is
3. Consistent lighting: top-left light source for all icons
4. 1px dark outline on all icons for readability against any background
5. Maximum 4 colors per icon (outline + 2-3 fills)
