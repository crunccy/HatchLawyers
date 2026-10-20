# World ambience & atmosphere (crnuch's brief, 2026-10-20)

Environmental VFX + lighting for the six boss zones. **Not a map redesign:** no buildings, terrain, layout, model or
boss changes; the classic studded look stays. Everything is **client-side** (lighting is per client; nothing
replicates or is saved).

| Piece | Where |
| --- | --- |
| The one controller | `StarterPlayerScripts.Ambience` (`src/Ambience.client.lua`) |
| Each zone's look (data only) | `ReplicatedStorage.Shared.AmbiencePresets` (`src/AmbiencePresets.lua`) |
| New particle textures | `tools/ambience_textures.py` -> `Models - Effects/amb_*.png` (ids in `ASSET_IDS.md`, uploaded from crnuch's Studio) |
| EffectsLod opt-out | emitters with attribute `NoLod` are left to their own script (`EffectsLod.client`, one line) |
| Before / after shots | `art/ambience/<zone>/` (`petpark_before_after.jpg` = the sheet) |

## How it works
- **Where:** every 0.25 s - the lane (`Config.Zones.List[n].Bounds`, +6 studs in z so the License gate gap never
  flickers back to the hub look) or a redesign island (`Workspace.IslandWiring.<Id>` BoundsMin/Max + 40). By zone id,
  so the lane and the islands get the same look; the lane <-> island hop keeps the look and builds that map's anchors.
- **Look:** cross-fades (3 s, smoothstep) Lighting (Ambient, OutdoorAmbient, ColorShift, Exposure, Env scales,
  ClockTime the short way round), the place's `Atmosphere`, the place's `Bloom` + `SunRays`, and its own
  `ColorCorrectionEffect` "AmbienceGrade" (stacks on the place's ColorCorrection). Outside every zone it fades back to
  the place's own values, captured when the client starts (the hub keeps exactly its look). **It only writes while a
  fade runs**, so nothing else ever has to fight it.
- **Hands off** while `TravelFx` flies you (player attribute `Traveling`) or a hatch owns the post effects
  (`HatchCC` on the camera; the Mythic / Supreme stage at y 3000): those save + restore lighting themselves. When they
  finish it fades (1.2 s) from whatever they left to the zone's look. Air particles hide meanwhile.
- **Particles:** `Where = "air"` layers live in a box that follows the player (the motes you always see). The rest sit
  on **anchors** found in the zone's own geometry - parts by name (`AmbiencePresets.FIND`), or on the islands by their
  folders (`Vegetation`, `Water`, `Foam_Mist`, `Scenery_Rocks`, `Landmarks`) - clustered into 36-stud cells. Only the
  nearest `Anchors` per kind within `Radius` of the camera emit. Streaming: the zone is re-scanned every 4 s while it
  has fewer than 6 anchors, then every 20 s; anchors keep their identity across scans (keyed by cell).
  `Ground` bands sit on each tree's own foot (its model's lowest point), not the zone floor.
- **Boss first:** particle rates x `BossDip` (0.3-0.35) while the zone's boss (`BossStates.<Model>` State) winds up or
  attacks. Boss warnings / shockwaves are never touched; particles use `LightEmission <= 0.3`, `ZOffset -0.5`.
- **Audio:** 3D loops from `Shared.Sfx` only (already-licensed ids: waves, gulls, fountain) on the nearest anchors of a
  kind; volume follows the zone fade. No new ids.
- **Quality:** `High` (desktop) / `Low` (touch-only devices, graphics level 1-4): rates x0.45 (and each layer's `Low`),
  3 anchors per kind, 110-stud radius, 0.75 air box, no glows, no extra sun rays. Rechecked every 5 s.
- **Test hooks** (player attributes, from a Client execute_luau): `AmbienceOff = true` (fade to the place's own look,
  no particles: the "before" shots), `AmbienceQuality = "High" | "Low"`, `AmbienceZone = "<Id>"` (force one). It sets
  `AmbienceZoneNow`.

## Tuning a zone
In a playtest, write `Lighting` / `Atmosphere` / `Lighting.AmbienceGrade` directly from a Client execute_luau (the
controller isn't fading, so it won't overwrite you), screenshot, then copy the numbers into the zone's preset.
Hide the PlayerGui ScreenGuis for clean shots; set `settings().Rendering.QualityLevel` high (particles). A boss
windup is ~1.5 s, shorter than the capture lag: clone the `BossVisuals` warning parts at windup (Archivable on) into a
temporary model and photograph that (delete it after).
**Lesson (Pet Park):** a coloured ambient shifts gameplay colours (a green OutdoorAmbient turned the orange path
yellow); keep Ambient / OutdoorAmbient near the place's own and put the zone's colour in the Atmosphere haze, Decay and
the particles.

## The place's own lighting (captured 2026-10-20)
ClockTime 14.5, Brightness 2.25, Ambient 95,95,104, OutdoorAmbient 125,125,135, ColorShift_Top 255,226,190,
Exposure -0.25, EnvDiffuse 0.42, EnvSpecular 0.55; Atmosphere D 0.20 O 0.12 Color 199,225,255 Decay 150,190,240
Glare 0.27 Haze 0; Bloom 0.30 / 30 / 1.6; SunRays 0.03 / 0.55; ColorCorrection C 0.12 S 0.05; DepthOfField off;
Sky "__WORLDFX". Streaming on.

## Per-world settings
| Zone | Status | Haze (Atmosphere) | Lighting / grade | Particles | Audio |
| --- | --- | --- | --- | --- | --- |
| Pet Park | **prototype, waiting for crnuch** | D 0.38 O 0.18, Color 196,226,156, Decay 104,150,84, Glare 0.15, Haze 1.2 | Ambient 98,104,98, Outdoor 126,134,122, ColorShift 255,232,196; grade C 0.03 S 0.03 tint 252,255,248; Bloom 0.45/28/1.75; rays 0.05 | air: pollen (16/s), leaves (3.5/s); trees: falling leaves, petals (blossom / flowers), fireflies on the tree's ground; water: mist + glints | fountain loop by the nearest pond (islands) |
| Briefcase Bay | draft | warm gold | | dust, paper scraps, gold glints | |
| Brainrot Boulevard | draft | purple / cyan | | neon motes, glitch squares | |
| Food Court | draft | golden orange | | warm dust, crumbs, sparkles | |
| Ocean Shore | draft | turquoise | | salt mist, spray on water | waves, gulls |
| Space Base | draft | violet | | cosmic dust, star motes, energy motes | |

Particle budget measured on Pet Park (island): High 34 emitters ~59 particles/s; Low 14 emitters ~7.5 particles/s.

## Assets
Textures (white + alpha, tinted in game): `amb_leaf` 76178310925290, `amb_petal` 105223361263918, `amb_paper`
94602324300971, `amb_mist` 127394798188063, `amb_square` 81592498778194, `amb_bubble` 126450061639497 (crnuch's
account). Reused from `Effects.TEXTURES`: dot, glow, twinkle, star, wisp, speck. Sounds: `Shared.Sfx` only.
