# Proposal: a more dynamic Supreme screen crack + mutated eggs beyond Golden (2026-10-13)

A suggestion from crnuch's cloud session, **nothing built**. A local session picks it up (claim it in SESSION_LOG →
In progress first). Read against what's live: `studio/StarterPlayer/StarterPlayerScripts/Eggs.client.lua`
(`screenCrack`, the Supreme "Ascension" cinematic) and `studio/ServerScriptService/Server/ZoneService.lua` +
`Shared.EggLook` (golden eggs).

## 1. The Supreme screen crack, more dynamic

**Today** (`Eggs.client:screenCrack`, ~line 1477): 11 white jagged lines appear all at once from the middle of the
screen, hold 0.7 s, fade. It reads as a flat overlay: no build, no impact, no glass.

**Suggested beat** (same slot in the Ascension cinematic, ~1.2 s instead of ~1 s):
1. **Hairline (0.0 s):** after the 3rd tap, time stops as today - then one tiny crack *ticks* in from the egg's
   on-screen position (`Camera:WorldToViewportPoint` of the egg, not the screen centre) with a small glass "tink".
   A held breath: the player wonders if something's wrong.
2. **Spread (0.15-0.45 s):** the crack *grows* - each segment animates its length from 0 (tween `Size.X`, anchored at
   its start), so the lines race outward, **branching** (at a random segment a thinner side crack splits off, 2
   levels deep). Small camera shake per branch. Sound: a rising crackle.
3. **Light leaks (0.3-0.8 s):** under every crack line, a wider, softer copy in the Supreme rainbow (a `UIGradient`
   whose `Offset` scrolls, so colour runs *along* the cracks) - light from the Supreme scene bleeding through.
   Optional "glitch": two faint copies of the lines offset 2-3 px in red and blue for a frame or two on each branch.
4. **Shatter (0.85 s):** a deep boom, the cracks flash white, and the screen *breaks*: 20-30 glass chips (small
   rotated white frames with a faint rainbow edge) burst from the crack lines, spin and fall with gravity off the
   screen, while a white-gold flash expands from the impact point straight into the Ascension stage.
5. **Every Supreme is a little different:** random origin offset, branch angles and chip spin per hatch.

**Rules:** no strobing (at most ~3 flashes a second; a young audience and photosensitive players), line thickness
scales with `ViewportSize` so phones read it, cap ~150 frames and reuse them, **no text** added (the existing
"SUPREME!" slam stays the only word). New sound cues through `ReplicatedStorage.HatchCue` (`"crack", stage`).
Mythic could get a smaller version of the same tech (crimson cracks along the floor fissures, no shatter) so the two
top tiers feel related but Supreme stays the biggest.

## 2. Mutated eggs beyond Golden

**Today:** a zone egg is sometimes **Golden** (`Config.Zones.Golden`: 6% of spawns, 5x price, Luck 4 = Rare / Epic /
Legendary chances x4, gold + crown + jewels, lasts 60 s). Golden is a yes/no flag everywhere: `Zones.Carried[i].Golden`,
the `*` in the `Carried` attribute, `EggLook.build(egg, golden, height)`, `EggServer` roll option `golden`.

**A problem found while sizing this:** luck works by moving chance from Common / Uncommon into Rare / Epic /
Legendary (that's what keeps Supreme exactly 1 in 2500, `Formulas.luckyWeights`). So luck has a **ceiling** per egg:
once Common and Uncommon are used up, more luck does nothing.

| Egg | Luck ceiling | Golden's x4 today |
|---|---|---|
| Briefcase | x5.5 | works |
| Pet | x4.7 | works |
| Food | x3.6 | capped at x3.6 |
| Ocean | x2.9 | capped at x2.9 |
| Brainrot | x2.2 | capped at x2.2 |
| Space | x2.2 | capped at x2.2 |

So "Diamond = luck x8" would roll *exactly* like Golden on most eggs. Mutations above Golden need a different lever.
**Suggestion: each higher mutation sets a rarity *floor*** (nothing below that rarity hatches; the chance is shared
out over what's left, Mythic and Supreme unchanged). It's simple to show exactly on the odds board, and each tier is
clearly better than the last.

### The ladder (first guesses - sim them)
| Mutation | Spawns | Price | Odds | Look (brick style, EggLook) | Effects ladder |
|---|---|---|---|---|---|
| **Golden** (today) | 6% | x5 | luck x4 (up to the ceiling) | gold, crown, jewels | gold glints |
| **Diamond** | 1.5% | x12 | **Rare or better**, e.g. Briefcase 61 / 25 / 14% Rare / Epic / Legendary | pale-cyan crystal facets, frosted tips | ICE (Rare's ladder) |
| **Rainbow** | 0.4% | x30 | **Epic or better**, e.g. Briefcase 64% Epic / 36% Legendary | hue-cycling bands, a rainbow trail when carried | ENERGY + rainbow |
| **Cosmic** | 0.1% | x80 | **Legendary or better**, and Mythic x2 (Supreme stays 1 in 2500) | dark purple with star specks, a tiny orbiting planet ring, a soft glow | Supreme-style stars |

Per-egg floor odds (Rare / Epic / Legendary %): Pet 57/29/14 · Brainrot 62/20/18 · Food 57/25/18 · Ocean 56/20/23 ·
Space 52/20/27 for Diamond; Rainbow (Epic / Legendary): Pet 67/33 · Brainrot 53/47 · Food 58/42 · Ocean 46/53 ·
Space 42/57.

- Spawn chances are rolled per egg spawn, rarest first. Rainbow and Cosmic get the server alert like Golden;
  Cosmic also gets a sky effect over the zone for its lifetime so everyone runs for it. Lifetime: Golden 60 s,
  Diamond 60 s, Rainbow 45 s, Cosmic 30 s (a scramble).
- They're boss bait: a mutated egg dropped by a boss hit is free game (docs/BOSSES.md), which makes carrying a Cosmic
  egg home the most exciting walk in the game.
- Pity counts them like any egg. They never touch the Supreme chance.
- **Economy:** a Cosmic egg is close to a guaranteed Legendary, so its price and spawn rate set how fast players get
  Legendaries. Put the ladder in `tools/economy_sim.py` (as zone egg variants) before tuning; the numbers above are
  only starting points.

### What has to change (for the local session)
- `Config.Zones.Golden` → `Config.Zones.Mutations = { { Id = "Golden", Chance, PriceMultiplier, Luck, Lifetime },
  { Id = "Diamond", ..., Floor = "Rare" }, ... }` (ids are saved: never rename one).
- Save: `Zones.Carried[i] = { Egg, Golden }` → `{ Egg, Mutation }`. Bump `SCHEMA_VERSION` with a `MIGRATIONS` entry
  that turns `Golden = true` into `Mutation = "Golden"`.
- The `Carried` attribute: `Pet*` → `Pet@Golden` (update `StarterPlayerScripts.Zones` and `CarryPose`'s parser).
- `Formulas`: a pure `mutationWeights(eggWeights, mutation, passLuck)` (luck, then the floor, Mythic boost, Supreme
  fixed) used by the server roll AND the odds board, plus a Config check in `tools/checks/config_tests.luau`: every
  egg x every mutation sums to 100 and keeps Supreme at 1 in 2500.
- `EggServer` roll option `golden` → `mutation`; `EggLook.build(egg, mutation, height)`; the incubator and the hatch
  screen tint the egg by mutation.
- Odds board / egg label: show each mutation's exact odds (CLAUDE.md: anything paid that's random shows exact odds).

### Bigger idea for later (not part of this)
Let the mutation carry onto the lawyer (a Diamond Corgi Cooper with an ice shimmer and a small earn bonus), like
golden / rainbow pets in pet games. That's a new saved field on every lawyer and a look for every lawyer, so it
deserves its own decision.
