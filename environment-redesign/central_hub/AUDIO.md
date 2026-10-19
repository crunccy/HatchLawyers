# Central hub — ambient audio research (Stage 4, 2026-10-18)

Research only: **nothing downloaded and nothing put into Roblox.** Downloading needs crnuch's OK file by file.
**I can't listen to audio.** Every pick below is chosen from its page's description, length, format and licence;
crnuch should preview each one before it's approved.

## House rule first
`ReplicatedStorage.Shared.Sfx` says every sound in the game is licensed for any Roblox experience: Roblox's own pack,
**Pro Sound Effects** and **APM Music** (Roblox's audio partners), "never random uploads". The game already has licensed
hub loops: `waves` (9126201551), `gulls` (9112870701), `fountain` (9119293570).

So the plan has two tiers:
1. **Tier 1 (recommended): Roblox Creator Store partner audio.** Over 100,000 free sound effects and music tracks
   from Roblox and its partners, free to use in experiences, no upload, no rights questions. The search terms per
   sound are listed below. Check each listing's terms (the docs don't spell them out).
2. **Tier 2 (fallback): external sounds with verified licences.** Only if Tier 1 has no good fit. They must be
   uploaded **by crnuch** (the place owner: the game only loads its owner's uploads, CLAUDE.md), and using them relaxes
   the Sfx "never random uploads" rule. **That's crnuch's call.**

## Licences checked (2026-10-18)
| Source | Terms (as read on the page) | OK for the game? |
| --- | --- | --- |
| [Pixabay Content License](https://pixabay.com/service/license-summary/) | Free to use, no attribution, may modify; **no** selling / redistributing a file as-is on its own; watch for trademarks, recognisable people, third-party rights | Yes (inside the game is not standalone redistribution) |
| [Freesound](https://freesound.org) | Per sound: **CC0** (no attribution) or **CC-BY 4.0** (credit the author); avoid **NC** | CC0 yes; CC-BY yes with a credit line |
| [Kenney](https://kenney.nl/assets/sci-fi-sounds) audio packs | CC0 | Yes |
| Sonniss GameAudioGDC bundles | Royalty-free, commercial, no attribution, unlimited projects; **no AI training** (from press coverage, e.g. [GameFromScratch](https://gamefromscratch.com/sonniss-27-5gb-sound-effect-giveaway-at-gdc-2024/), [Rekkerd 2026](https://rekkerd.org/sonniss-releases-gdc-2026-game-audio-bundle/); the licence text itself not read: check sonniss.com) | Likely yes; verify |
| itch.io packs | Licence varies per pack | Case by case (none picked) |
| [Roblox audio assets](https://create.roblox.com/docs/audio/assets) | Uploads: .mp3 / .ogg / .wav / .flac, < 20 MB, < 7 min, ≤ 48 kHz; 2,000 imports / 30 days (ID-verified) or 100 (unverified); the uploader must hold the rights; uploads start private (grant per experience) | The rules every Tier 2 file must meet |

## The hub's soundscape
Mix through SoundGroups (Ambience / Music / SFX, as `Sfx` already does). Starting volumes are given per layer.
Landmarks are 3D sounds on their parts (`Sfx.loop`): RollOffMode InverseTapered, heard within ~60–90 studs.

### 1. Primary ambient bed (2D, quiet, everywhere in the hub)
| Tier | Pick | Licence | Length / format | Notes |
| --- | --- | --- | --- | --- |
| 1 | Creator Store search: "park ambience", "birds day", "city park" (Pro Sound Effects) | Roblox partner | — | first choice |
| 2 | [Bird Park Ambience](https://freesound.org/people/nick121087/sounds/234315/) by nick121087 | **CC0** | 1:06, WAV 48 kHz | spring park birdsong (Roland R-26); needs a ~2 s crossfade to loop |
| 2 alt | [Park ambience - mostly birds](https://freesound.org/people/Mafon2/sounds/274175/) by Mafon2 | **CC0** | 1:02, WAV 48 kHz | recorded on a camera: check its noise floor |

Volume ~0.22.

### 2. Environmental layers (2–4)
| Layer | Tier 2 pick | Licence | Length / format | Use |
| --- | --- | --- | --- | --- |
| Wind in the leaves | [Soft Wind in the Trees - Leaves rustle](https://freesound.org/people/Borgory/sounds/751473/) by Borgory | **CC0** | 2:26, WAV 48 kHz / 24-bit | 3D on the bigger groves, ~0.15; rises with the visual gust |
| Distant chatter | [Outdoor crowd noise](https://freesound.org/people/Awesoman/sounds/129344/) by Awesoman | **CC0** | 0:38, WAV 44.1 kHz | very low (~0.08) round the plaza + street; crossfade-loop |
| Extra birds (seamless) | [Forest birds - ambient seamless loop](https://freesound.org/people/Magnesus/sounds/723913/) by Magnesus | **CC0** | 0:27, WAV 48 kHz | author says seamless; gardens / lookouts, ~0.12 |
| Gulls (Arcade Pier, cliff edges) | already in the game: `Sfx` `gulls` | Pro Sound Effects | — | reuse |

Tier 1 search terms: "wind trees", "crowd distant", "birds loop".

### 3. Background music
**Recommendation:** Tier 1, a relaxed APM Music track from the Creator Store, the same family as the game's current
stings, so the licence matches. Search: "ukulele happy", "acoustic carefree", "kids playful". Volume ~0.3, ducked
under hatch reveals.

Tier 2 candidates. Pixabay Content License: the search listing was read, but each track's page wasn't, so verify
there:

| Track | Artist | Length |
| --- | --- | --- |
| [Upbeat Ukulele](https://pixabay.com/music/happy-childrens-tunes-upbeat-ukulele-617550/) | Caldena | 1:07 |
| [Happy Ukulele](https://pixabay.com/music/happy-childrens-tunes-happy-ukulele-617574/) | AtlasAudio | 1:04 |
| [Hawaii Ukulele](https://pixabay.com/music/upbeat-hawaii-ukulele-618222/) | The_Mountain | 1:18 |

### 4. Landmark sounds (3D)
| Landmark | Tier 1 | Tier 2 pick | Licence |
| --- | --- | --- | --- |
| Statue fountain | **already in the game: `Sfx` `fountain`** | [1 Hour of Peaceful Fountain Sounds](https://freesound.org/people/Tonnex/sounds/832609/) by Tonnex (62 min, m4a 22 kHz: cut a 60 s section) | **CC-BY 4.0** (credit "Tonnex") |
| Waterfalls ×4 | "waterfall loop" | [Ambiance_Waterfall_Loop_04](https://freesound.org/people/Nox_Sound/sounds/511075/) by Nox_Sound (0:26 loop, WAV 48 kHz / 24-bit) | **CC0** |
| Travel Portal | "magic hum", "portal loop" | [Hum Loop](https://pixabay.com/sound-effects/film-special-effects-hum-loop-64146/) (Smice_6 via freesound_community, 0:37) as the bed + one-shot whooshes from [Kenney Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds) (70 files) | Pixabay / CC0 |
| Egg Incubator | "bubbling", "warm machine hum" | [Gentle Water Bubbling](https://pixabay.com/sound-effects/film-special-effects-gentle-water-bubbling-584723/) by DRAGON-STUDIO (1:00) | Pixabay |
| Mutation Lab | "electric hum", "tesla" | [Tesla Coil](https://pixabay.com/sound-effects/film-special-effects-tesla-coil-193020/) by SoundReality (0:22): occasional zaps over the hum loop | Pixabay |
| Big Case belt | "conveyor loop" | [Conveyor Belt](https://pixabay.com/sound-effects/film-special-effects-conveyor-belt-584731/) by DRAGON-STUDIO (1:00) | Pixabay |
| Arcade Pier | **already in the game: `waves`, `gulls`** | booth bleeps: [Kenney Casino Audio](https://kenney.nl/assets/casino-audio) | CC0 |

Shop / Upgrades / License purchases already have the game's UI sounds (`Sfx`); nothing new is needed.

## If crnuch approves Tier 2 files
1. Download into `environment-redesign/audio/central_hub/` with `<source>__<author>__<title>.<ext>` names, plus a
   `LICENSES.md` row per file: URL, licence, author, credit text for CC-BY.
2. Trim / crossfade loops (Audacity), export OGG ≤ 48 kHz.
3. **crnuch uploads** them (Asset Manager) and adds the ids to `Shared.Sfx` with the source noted.
4. CC-BY credits (Tonnex) go in the game's credits / description.

## Sources consulted
- Licence and platform pages:
  [Pixabay licence summary](https://pixabay.com/service/license-summary/) ·
  [Roblox audio assets](https://create.roblox.com/docs/audio/assets) ·
  [Kenney Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds) ·
  [Kenney Casino Audio](https://kenney.nl/assets/casino-audio)
- Freesound sounds:
  [nick121087](https://freesound.org/people/nick121087/sounds/234315/) ·
  [Mafon2](https://freesound.org/people/Mafon2/sounds/274175/) ·
  [Borgory](https://freesound.org/people/Borgory/sounds/751473/) ·
  [Awesoman](https://freesound.org/people/Awesoman/sounds/129344/) ·
  [Magnesus](https://freesound.org/people/Magnesus/sounds/723913/) ·
  [Tonnex](https://freesound.org/people/Tonnex/sounds/832609/) ·
  [Nox_Sound](https://freesound.org/people/Nox_Sound/sounds/511075/)
- Pixabay sounds and searches:
  [Hum Loop](https://pixabay.com/sound-effects/film-special-effects-hum-loop-64146/) ·
  [conveyor search](https://pixabay.com/sound-effects/search/conveyor/) ·
  [bubbling search](https://pixabay.com/sound-effects/search/bubbling%20machine/) ·
  [tesla search](https://pixabay.com/sound-effects/search/tesla%20coil/) ·
  [ukulele music search](https://pixabay.com/music/search/ukulele%20background%20music/)
- Sonniss coverage:
  [GameFromScratch 2024](https://gamefromscratch.com/sonniss-27-5gb-sound-effect-giveaway-at-gdc-2024/) ·
  [Rekkerd 2026](https://rekkerd.org/sonniss-releases-gdc-2026-game-audio-bundle/)
