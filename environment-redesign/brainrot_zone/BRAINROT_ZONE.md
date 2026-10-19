# World 3 — Brainrot Zone (Stage 5, 2026-10-19) · APPROVED by crnuch 2026-10-19

The game's "Brainrot Boulevard" zone as a surreal neon island at dusk: a zig-zag neon boulevard lined with giant
statues of the game's own brainrot lawyers, glowing skyscrapers, a melting mall, a twisting tower, floating cubes and
eyeballs, goo waterfalls, and a checkerboard boss pit. Built in the shared kit (`../kit/`: `hl_kit`, `hl_island`,
`hl_world`, `hl_ambience`) plus this island's own pieces in `br_parts.py`.
```bash
Blender -b --python environment-redesign/brainrot_zone/br_build.py              # .blend + layout JSON + renders
Blender -b --python environment-redesign/brainrot_zone/br_ambience.py           # + the ambience, saved into the .blend
```

| Deliverable | File |
| --- | --- |
| Editable .blend (ambience animated: scrub the timeline) | `brainrot_zone.blend` |
| Aerial beauty render | `renders/br_aerial.jpg` |
| Labelled top-down layout | `renders/br_layout_topdown.jpg` |
| Ground views | `renders/br_ground_arrival.jpg`, `br_ground_boulevard.jpg`, `br_ground_fields.jpg`, `br_ground_arena.jpg` |
| Cliff view | `renders/br_cliff.jpg` |
| Positions (Blender + Roblox coords) | `br_layout.json` |

## The route (return portal past the boss, as decided)
```
ARRIVAL (south) ──> glitched BRAINROT BOULEVARD gate ──> zig-zag NEON BOULEVARD (3 giant lawyer statues)
        ──> side paths to 3 EGG FIELDS (Glitch Garden W · Wobble Square E · Upside-Down Park NE)
        ──> THE GAVEL PIT (Judge Martello) ──> RETURN HOME portal (north)
```
| Place | Blender (x, y) | What |
| --- | --- | --- |
| Arrival pad + plaza | (0, −161) / (0, −155) | Dark studded plaza with cyan + magenta neon rings; Travel lands here |
| BRAINROT BOULEVARD gate | (0, −127) | An arch whose blocks are knocked out of line (a "glitch") |
| Neon boulevard | (0, −131) → (0, 29) | 14 wide, dark studded "night" floor, cyan edges, magenta chevrons pointing to the arena; wobbly neon lamps; three side paths (magenta) to the fields |
| Giant lawyer statues | (−50, −96) / (50, −34) / (−52, −6) | The game's own CactusinoAvvocatino ×4.0, DraghettoSpaghetto ×3.4, ImperatorePinguino ×2.4 (from `tools/zones/lawyers_top.json`), on neon plinths, facing the boulevard |
| Glitch Garden | (−98, −55), r 30 | Checkerboard lawn (teal / lilac), pixel trees, cyan rim |
| Wobble Square | (96, −72), r 28 | Dark plaza ringed by five leaning towers (each leans more per block), giant dice |
| Upside-Down Park | (96, 8), r 26 | A cottage standing on its roof (furniture on the "ceiling"), upside-down trees |
| **THE GAVEL PIT (boss arena)** | (0, 80), open floor r 52 | Neon checkerboard floor, a cyan ring and a gold gavel emblem; neon pylons round the rim (open S + N); four giant speakers outside; a marquee at the south entrance |
| **RETURN HOME portal** | (0, 154) | Magenta / violet ring with a voxel-brain keystone; the green home field is the same on every island |
| Big Screen | (−112, 30) | Dark tower with a giant cartoon-face screen (a fictional face) |
| Twisty Tower | (−76, 132) | Every floor turned 7.5°, stepped spire |
| Melty Mall | (92, 128) | The roof melts down the walls in drips |
| Neon towers | LOL LAW (−128, −20) · OBJECTION! (−120, 88) · SIGMA SUITS (126, 66) · GIGA CASE (124, −112) · BRAIN LAB (−90, −128) | Dark skyscrapers 34–52 tall, glowing window strips, stepped crowns, rooftop signs (made-up names only) |
| Odd giant objects | gelato ×3, traffic cones ×2, floating eyeballs ×4, 22 floating cubes | Along the boulevard, by the arena, over open ground |

- Island: ~320 × 380 studs, violet top with purple cliff strata and glowing crystal clusters.
- Two goo waterfalls (SW at 225°, E at 346°), each fed by a glowing goo pond and a stream, clear of the fields.
- 13 pixel-tree groves (one colour each), stepped hills, clouds and islets.
- The portal's spot comes from the island's real north edge, so it never overhangs.

## Gameplay numbers (Judge Martello, `Config.Bosses`, `docs/BOSSES.md`)
| | Value | Arena check |
| --- | --- | --- |
| Size | Scale 3.4 → ~19 studs tall, 24 wide | Placed in the .blend at that scale (`Boss_JudgeMartello`, at (6, 86)) |
| Attack | **Slam**, Radius 26, Windup 1.1 s, every 3 s, hop 6 high; it lands where you WERE when it jumped; WalkSpeed 40 | Open floor r 52 = two slam radii: in the 1.1 s windup a player runs ~35 studs (more than 26), and no wall is in the way |
| Suggested boss area | Blender x −37…37, y 43…117 (Roblox x −37…37, z −117…−43, island-local) | The largest square inside the floor circle: Martello stays on the checkerboard, but his 26-stud slam still reaches the rim. (BossService derives the area from the zone's `Bounds` minus `Margin`: integration sets it directly, `../README.md` → "Notes for Stage 7") |
| Field distances (TriggerRange 60) | Upside-Down Park's west edge is ~43 studs from his nearest point | Inside the trigger, so he turns and hops toward you there, but BossService clamps a Slam's landing to his area: it lands ~17 studs short, a scare, not a hit (corrected 2026-10-19). Kept small (4 eggs). Glitch Garden (~85) and Wobble Square (~100) are out of range. **The real danger is crossing the pit** to RETURN HOME. The boulevard's last stretch is inside his reach by design |

## Egg spots — 24
| Where | Spots |
| --- | --- |
| Glitch Garden / Wobble Square | 8 each |
| Upside-Down Park (inside his trigger) | 4 |
| THE GAVEL PIT (bonus, inside the arena) | 4 |

- Spots are sampled on open ground inside each field, clear of props, ≥ 7 studs apart.
- The zone spawns up to 14 eggs at once (`Config.Zones.List` MaxEggs); it picks from these 24 spots.
- The **Brainrot egg** design: a purple voxel egg with neon zig-zag bands (golden variant too). It's the island's
  themed egg (`EggLook` in game).

## Models (`br_parts.py`, studded brick, Blender-made)
| Group | Pieces |
| --- | --- |
| Buildings | Neon tower (strips, stepped crown, antenna, rooftop sign), Big Screen (cartoon face), Twisty Tower (turned floors, stepped spire), Melty Mall (dripping roof), upside-down cottage |
| Landmarks | Glitch gate, THE GAVEL PIT (checkerboard, pylons, speakers, marquee), brain-keystone RETURN HOME portal, statue plinths |
| Odd objects | Leaning towers, giant dice, gelato (stepped wafer cone + voxel scoops), traffic cones (stepped, white bands), floating eyeballs (voxel), floating cubes |
| Street pieces | Neon strips + signs, wobbly lamps, chevrons |
| Plants | Pixel trees, upside-down trees |
| Eggs | Brainrot eggs + spot rings |

Totals: 332k tris + 210k raised studs (one 48-tri stud mesh, instanced; 5.4 MB .blend). Lamp heads and antenna lights are glowing bulbs (smooth
spheres, as on the hub); everything solid is studded brick.

## Ambience
### Visual (`br_ambience.py`, in the .blend: no preview clips, crnuch's call 2026-10-19)
"Exciting without strobing" (the brief). **Young players: nothing flashes faster than 3 Hz** (photosensitivity), so
the neon breathes and the bulbs blink slowly.
| Effect | How |
| --- | --- |
| Neon breathes: magenta, cyan, lime, green, each at its own slow rate (never in sync) | Emission drivers (sine) |
| Window strips breathe very slowly; marquee bulbs blink (~1.4 Hz) | Emission drivers (sine / square) |
| Goo flows down both falls; the goo ponds ripple | Animated shaders |
| RETURN HOME breathes | Emission driver |
| **Floating cubes bob**; clouds + islets drift (their studs ride with them) | Keyframes. The cubes only float over open ground, so the bob never meets a tower |
| **Judge Martello's "boing"**: a small hop in place with a sway | Keyframes, pivoted at his feet, in the middle of the empty floor |
| Neon sparkles rise over the island | One particle system (tiny cyan motes) |
| Pixel-tree canopies sway (with their studs) | Shared `WindSway` |

### Audio (research only, nothing downloaded or listened to; tiers as in `../central_hub/AUDIO.md`)
Licences below were read on each sound's own page (2026-10-19).
| Layer | Tier 1 (Creator Store search) | Tier 2 pick (licence checked) |
| --- | --- | --- |
| Primary bed: electronic hum + synth | "synth ambience", "sci-fi hum" | [Sci-Fi Lab Ambience](https://freesound.org/people/Zeraora/sounds/726006/) (Zeraora, **CC0**, 0:24, 44.1 kHz mono, tagged loopable): a low glitched tone; keep it quiet, since it's tagged dark |
| Distorted synth sweetener | "synth arpeggio", "funny synth" | [synth arpeggio.wav](https://freesound.org/people/antoinevg/sounds/368000/) (antoinevg, **CC0**, 0:09, 44.1 kHz mono, a loop; its second half is wavefolder-distorted) |
| Neon hum by the towers and signs (3D, short roll-off) | "neon buzz", "electric hum" | [Neon Lamp, Switch On, Hum](https://freesound.org/people/Kinoton/sounds/351430/) (Kinoton, **CC0**, 0:26, 48 kHz stereo): cut after the switch-on and loop the hum; mono for 3D |
| Glitch one-shots (random, every 8–20 s, from the gate and the Big Screen) | "glitch", "digital error" | [Glitch Corruption](https://freesound.org/people/dotY21/sounds/348585/) (dotY21, **CC0**, 1.3 s, 44.1 kHz) |
| Comedic cartoon sounds (wobbly lamps, dice, Martello's landings) | "cartoon boing", "spring" | [Boing 2](https://freesound.org/people/magnuswaker/sounds/540790/) (magnuswaker, **CC0**, 1.1 s jaw harp, 96 kHz: resample to 48 kHz) |
| Goo falls + ponds | "slime bubbling", "goo"; or `Sfx` `fountain` pitched down | — |
| THE GAVEL PIT | an APM tension sting when the boss targets you; the slam is the boss's own sound (BossService) | — |
| Music | APM "quirky electronic", "funny synth", "8-bit happy" | — |

## Roblox compatibility notes (integration later, on approval)
**Dynamic, so not scenery:** eggs on `EggSpots`; the boss (BossService + Bosses.client; its new `Bounds` above);
`Arrival`; RETURN HOME's carry rule (code later).

**Collision:**
- solid: ground, plazas, boulevard, the pit floor, buildings, plinths, leaning towers, dice, statues
- no collision: floating cubes and eyeballs, neon strips, lamp heads, goo falls, sparkles, canopies

**Mapping the look:**
- `glow_*` looks → `Material.Neon`.
- The goo falls and ponds → a scrolling `Texture` (or a `Beam` with a moving texture), as for water.
- Floating cubes → client-only bob (like `WorldLife`), anchored, CanCollide off.
- Martello's idle is BossService's own animation: the .blend's hop is presentation only.
- **The neon only pops at dusk:** the zone needs its own local lighting while a player is in it (a purple
  `Atmosphere`, later `ClockTime`, a client-side swap like `HatchFx.stage`). Otherwise it renders in the hub's daylight.

**Particles in Roblox:** sparkles → one ParticleEmitter, low Rate, LightEmission ≤ 0.3 (CLAUDE.md), culled by
distance.

**Streaming:** the fields, the boulevard, the pit and each tower are separate objects.

## Known weaknesses (honest)
- **Mostly purple from far away:** the violet ground, purple cliffs and dusk sky read as one colour from a distance;
  the dark boulevard, neon and the green portal are what break it up.
- **Daylight:** the look depends on the dusk lighting (above). In daylight the neon would look flat.
- **Plain interiors:** the towers and shops are shells (window strips, signs, props); the interiors aren't modelled.
- **Glowing bulbs:** lamp heads, antenna lights and the leaning towers' tip orbs are smooth glowing spheres.
