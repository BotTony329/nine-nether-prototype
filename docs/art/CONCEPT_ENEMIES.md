# Concept: Enemies — 鬼卒 / 鬼弓手 / 尸兽

> **Type:** Enemy Characters
> **Frame Size:** 48 × 48 px (humanoid), 64 × 48 px (beast)
> **Direction:** Face left by default (toward player)

---

## 1. 鬼卒 (Ghost Soldier) — Melee

### Visual Description
A reanimated soldier of a defeated ancient army, now serving as cannon fodder in the underworld. It shambles with rusted weapon in hand.

### Key Characteristics
- **Rusted weapon:** Broken spear or notched axe, held in one hand
- **Tattered robes:** Ancient military uniform, rotted to strips
- **Pale blue-grey skin:** Corpse-like, slightly translucent
- **Empty eye sockets:** Faint ghost-fire glow within
- **Hunched posture:** Not standing straight — decades of death have bent it

### Color Palette
| Part | Color | Hex |
|------|-------|-----|
| Skin | Corpse blue-grey | `#2D3746` |
| Skin highlight | Pale dead flesh | `#46566B` |
| Robes | Rotten dark teal | `#1E2A2A` |
| Weapon | Rusted iron | `#3A3028` |
| Eye glow | Ghost fire | `#B4641E` |
| Shadow | Deep void | `#0F0C12` |

### Animations
| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 4 | 8 | Swaying slightly, weapon dragging |
| run | 6 | 10 | Lurching forward, uneven gait |
| attack | 4 | 12 | Wild overhead chop with weapon |
| hurt | 2 | 10 | Recoils, parts of body flicker |
| death | 4 | 8 | Dissolves into blue mist |

### Design Notes
- Should look clearly "dead" — not a living soldier
- Movements are jerky and unnatural (puppet-like)
- The ghost-fire eye glow is the only warm color on the body

---

## 2. 鬼弓手 (Ghost Archer) — Ranged

### Visual Description
A spectral archer that fires soul arrows from a distance. Thinner and more ethereal than the Ghost Soldier.

### Key Characteristics
- **Bow:** Longbow made of bone/ghost energy, faintly glowing string
- **Quiver:** Worn at hip, arrows are wisps of ghost fire
- **Thin frame:** Gaunt, almost skeletal beneath tattered archer's garb
- **Hood:** Dark hood obscures most of the face
- **Floating slightly:** Feet barely touch ground — hovering

### Color Palette
| Part | Color | Hex |
|------|-------|-----|
| Skin | Sickly green-grey | `#323C37` |
| Skin highlight | Pale green | `#4B5F55` |
| Garb | Dark moss green | `#1E2820` |
| Bow | Bone white | `#8A8070` |
| Bowstring/arrow | Ghost fire | `#B4641E` |
| Hood shadow | Deep void | `#0F0C12` |

### Animations
| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 4 | 8 | Hovering, bow held loosely |
| run | 6 | 10 | Gliding forward, feet not touching ground |
| attack | 4 | 12 | Draws bow → releases ghost arrow → lower bow |
| hurt | 2 | 10 | Flickers, body becomes semi-transparent |
| death | 4 | 8 | Bow shatters, body disperses into green wisps |

### Design Notes
- Clearly distinguishable from Ghost Soldier by color (green vs blue) and build (thin vs hunched)
- The arrow should be visible as a distinct projectile (ghost fire wisp)
- Hovering/gliding movement replaces walking

---

## 3. 尸兽 (Corpse Beast) — Charge

### Visual Description
A massive quadruped formed from fused corpses of war horses and soldiers. It charges blindly, driven by rage.

### Key Characteristics
- **Quadruped:** Four legs, low-slung body, wider than humanoid enemies
- **Fused flesh:** Visible human limbs protruding from its mass
- **No eyes:** Just a gaping maw with too many teeth
- **Exposed bone:** Ribs and spine visible through rotted flesh
- **Size:** Visually larger and wider than other enemies (64×48 frame)

### Color Palette
| Part | Color | Hex |
|------|-------|-----|
| Flesh | Dark rotten brown | `#372823` |
| Flesh highlight | Rancid pink | `#5A4035` |
| Bone | Yellowed ivory | `#A0987A` |
| Mouth interior | Void black | `#0A080C` |
| Teeth | Stained bone | `#8A8060` |
| Blood | Dried crimson | `#5A1818` |

### Animations
| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 4 | 8 | Low growl, body heaving, limbs twitching |
| run | 6 | 14 | Fast charge — all four legs, mouth open |
| attack | 4 | 12 | Lunge forward, jaws snapping |
| hurt | 2 | 10 | Recoils, limbs spasm |
| death | 4 | 8 | Collapses, flesh sloughing off bones |

### Design Notes
- The charge (run animation) should feel FAST and DANGEROUS — this is the core behavior
- Frame is 64×48 (wider) to accommodate the quadruped body
- Mouth should be the most visually striking element (threat indicator)
- No ghost fire on this enemy — it's pure flesh/horror, not spectral
