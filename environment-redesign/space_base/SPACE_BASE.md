# World 6 — Space Base (Stage 5, 2026-10-19) · waiting for crnuch's approval

A lunar base on its own floating island under a starry sky: an airlock gate, a red-and-white rocket on its launch pad,
Mission Control's hologram planet ringed by eight kiosks, three egg fields (craters, alien plants, crystals), glowing
plasma falls, and the round Eclipse Ring where Chief Justice Eclipse pulls and throws his gavels. Built in the shared
kit (`../kit/`) plus this island's pieces in `sb_parts.py`, on mr.robe's Windows PC (Blender 5.2). Also built into the
place (`Workspace.WorldRedesign.SpaceBase`, its NW slot on the ring; see `../README.md` → "Building into the place").
```bash
Blender -b --python environment-redesign/space_base/sb_build.py              # .blend + layout JSON + renders
Blender -b --python environment-redesign/space_base/sb_ambience.py           # + the ambience, saved into the .blend
Blender -b --python environment-redesign/kit/export_island.py -- space_base sb_build.py SpaceBase   # -> Roblox parts JSON
```

| Deliverable | File |
| --- | --- |
| Editable .blend (ambience animated: scrub the timeline) | `space_base.blend` |
| Aerial beauty render | `renders/sb_aerial.jpg` |
| Labelled top-down layout | `renders/sb_layout_topdown.jpg` |
| Ground views | `renders/sb_ground_arrival.jpg`, `sb_ground_plaza.jpg`, `sb_ground_fields.jpg`, `sb_ground_arena.jpg` |
| Cliff view | `renders/sb_cliff.jpg` |
| Positions (Blender + Roblox coords), steam / spore / turning points | `sb_layout.json` |
| Roblox parts (13,283) | `../../tools/zones/redesign/SpaceBase.json` |

## The route (return portal past the boss, as decided)
```
ARRIVAL (south, the landing pad) ──> SPACE BASE airlock gate ──> orange path (rocket + launch pad, Space-lawyer statues)
        ──> MISSION CONTROL PLAZA (hologram planet, 8 kiosks, tables) ──> side paths to 3 EGG FIELDS
            (Crater Field W · Alien Garden E · Crystal Field NE, off the east path)
        ──> THE ECLIPSE RING (Chief Justice Eclipse) ──> RETURN HOME portal (north)
```
| Place | Blender (x, y) | What |
| --- | --- | --- |
| Arrival pad + plaza | (0, −197) / (0, −191) | Orange studded landing plaza on the moon; Travel lands here |
| SPACE BASE gate | (0, −165) | An airlock: chunky white pylons with hazard-striped feet and neon strips, the doors slid open into them, a navy marquee, red beacons, an antenna |
| ROCKET + LAUNCH PAD | (−64, −118) | A red-and-white rocket (bands, portholes, fins, nose cone, engine bells) on an octagon pad with hazard rings, a lattice gantry with two arms; steam curls off the pad (ambience) |
| MISSION CONTROL PLAZA | (0, −42), r 34 | Ringed white / grey / lilac / purple tiles with a neon edge; a stepped white pedestal with consoles and a faint light column under a **hologram planet** (ring + two moons) that turns; eight kiosks facing in (ASTRO SNACKS, MOON ROCKS, STAR MAPS, SPACE SUITS, COSMIC CONES, ROBOT REPAIR, ALIEN PETS, GADGETS), each a white pod with a stepped dome, a coloured band and a prop on top; neon light strings round the ring; four tables with holo lamps. The four compass lanes stay open |
| Space-lawyer statues | Comet (38, −136), Nebula (−34, −88), Supernova Sovereign (−58, −4) | The game's own Space Epic / Mythic / Supreme lawyers (from `tools/zones/lawyers_top.json`) at ~28 studs, on plinths with a neon ring |
| Lawn landmarks | moon rocks (44, −70), a meteorite with glowing cracks (−44, −60) | |
| Crater Field | (−114, −14), r 34 | Dark moon dust with five craters, moon rocks, a meteorite, a planted base flag, a moon rover |
| Alien Garden | (116, −42), r 32 | Purple soil: glowing mushrooms, tentacle plants with glowing tips, bulb plants, spike plants; glowing spores drift (ambience) |
| Crystal Field | (116, 92), r 24 | Pale moon ground with crystal clusters (cyan, pink, violet) with glowing cores |
| **THE ECLIPSE RING (boss arena)** | (0, 76), r 72 | A round, open, studded observation floor (navy with purple bands, gold rings), an eclipse emblem in the middle, a constellation of neon dots and gold lines, low rim blocks with gaps at south + north; an ECLIPSE RING marquee, star charts and beacon lamps at the south entrance; four telescopes outside the rim |
| **RETURN HOME portal** | (0, 176) | Violet / purple / lilac ring, a ringed-planet keystone; the green home field is the same on every island |
| Buildings | OBSERVATORY (−118, 62), HABITAT DOMES (138, 26), ROBOT FACTORY (105, −118), SOLAR FARM (−82, 150), FUEL DEPOT (86, 150), SATELLITE DISH (−150, 8), UFO LANDING (−130, −72) | Decor shells. The observatory dome, the factory's radar and the big dish TURN (ambience). The UFO is a fictional flying saucer |
| Plasma falls | west (−129, −104) at 219° · east (125, −91) at 324° | A glowing plasma pool, a stream and a fall off the edge each. The build picks angles clear of everything placed before it |

- Island: ~360 × 425 studs; a studded lilac-grey moon top with craters, moon dunes topped with crystals, alien
  plants, crystal clusters and moon rocks scattered over it (77 decor pieces in all); purple-grey rock strata below.
- The sky: 26 drifting asteroids round the island (some with crystals); in Blender only, a starfield (900 stars,
  above and below the horizon), a ringed purple planet and a pale moon (`Sky_Backdrop`, not exported: the place gets
  a space skybox at wiring time). The camera sees deep space; the scene is lit by a lifted purple sky + a cool sun.
- The ring's north edge is computed from the portal stairs (6 studs short), and the portal from the island's real
  north edge.

## Gameplay numbers (Chief Justice Eclipse, `Config.Bosses`, `docs/BOSSES.md`)
| | Value | Arena check |
| --- | --- | --- |
| Size | Scale 3.2 → ~31 studs tall, 21 × 22 across, hovering | Placed in the .blend at that scale (`Boss_Eclipse`, at the ring's centre, 1 stud above the floor) |
| Attacks | **Pull** (Gravity Pull): Radius 44, Inner 12, PullTime 2 s, PullSpeed 16, Windup 1.4 s · **Ring** (Gavel Orbit): RingRadius 38 · every 2.5 s; WalkSpeed 44 | The floor is r 72. In the 1.4 s windup a player runs ~45 studs, enough to leave a 44-stud circle from its centre; walking straight out escapes the pull (PullSpeed 16 < WalkSpeed 32) |
| Suggested boss area | Blender x −26…26, y 50…102 (Roblox x −26…26, z −102…−50, island-local): a 52 × 52 box round the ring's centre | Pull circle (r 44) and gavel ring (r 38) cast from anywhere in it stay on the floor (26 + 44 = 70 < 72) |
| Distances (TriggerRange 60) | The plaza is 58 from the area; Crystal Field 66; Crater Field 75; Alien Garden 97 | Nothing outside the ring is reachable by either attack. **The real danger is crossing the ring**, the only way to RETURN HOME: its north and south gaps line up, so the way through runs right past him (Extreme boss) |

**Integration note (BossService today):** the boss's area is the zone's `Bounds` shrunk by `Margin`. An island arena
needs the area set directly (e.g. a per-boss `Arena` box): see `../README.md` → "Notes for Stage 7".

## Egg spots — 24
| Where | Spots |
| --- | --- |
| Crater Field / Alien Garden | 8 each |
| Crystal Field | 4 |
| THE ECLIPSE RING (bonus, on the ring, r 34 from the centre) | 4 |

- Spots are sampled on open ground inside each field, clear of props (craters, plants, crystals), ≥ 7 studs apart.
- The zone spawns up to 14 eggs at once (`Config.Zones.List` MaxEggs); it picks from these 24 spots.
- The **Space egg** design: deep purple with a gold planet-ring band, a neon cyan band and little neon stars (golden variant).

## Models (`sb_parts.py`, studded brick, Blender-made)
| Group | Pieces |
| --- | --- |
| Base props | Beacon lamps, craters, moon rocks, a meteorite, base flags, a moon rover, telescopes, star charts, neon light strings |
| Alien life + minerals | Glowing mushrooms, tentacle plants, bulb plants, spike plants, crystals + crystal clusters |
| Buildings | Space kiosk (×8), ROCKET + launch pad + gantry, OBSERVATORY (+ turning dome), HABITAT DOMES, ROBOT FACTORY (+ radar), SOLAR FARM, FUEL DEPOT, SATELLITE DISH, UFO LANDING |
| Landmarks | SPACE BASE airlock gate, Mission Control's hologram fountain + hologram planet, THE ECLIPSE RING, ringed-planet RETURN HOME portal, statue plinths |
| Eggs | Space eggs + spot rings |

Totals: 404k tris + 197k raised studs; 6.0 MB .blend; 13,283 Roblox parts.

## Ambience
### Visual (`sb_ambience.py`, in the .blend: no preview clips, crnuch's call 2026-10-19)
Quiet, glowing, a little mysterious. Nothing flashes faster than 3 Hz. Clearances are reasoned in the script's header.
| Effect | How |
| --- | --- |
| **Hologram planet** turns over Mission Control (14 s a turn) | Its own see-through glowing object, pivoted on the projector |
| **Observatory dome** creeps round (60 s), **radar** sweeps (6 s), **big dish** turns (16 s) | Each its own object, its studs riding with it (`K.STUD_GROUP`) |
| **Steam** curls off the rocket's launch pad | Particles (soft white puffs) |
| **Spores** drift over the Alien Garden | Particles (tiny glowing green motes) |
| Plasma pools ripple, plasma falls flow | Animated shaders (cyan sheen) |
| Neon breathes; red beacons blink (~0.7 Hz); marquee bulbs blink (~1.4 Hz) | Emission drivers |
| Chief Justice Eclipse hovers (4°, a 1-stud bob) | Keyframes, pivoted at his feet |
| Asteroids drift (their studs ride along) | Keyframes |

### Audio (research only, nothing downloaded or listened to; tiers as in `../central_hub/AUDIO.md`)
Licences below were read on each sound's own page (2026-10-19, via curl).
| Layer | Tier 1 (Creator Store search) | Tier 2 pick (licence checked) |
| --- | --- | --- |
| Primary bed: a soft spaceship / base hum | "space ambience", "spaceship hum", "sci-fi drone" | [Spaceship Ambience](https://freesound.org/people/nick121087/sounds/234316/) (nick121087, **CC0**, 0:42, 48 kHz stereo); darker alternative: [spacedrone3.wav](https://freesound.org/people/Elektrocell/sounds/20705/) (Elektrocell, **CC0**, 1:14, 44.1 kHz stereo). Keep it low and friendly (young audience) |
| Base life: computer + robot beeps (random, 3D at the kiosks + the factory) | "computer beeps", "robot beep" | [Retro Sci Fi Computer](https://freesound.org/people/notKlaatu/sounds/260103/) (notKlaatu, **CC0**, 0:05, 44.1 kHz mono); [Beeping Robot or Machine](https://freesound.org/people/Jofae/sounds/363251/) (Jofae, **CC0**, 0:02, 44.1 kHz stereo) |
| The rocket: a distant low rumble now and then (3D at the pad) | "rocket rumble", "launch" | [Rocket Launch Rumble at Canaveral](https://freesound.org/people/felix.blume/sounds/613855/) (felix.blume, **CC0**, 4:25, 96 kHz stereo): take a short, quiet slice |
| Plasma falls | `Sfx` `fountain` (already licensed), pitched down + filtered | — |
| THE ECLIPSE RING | an APM tension sting when the boss targets you; the pull / gavels are the boss's own sounds (BossService) | — |
| Music | APM "space adventure", "synth wonder", "cosmic kids" | — |

## Roblox compatibility notes (integration later)
**Dynamic, so not scenery:** eggs on `EggSpots`; the boss (BossService + Bosses.client, with its arena area above);
`Arrival`; RETURN HOME's carry rule (code later); a space skybox / Lighting for this island (zone Lighting at wiring).

**Collision:** solid ground, paths, the plaza, the ring floor + rim, kiosks, buildings, the rocket + pad, statues,
rocks, crystals' bases; no collision for neon, holograms, the light column, spores / steam, plasma (wadeable), the
asteroids, small bits.

**Mapping the look:** turning objects → client-only rotation (like `WorldLife`); hologram → Neon / ForceField with
Transparency; steam / spores → ParticleEmitters at the `sb_layout.json` points; plasma → Neon-tinted Glass with
scrolling textures; `glow_*` → Neon.

## Known weaknesses (honest)
- **Open moon:** between the plaza, the fields and the ring the moon is wide and plain (craters, dunes and scattered
  plants break it up). The edge buildings carry most of the detail.
- **Plain interiors:** kiosks and buildings are shells (doors, windows, signs, props); no interiors.
- **Upright-only pieces:** the kit only turns bricks round the vertical, so the dish bowl, the telescope tubes and
  the gantry arms are stepped blocks, never tilted.
- **The ring is wide open on purpose:** from far away it reads as one big dark disc; the gold rings, the emblem, the
  constellation and the rim carry the theme.
- **Night in Blender, day in Studio:** the place still has the day sky; the island needs its own skybox at wiring.
