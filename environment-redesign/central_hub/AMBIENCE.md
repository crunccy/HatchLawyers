# Central hub — Stage 4: ambience (2026-10-18)

The hub should feel welcoming, peaceful and alive without distracting from play. Everything here is a **Blender
demonstration** (`hub_ambience.py`) plus a design for Roblox. Nothing is implemented in the game.
Audio: [AUDIO.md](AUDIO.md).

```bash
Blender -b --python environment-redesign/central_hub/hub_build.py -- norender   # the hub
Blender -b --python environment-redesign/central_hub/hub_ambience.py -- clips   # + ambience, MP4 previews
Blender -b --python environment-redesign/central_hub/hub_ambience.py -- stills  # or a few review frames
```
`hub_ambience.py` saves the animated `central_hub.blend` (timeline 1–96+), so the effects can be scrubbed there.

## Preview clips (`renders/ambience/`, 960×540, 24 fps, EEVEE at 8 samples)
| Clip | Length | Shows |
| --- | --- | --- |
| `hub_ambience_plaza.mp4` | 4 s | Dolly from spawn to the fountain: rippling water curtain + jets, pollen, butterflies, swaying groves, breathing portal / egg halos |
| `hub_ambience_aerial.mp4` | 4 s | Slow orbit: waterfalls flowing, clouds + islets drifting, the island's canopy moving in the wind |
| `hub_ambience_portal.mp4` | 3 s | The Travel Portal: the light swirl turning, the field and runes breathing, crystals glowing |
| `hub_ambience_bigcase.mp4` | 2 s | Cases riding the Big Case belt (a seamless loop) |
| `hub_ambience_waterfall.mp4` | 3 s | A waterfall from outside: white water streaming down the curtain into the mist |

The previews are kept short and low-sample because each frame costs about 0.6 s per sample here (681k studs).
`stills` renders review frames.

## What moves, how Blender does it, how Roblox would
| Effect | Blender (this demo) | Roblox equivalent | Blender-only? |
| --- | --- | --- | --- |
| Trees sway (canopies + their studs; trunks stay put) | Geometry Nodes `WindSway`: Set Position, offset = sin / cos of (time + position) × height above 4.5 studs, plus a slow gust | Client script (like `WorldLife`): tagged canopy parts get a small CFrame sway each frame within ~150 studs of the camera (EffectsLod-style culling); or skinned MeshPart trees with a looping Animation | No |
| Fountain water + ponds ripple | Animated shader: 4D noise in time → lighter streaks | `Texture` on the water parts with OffsetStudsU/V tweened; Neon / Glass transparency shimmer | Partly (ripple via noise) |
| Fountain jets | (static arcs, rippling material) | Beams with a scrolling water texture (`TextureSpeed`) along each arc + a splash ParticleEmitter at the basin | No |
| Waterfalls flow | Animated shader: bright bands scrolling down (wave texture, time-offset) | Beam / Texture with downward-scrolling texture on the curtain parts; ParticleEmitters for spray at the lip and mist at the bottom (`Effects.ambient`) | No |
| Glows breathe (portal field + runes, crystals, egg halos, lab core) | Emission-strength drivers (sine of time) | TweenService on Neon parts' `Transparency` / `Color`, PointLight `Brightness` | No |
| Portal light swirl spins | Object rotation about the ring's axis (cycling) | Client: CFrame rotation of the swirl model about the ring axis + a ParticleEmitter swirl (Effects) | No |
| Big Case cases ride the belt | Cycling slide (8 studs per 2 s, seamless) | Client CFrame loop of the case models (BigCase.client already moves clients) | No |
| Butterflies | Keyframed meandering paths + cycling wing flaps (hinged wings) | Small models moved by a client script along random waypoints (like `WorldLife`'s gulls), wings flapped by CFrame | No |
| Floating pollen | Particle system: no gravity, brownian drift, warm emissive motes, pre-baked | ParticleEmitter (`Effects.ambient`): tiny warm squares, low Rate, Drag, slow Speed, LightEmission ≤ 0.3 | No |
| Clouds + islets drift | Object animation | Client: slow CFrame drift of the cloud models, wrapping round | No |
| Soft sunlight, bloom | EEVEE sun + gradient sky + compositor glare | `Lighting` (ClockTime ~14, Brightness), `Atmosphere`, `BloomEffect` (low intensity), `ColorCorrectionEffect` | Bloom look differs |
| Ray-traced AO / soft shadows | EEVEE ray tracing | Roblox Future / ShadowMap lighting (no AO control) | Yes |

## Rules for moving parts (learned 2026-10-18: crnuch caught cases riding through the arch)
- **Clearance:** every moving thing's whole path is checked against the static scene before it's presented. The
  Big Case arch now straddles the belt (posts beside it, crossbeams over it, flags on the back posts). Butterflies
  fly in rings kept outside platforms / walls and above platform height.
- **Seamless loops hide their seams:** a looping ride starts and ends inside something (the belt's IN / OUT tunnel
  hoods with flaps), so nothing pops in or rolls off an end.
- **Check frames, not just the idea:** render the start, middle and end frames of each clip (`-- stills`) and look
  for clipping before the MP4.

## Hub ambience spec (for the game)
- **Mood:** welcoming, sunny early afternoon, gentle breeze, birds, distant voices, a relaxed ukulele track.
- **Motion budget:** everything subtle and slow. No flashing; glows breathe at 0.3–0.5 Hz; sway ≤ 0.4 studs at the
  canopy top.
- **Distance culling:** motion and particles run only within ~150 studs of the camera (EffectsLod's pattern); phones
  get half the radius and no butterflies.
- **Particles:** pollen over the plaza (Rate 4–6), fountain splash, waterfall lip spray + mist, portal motes.
- **Sound:** a 2D park bed + 3D landmark loops. Tiers, picks and volumes are in AUDIO.md.

---

# The future WorldAmbience system (design only; Stage 7 plans the integration)

**Goal:** each world (the hub + every egg island) has its own ambience, and travelling between them cross-fades it.
Adding an island must only mean adding data and tags.

## Data: `Config.WorldAmbience[worldId]`
| Field | Holds |
| --- | --- |
| `Lighting` | ClockTime, Brightness, Ambient, OutdoorAmbient, ExposureCompensation, FogColor / FogEnd, ShadowSoftness |
| `Atmosphere` | Density, Offset, Color, Decay, Glare, Haze |
| `Sky` | the Skybox asset ids (or the current sky), StarCount, CelestialBodiesShown |
| `PostFx` | Bloom (Intensity, Size, Threshold), ColorCorrection (Brightness, Contrast, Saturation, TintColor) |
| `Sound` | `Bed` (Sfx name or id + volume), `Music` (ids + volume), `Layers` ([name, volume, region?]), `Oneshots` ([name, minGap, maxGap, volume]) |
| `Particles` | camera-attached emitters (e.g. Space Base dust, Food Court steam) |
| `Weather` | optional: rain / snow / leaves |

## Which world am I in?
- `Workspace.Worlds.<Id>` each holds a `Bounds` part (an invisible box round the island). The client checks the
  camera / character position against the bounds every 0.5 s.
- TravelServer also sets a `World` attribute on the player when a trip lands. That's authoritative, and the bounds
  are the fallback.

## Client: `StarterPlayerScripts.WorldAmbience` (+ `Shared.WorldAmbience` for the data helpers)
1. **On a world change:** fade the old bed + music + layers out (0.6 s Sound volume tweens; the SoundGroups keep
   the mix).
2. **During the trip** (`Shared.TravelFx` already plays a travel animation):
   - TravelFx fires `WorldAmbience:Prepare(dest)` before the camera cuts.
   - Lighting, Atmosphere, Sky and PostFx are tweened or swapped **under cover of the travel effect**.
3. **Fade the new ambience in** (0.8 s) and enable the new world's camera-attached particles and weather.
4. **Animated props** are driven by **tags**, one controller for every world:
   - `AmbSway` (trees, flags), `AmbSpin` (portal swirl, satellite dishes, planets), `AmbBob` (floating things)
   - `AmbPulse` (Neon breathing), `AmbScroll` (water / belts: Texture offsets), `AmbPath` (butterflies, fish,
     drones)
   - Attributes per instance: Axis, Rate, Amp, Phase (the same idea as `Shared.Puppet`'s Fx attributes).
   - Distance-culled and quality-scaled like EffectsLod; nothing replicates.
5. **Lighting is global on the client:**
   - Only one world's Lighting can apply at a time, so it's chosen by "which world the local player is in", never
     by part.
   - Islands are far apart, so a mismatch is never on screen.
   - Effects that must differ inside one view (a portal glowing into another world) use local Neon / Beams, not
     Lighting.
6. **Streaming:**
   - landmark sounds and particles live on parts inside each island model, so they stream with it
   - the controller listens for tagged parts being added or removed (CollectionService signals)
   - beds and music are 2D and owned by the controller

## Server
Nothing per frame. TravelServer sets `player:SetAttribute("World", id)` on arrival (one line).

## Testing
- Admin `/world <id>` previews a world's ambience at the hub.
- A `config_tests.luau` rule checks that every world in `Config.Zones.List` (+ "Hub") has an ambience entry with
  valid ids.
