# Boss attack animation overhaul (2026-10-19, crnuch's brief)

Visual overhaul of the six zone bosses' attacks: better character animation, effects and sound, **with no
gameplay change** (damage, hit shapes, targeting, attack frequency, walk speed, range, egg drops, ragdoll, post-hit
immunity, safe zones all stay exactly as `Server.BossService` + `Config.Bosses` have them) - **except the CROWD
add-ons in section 4**, crnuch's later call (more players on the island = the boss threatens all of them).
**Megalodon first, as the quality benchmark; the other five wait for crnuch's approval of it.**

## 1. Audit: how the bosses work today
- **Not humanoid rigs.** Each boss is a set of studded blocks built in Blender (`tools/blender/bosses.py` ->
  `tools/zones/bosses.json` -> `tools/zones/BuildBosses.lua` -> `ReplicatedStorage.Bosses.<Model>`), split into
  GROUPS (Models with a `Joint` CFrame and a `Parent` group). No Motor6Ds, no AnimationTracks.
- **The server moves nothing.** `Server.BossService` writes each boss's state to attributes on
  `ReplicatedStorage.BossStates.<Model>` (From / To / MoveStart / MoveEnd / Yaw / State / StateStart / StateEnd /
  AttackKind / Target). Every client clones the model and poses it each frame (`StarterPlayerScripts.Bosses`,
  one `BulkMoveTo`): `world = parent * joint * rot * joint:Inverse()` per group, where `rot` comes from a
  hand-written `POSES.<Model>(b, state, a, t, idle)` function of sines and two eases.
- **Effects today:** a floor warning per attack kind (Cone fan / Ring disc / Slam disc / Line strip with marching
  arrows / Pull swirl), a flat neon shockwave ring, a paper burst (Partner), sparkle bursts, 3 neon cubes as dizzy
  stars (Megalodon), a sparkle puff trail on Line attacks, a CameraOffset shake. Sounds: the Big Case alert as the
  windup, the gavel knock (slam AND bark), whooshBig (charge), all from the licensed `Shared.Sfx` set.
- **What is weak:** every pose is one sine-driven lean; no anticipation beat, no squash / stretch, no secondary
  motion (robes, lures, papers are rigid or spin on a timer), attacks start and stop on a linear tween, the
  recovery is a plain ease back to idle. Several requested beats are impossible on the current models (the
  Megalodon's mouth, eyes, fin and glasses were all one rigid Torso block).

### Megalodon's real timeline (BossService "Line" + Config.Bosses.List[5])
| Phase | Server | Duration |
| --- | --- | --- |
| trigger | nearest non-ignored player within `TriggerRange` 60, `AttackEvery` 2.8 s after the last recover | - |
| windup | `Yaw` snaps toward the target, boss stands; Target = end of the lane, 130 studs on (clamped to its area) | **1.0 s** |
| charge ("attack") | From -> To linear at 150 studs/s; every 0.05 s anyone within 10 studs (Width 20 / 2) of its centre is hit | **max(0.25, dist / 150)** = up to 0.867 s |
| dizzy | stands at the goal (its body hitbox still hits) | **2.0 s** |
| recover | stands | **0.6 s** |
Touch hitbox: HalfWidth 2.2, Back 2.4, Front 1.8, Height 8 model units x Scale 3.2 (+1.5 studs).
**Targeting note:** the brief says it turns to "the player carrying eggs"; the server targets the NEAREST player
(carrying or not). Changing that is a targeting change, so the animation turns to whoever the server picked. If
crnuch wants egg-carriers first, that's a one-line server change to decide separately.

## 2. How the new animation works (all bosses, built on Megalodon)
- **Authored in Blender, played by the client.** `tools/blender/boss_anims.py` rebuilds the boss from
  `bosses.json` as empties at each group's joint, keys every clip at 30 fps (pose keys with per-key easing:
  back-out snaps, expo launches, elastic settles, plus baked trembles and cycles), renders a storyboard + an
  MP4 preview at the server's exact timing, and exports the clips to `tools/zones/boss_anims.json` and
  `src/BossAnims.lua` (`ReplicatedStorage.Shared.BossAnims`, a plain ModuleScript - no assets to upload).
- **Channels per clip:** each group's rotation (quaternion, Roblox axes), the root offset (model units, x Scale),
  the root tilt, the root SQUASH / STRETCH (sx, sy, sz around the feet), and fx channels (`FinGlow` 0..1).
- **The client** (`Bosses.client`): walk / idle stay procedural; windup / attack / dizzy / recover play clips,
  cross-faded in and out over 0.1 s. Squash scales part positions + sizes around the feet (only while it isn't
  1, about 50 parts). The root never leaves the server's path: the charge's "explosion", the skid and the
  dizzy stumble live in the pose (lean, stretch, overshoot of at most 0.35 model units), so what you see is
  where the hitbox is.
- **Charge clips are split so any charge length works:** `charge_launch` (first 0.2 s), `charge_loop` (a
  0.233 s two-stride cycle), `charge_brake` (last 0.2 s). Short charges (0.25 s at a wall) blend launch into brake.

## 3. Megalodon storyboard: FIN CHARGE (1.0 + up to 0.867 + 2.0 + 0.6 s)
Times are from the start of each server state. The floor warning strip is untouched and appears at 0.0 as today;
nothing below rises over it (windup dust is behind him, low and short; the glow is on the fin, above head height).

**A. ANTICIPATION (windup, 1.0 s)**
| t (s) | Beat |
| --- | --- |
| 0.00-0.08 | DETECT: snout jerks up (head hinge +0.12), a sniff - the body is still facing the old way |
| 0.04-0.24 | THE TURN: body whips round to the target with a back-out overshoot (~8 deg past, settles) and a little hop (root +0.35, lands with a squash 0.9) - the head leads the body |
| 0.20-0.50 | COIL: sinks into a crouch (root -0.45, squash sz 0.86 / sx 1.08), torso pitches forward, fins sweep back and out, tail cocks up, cape lifts |
| 0.25-0.95 | FIN GLOW: the dorsal fin's shell lights electric blue (0 -> 1, with a flicker), sparks crackle off it from 0.6 |
| 0.30-0.75 | FEET DIG: two bull-style paw scrapes with the right foot (back - plant - back - plant), a sand kick BEHIND him each time |
| 0.45-0.85 | GRIN + HOLD: jaw parts into a toothy grin (head hinge +0.18), a growing tremble (2 -> 6 Hz amplitude ramp) |
| 0.85-1.00 | FINAL SINK: one more drop (-0.1) and the stretch is loaded: a frame of extra squash just before go |

**B. ATTACK (charge, linear 150 studs/s on the server path)**
| Part | Beat |
| --- | --- |
| launch 0-0.2 s | EXPLODES: squash flips to stretch along the run (sy 1.28 / sz 0.9) in 2 frames, torso near flat forward, jaw WIDE (hinge +0.5), fins flung back, tail whips; a launch ring + dust burst at the start spot, a screen shake for players near |
| loop | full sprint: two-stride cycle (legs pumping, body bob), cape and lure streaming back, jaw chomping open-shut, fin glowing; speed streaks + sand spray from the feet + water-like splash arcs off the dorsal fin's wake |
| brake last 0.2 s | leans BACK hard, feet thrust forward plowing, stretch flips to squash (forward compress), a sand plume thrown forward |

**C. IMPACT (along the charge and at the stop)**
- start: launch ring (fx_ring, electric blue) + a dust burst, `whooshBig` + `splash`.
- along: sand spray (fx_dot / fx_glow tinted sand, low, behind the feet), speed streaks (vfx_beam_streak, white,
  short), splash droplets (fx_dot, ice blue), 12-14 particles per 0.07 s at most.
- stop: skid plume forward + a small shake within 30 studs, `splash` low + `bonk`.

**D. RECOVERY (dizzy 2.0 s, then recover 0.6 s)**
| t (s) | Beat |
| --- | --- |
| dizzy 0.00-0.40 | SKID SETTLE: overshoots forward (lean -0.35, root +0.35 forward), rocks back, squash 0.82 -> 1.06 -> 1; glasses jump up and land crooked (15 deg); fin glow drains |
| dizzy 0.30-2.00 | DIZZY: body circles (torso sways on a 0.75 Hz figure), head lolls the other way, eyes SPIN in opposite directions, fins dangle and flop, jaw hangs open, a stumble step at 1.1 s; the existing 3 stars orbit (now spinning gold stars) |
| recover 0.00-0.30 | WET-DOG SHAKE: a fast head + torso shake (8 Hz, decaying), cape and lure flick |
| recover 0.25-0.50 | pushes the glasses straight with the left fin, a jaw snap shut |
| recover 0.45-0.60 | chest puff + gavel tap, back to the stalk pose |

## 4. CROWD ATTACKS: more players on the island = more danger (crnuch's call 2026-10-19)
> "if it's just one person it's dangerous but still manageable ... if there's three people on the island it can
> target all three at once somehow with like a range attack ... incorporate this for all the bosses."

This one IS a gameplay change (crnuch's call, overriding the brief's "no gameplay change" for this part only).
- **One player in the zone: nothing changes.** Same attack, same timing, same numbers as today.
- **2+ players:** as the boss winds up its normal attack on its target (unchanged), it also aims a RANGED add-on at up
  to `Crowd.Max` (2) OTHER players in its zone within `Crowd.Range` studs (nearest first; skipping anyone it's ignoring
  or who is safe after a hit). So three players = all three under threat at once.
- **Fairness floor, same as every attack:** each add-on has its own floor warning in the boss's colour from the first
  frame of the SAME windup (never shorter than 1 s), is narrower / smaller than the main attack, and lands at the
  same moment as (or after) the main one. It aims where the player stood when the windup began, so moving dodges it.
  A hit is a normal hit (eggs out, ragdoll, `SafeAfterHit`, `IgnoreAfterHit`) - one hit per player per attack.
- **Server:** generic in `BossService` - `Config.Bosses.List[n].Crowd = { Shape = "Lane" | "Disc", Max, Range, Width
  / Radius, Speed }`; picked at the start of the windup and published as state attributes `CrowdN` + `Crowd1..3`
  (lane ends / disc centres) so every client draws the warnings; the hits are decided on the server like the rest.

| Boss | Crowd add-on (2+ players) | Shape |
| --- | --- | --- |
| **Magistrate Megalodon** | **FEEDING FRENZY** - as he coils, sand-shark fins burst out of the sand at his feet and race down a lane at each other player while he charges his own target | Lane, 12 wide, at 120 studs/s, up to 110 long |
| The Senior Partner | PAPER STORM - the briefcase bursts open at the top of the swing and lobs a bundle of case files at each other player | Disc r 10 at their spot, lands with the swing |
| Barrister Bulldog | ECHO BARK - the bark's sound wave travels to each other player and goes off round them | Disc r 12, lands with the bark |
| Judge Martello | GAVEL RAIN - as he lands, a mini gavel drops on each other player's spot | Disc r 12, lands with the slam |
| Prosecutor Big Cheese | WHEEL SPLIT - two cheese wedges peel off the wheel and roll down lanes at the others | Lane, 12 wide, at 110 studs/s |
| Chief Justice Eclipse | GAVEL VOLLEY (Ring turns) - each orbiting gavel locks onto a different player and slams down; the Pull already catches everyone within 44 | Disc r 10 under each, lands with the ring |

Megalodon's Feeding Frenzy is built with this benchmark (preview + `src/`); the other five are proposals that get built
with their animation passes once crnuch approves.

## 5. Megalodon benchmark: what was built (2026-10-19)
- **Model v2** (`tools/blender/bosses.py`, 41 -> 47 blocks, 6 -> 13 groups): the jaw hinge (Head over Torso, a
  gullet + palate inside), Fin + FinGlow shell (tag `glow`: Neon, hidden until lit), EyeL / EyeR, Glasses, Lure, Cape.
  The robe stops at the mouth line and the cape is 3.4 wide so nothing clips. The other five export unchanged.
  **Round 2 (crnuch):** the mouth is a real cavity (x +-1.2, 0.5 deep; gums, throat) with 3D teeth (diamond prisms
  half sunk in the gums, 5 top / 4 bottom, interleaved), and a `Cheek` group (a skin flap each side on the jaw hinge,
  keyed to HALF the head's angle by `cheek()` in boss_anims.py) keeps the head joined to the body when it opens
  (covers the side gap up to a 0.5 rad jaw; hidden inside when shut). 58 blocks / 14 groups.
- **Clips** (`tools/blender/boss_anims.py`): windup 31 frames, charge_launch 7, charge_loop 8 (loops), charge_brake 7,
  dizzy 61, recover 19, at 30 fps -> `tools/zones/boss_anims.json` + `src/BossAnims.lua` (39 KB).
- **Review page for approval:** https://claude.ai/artifact/1V8cbTiD2YNckxRuVkfGQp (crnuch's private artifact; source
  `art/bosses/megalodon/review.html`).
- **Preview** (`art/bosses/megalodon/`): `megalodon_fin_charge.mp4` (cinematic: start / tracking run / stop cameras),
  `megalodon_fin_charge_halfspeed.mp4`, `megalodon_gameplay_view.mp4` (the whole lane from a player's height: three
  players - the target steps out of the charge strip, orange steps out of its frenzy lane, red stays and is caught),
  `board_*.png` (the storyboard frames), `megalodon_charge.blend` (scrubbable, every channel baked).
- **Timing verified:** the preview runs on the server's own timeline (walk 0.5, windup 1.0, charge 130 studs at 150 =
  0.867 s, dizzy 2.0, recover 0.6) and the clips are exported from the same functions; `tools/checks/config_tests.luau`
  now fails if a clip's length drifts from `Config.Bosses` (windup / dizzy) or BossService (recover 0.6), or a crowd
  lane gets too wide to dodge. The client samples clips by time since `StateStart`, the same clock the server uses.
- **Clipping checked** (`boss_anims.py -- check`: every block of every group against every other group's blocks,
  every frame, minus the rest pose's own overlaps and the hinge corners): worst left 0.33 studs (a cape corner
  grazing a fin for one frame of the launch) on a 26-stud boss. It found and fixed: the tail swinging 1.6 studs into
  the body, the dorsal fin tipping into the head, swept fins cutting the cape, the glasses fin grazing the snout.
- **Client** (`src/Bosses.client.lua`): a generic clip player for any boss in `Shared.BossAnims` (cross-fades, squash
  in its own axes round the feet, fx channels), the whip-round turn (code: 0.04 s hold, back-out over 0.2 s, the head
  leads), the frenzy lanes in the warning, sand sharks, and the effects (section 3 C). Other bosses are untouched.
- **Server** (`src/BossService.lua` + `src/Config.lua`): the generic Crowd add-on, Lane shape (Megalodon only).
- **Not in Studio yet** - waiting for crnuch's approval of the preview. To install: run `tools/zones/BuildBosses.lua`
  (the v2 model), add `src/BossAnims.lua` as `ReplicatedStorage.Shared.BossAnims`, 3-way merge `src/Bosses.client.lua`,
  `src/BossService.lua`, `src/Config.lua`, then playtest with 1 and 3 players (`QualityLevel` high for particles).
- Rerun: `Blender -b --factory-startup -P tools/blender/boss_anims.py -- check stills frames` (frames go to
  `$BOSS_FRAMES` or `_boss_frames/`), then `tools/blender/encode_preview.py -- <frames>/cine <out.mp4> [speed] [title]`.

## 6. Status
| Boss | Storyboard | Blender clips | Preview | Client | In Studio |
| --- | --- | --- | --- | --- | --- |
| Magistrate Megalodon | done | done | done | done (`src/`) | waits for approval |
| The Senior Partner | - | - | - | - | - |
| Barrister Bulldog | - | - | - | - | - |
| Judge Martello | - | - | - | - | - |
| Prosecutor Big Cheese | - | - | - | - | - |
| Chief Justice Eclipse | - | - | - | - | - |
