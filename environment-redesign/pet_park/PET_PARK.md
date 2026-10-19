# World 2 — Pet Park (Stage 5, 2026-10-18) · APPROVED by crnuch 2026-10-19

A lush, cheerful animal park on its own floating island: winding orange paths, a pond with a giant corgi, fenced
pet meadows, and a dog-run boss arena. Built in the shared kit (`../kit/`), now including `hl_world.py`, the
themeable pieces every island shares: signs, arrival pad, RETURN HOME portal, boss floor, eggs, winding paths.
```bash
Blender -b --python environment-redesign/pet_park/pp_build.py              # .blend + layout JSON + renders
Blender -b --python environment-redesign/pet_park/pp_ambience.py           # + the ambience, saved into the .blend
```

| Deliverable | File |
| --- | --- |
| Editable .blend (6.4 MB; ambience animated, scrub the timeline) | `pet_park.blend` |
| Aerial beauty render | `renders/pp_aerial.jpg` |
| Labelled top-down layout | `renders/pp_layout_topdown.jpg` |
| Ground views | `renders/pp_ground_arrival.jpg`, `pp_ground_pond.jpg`, `pp_ground_meadow.jpg`, `pp_ground_arena.jpg` |
| Cliff view | `renders/pp_cliff.jpg` |
| Positions (Blender + Roblox coords) | `pp_layout.json` |

## The route (return portal past the boss, as decided)
```
ARRIVAL (south) ──> PET PARK bone gate ──> winding path ──> THE POND (giant corgi on its island)
        ──> pond loop ──> 3 EGG MEADOWS (Dog Meadow W · Cat Garden E · Bunny Hills SE)
        ──> BARK COURT (Barrister Bulldog) ──> RETURN HOME portal (north)
```
| Place | Blender (x, y) | What |
| --- | --- | --- |
| Arrival pad + plaza | (0, −161) / (0, −155) | Pink-ringed plaza; Travel lands here |
| PET PARK gate | (0, −127) | Paw-print posts, a giant bone across the top, a marquee |
| The pond | (0, −25), water r 26 | Lily pads; a ~23-stud **giant corgi** on its mossy island; an arched wood bridge from the south; benches; palms round the loop |
| Dog Meadow | (−102, −28), ellipse 40 × 36 | White picket fence; REX / BISCUIT / NOODLE doghouses, a giant bone, tennis balls, hydrants, a giant water bowl |
| Cat Garden | (100, −22), 38 × 34 | Pink picket fence; two cat towers, a giant cat, yarn balls, flower beds |
| Bunny Hills | (72, −115), 26 × 24 | Wood fence; a rabbit hutch with carrots, a bunny topiary |
| **BARK COURT (boss arena)** | (0, 78), open floor r 54 | Green studded court with a white bone emblem; white picket rim with pink gateposts (openings S + N); agility course outside (hurdles, tunnels, weave poles) and a little judge's bench; marquee |
| Giant cat / bunny topiary | (±40, 148) | Sculptures by the north exit |
| **RETURN HOME portal** | (0, 156) | Pink / yellow ring, green home field (the same on every island), a paw keystone |
| PAW CLINIC / FLUFF & PUFF / THE BARKERY | (−118, 52) / (118, 52) / (−66, −128) | Vet, groomer, dog bakery café (decor) |

- Island: ~340 × 380 studs.
- Two waterfalls (SW, SE), each fed by a pond and a stream.
- 14 birdhouses on posts, flower beds, wildflowers, blossom / oak / pine groves, palms, stepped hills, clouds and
  islets.
- The portal's spot is computed from the island's real north edge (182.7) so it never overhangs.

## Gameplay numbers (Barrister Bulldog, `Config.Bosses`, `docs/BOSSES.md`)
| | Value | Arena check |
| --- | --- | --- |
| Size | Scale 3.5 → ~26 studs tall | Placed in the .blend at that scale (`Boss_BarristerBulldog`) |
| Attack | **Ring** bark, Radius 34, Windup 1.4 s, every 3 s; WalkSpeed **44** (players 32) | Open floor r 54: room to get out of the 34-stud ring in the windup, with no fence in the way |
| Suggested `Bounds` | Blender x −52…52, y 26…130 (Roblox z −130…−26) | |
| Meadow distances | Nearest meadow edges are ~70 studs from the arena's centre | With the boss on the south rim (y ~30), Cat Garden's and Dog Meadow's north edges are ~55–65 away: at the edge of its 60-stud trigger. Unlike Briefcase Bay, the meadows are mostly safe; the danger is crossing BARK COURT |

## Egg spots — 24
| Where | Spots |
| --- | --- |
| Dog Meadow / Cat Garden | 8 each |
| Bunny Hills | 4 |
| BARK COURT (bonus, inside the arena) | 4 |

- Spots are sampled on open lawn inside the fences, clear of props, ≥ 7 studs apart.
- The **Pet egg** design: a sky-blue voxel egg with a white band and pink paw prints (golden variant). It's the
  island's themed egg for the Pet egg (`EggLook` in game).

## Models (`pp_parts.py`, studded brick, Blender-made)
| Group | Pieces |
| --- | --- |
| Sculptures | Giant corgi (sitting, ears, tongue, tail, mossy plinth), giant cat (whiskers, curled tail), bunny topiary (cotton tail) |
| Pet houses | Doghouse (stepped gable roof, name plate, food bowl) ×3, cat tower ×2 (perches, hidey box, toy ball), birdhouses ×14, rabbit hutch (wire window, carrots) |
| Toys | Giant bone, tennis balls, giant water bowl, yarn balls, fire hydrants |
| Buildings | PAW CLINIC (sky-blue, paw medallion), FLUFF & PUFF (pink + purple, soap bubbles), THE BARKERY (bone sign, umbrella tables): shared two-storey pet-shop shell with awnings, flower boxes, paw prints |
| Park pieces | Picket fences (white / pink / wood), arched wood bridge, lily pads, benches, flower beds |
| Landmarks | Bone gate, BARK COURT (agility course, judge's bench), paw-keystone RETURN HOME portal, Pet eggs + spot rings |

Totals: 416k tris + 236k raised studs (one 48-tri stud mesh, instanced).

## Ambience
### Visual (`pp_ambience.py`, in the .blend: no preview clips, crnuch's call 2026-10-19; clearance rules from `../central_hub/AMBIENCE.md`, checked per prop in its header)
| Effect | How |
| --- | --- |
| Blossom / oak / pine canopies and palms sway (with their studs) | Shared `WindSway` |
| **Petals + leaves drift down** over the island | One particle system picking pink petals and green leaves at random, tumbling, near-weightless |
| Butterflies over Dog Meadow, Cat Garden and the pond | Above every prop in each ring |
| The pond ripples; both waterfalls flow | Animated shaders |
| The arrival pad and RETURN HOME breathe; marquee bulbs blink | Emission drivers |
| **Barrister Bulldog idles** (a waddle-sway); clouds drift | Keyframes |

### Audio (research only, nothing downloaded or listened to; tiers as in `../central_hub/AUDIO.md`)
| Layer | Tier 1 (Creator Store search) | Tier 2 pick (licence checked) |
| --- | --- | --- |
| Primary bed: birds in a park | "park birds", "summer meadow" | [Bird Park Ambience](https://freesound.org/people/nick121087/sounds/234315/) (nick121087, **CC0**, 1:06, 48 kHz): the hub's bed fits here too |
| Rustling leaves + gentle wind | "wind trees" | [Soft Wind in the Trees](https://freesound.org/people/Borgory/sounds/751473/) (Borgory, **CC0**, 2:26) |
| Distant barking | "dog bark distant" | [countryside … dog barking afar](https://freesound.org/people/philippe%20b/sounds/165567/) (philippe b, **CC0**, 0:31, AIFF 96 kHz): a night take, so cut just the barks and resample to 48 kHz |
| Playful animals | "cat meow", "puppy", "bunny" | [Kitten Meowing](https://freesound.org/people/lolamadeus/sounds/196251/) (lolamadeus, **CC0**, 0:09, 44.1 kHz); [Cat Meow](https://freesound.org/people/Mafon2/sounds/436541/) (Mafon2, CC0 per listing) |
| Pond + waterfalls | `Sfx` `fountain` (already licensed) | Nox_Sound waterfall loop (CC0) |
| Butterflies / petals | none (visual only) | — |
| BARK COURT | an APM tension sting when the boss targets you; its bark is the boss's own attack sound (BossService) | — |
| Music | APM "playful ukulele", "kids happy" | — |

## Roblox compatibility notes (integration later, on approval)
**Dynamic, so not scenery:** eggs on `EggSpots`; the boss (BossService + Bosses.client; its new `Bounds` above);
`Arrival`; RETURN HOME's carry rule (code later).

**Collision:**
- solid: ground, plazas, paths, the bridge, BARK COURT, buildings
- no collision: canopies, flowers, petals, lily pads, water, fences' tops

**Particles in Roblox:** petals / leaves → ParticleEmitter with a small square texture, low Rate, slow fall, Drag,
SpreadAngle 180, culled by distance.

**Streaming:** meadows, the pond and BARK COURT are separate objects.

## Known weaknesses (honest)
- **Wide arena:** the open court reads very green and wide from above; the agility props sit outside the fence (by
  design, so the floor stays clear).
- **Plain shop interiors:** the shops share one shell (themed by colour, sign and props); the interiors aren't
  modelled.
- **Flat lawns:** the lawns between groves are flat studded grass with scattered flowers and a few hills.
