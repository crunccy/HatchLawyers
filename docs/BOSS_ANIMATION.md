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
  / Radius, Speed }`; picked at the start of the windup (every attack kind) and published as state attributes
  `CrowdShape`, `CrowdN` + `Crowd1..3` (lane ends / disc centres) so every client draws the warnings; released as the
  windup ends (`releaseCrowd`); the hits are decided on the server like the rest.

| Boss | Crowd add-on (2+ players) | Shape |
| --- | --- | --- |
| **Magistrate Megalodon** | **FEEDING FRENZY** - as he coils, sand-shark fins burst out of the sand at his feet and race down a lane at each other player while he charges his own target | Lane, 12 wide, at 120 studs/s, up to 110 long |
| **The Senior Partner** | **PAPER STORM** - the briefcase bursts open at the top of the swing and lobs a bundle of case files at each other player (**built**, section 6) | Disc r 10 at their spot, lands with the swing |
| Barrister Bulldog | ECHO BARK - the bark's sound wave travels to each other player and goes off round them | Disc r 12, lands with the bark |
| Judge Martello | GAVEL RAIN - as he lands, a mini gavel drops on each other player's spot | Disc r 12, lands with the slam |
| **Prosecutor Big Cheese** | **WHEEL SPLIT** - two cheese wedges pop off the wheel and tumble down lanes at the others (**built**, section 7) | Lane, 12 wide, at 110 studs/s |
| Chief Justice Eclipse | GAVEL VOLLEY (Ring turns) - each orbiting gavel locks onto a different player and slams down; the Pull already catches everyone within 44 | Disc r 10 under each, lands with the ring |

Megalodon's Feeding Frenzy and the Senior Partner's Paper Storm (section 6) are built and live; the
other four are proposals that get built with their animation passes.

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
- **Round 3 (crnuch):** the side fins now root INTO the shoulder (they tilted top-out and floated ~1 stud off).
- **LIVE in Studio since 2026-10-19** (crnuch approved; targeting stays nearest player). 1-player playtest clean;
  the 3-player Feeding Frenzy playtest is still to do. How it was installed: run `tools/zones/BuildBosses.lua`
  (the v2 model), add `src/BossAnims.lua` as `ReplicatedStorage.Shared.BossAnims`, 3-way merge `src/Bosses.client.lua`,
  `src/BossService.lua`, `src/Config.lua`, then playtest with 1 and 3 players (`QualityLevel` high for particles).
- Rerun: `Blender -b --factory-startup -P tools/blender/boss_anims.py -- check stills frames` (frames go to
  `$BOSS_FRAMES` or `_boss_frames/`), then `tools/blender/encode_preview.py -- <frames>/cine <out.mp4> [speed] [title]`.

## 6. The Senior Partner: BRIEFCASE SWING + PAPER STORM (2026-10-19; APPROVED + LIVE in Studio 2026-10-20)
### His real timeline (BossService "Cone" + Config.Bosses.List[1])
| Phase | Server | Duration |
| --- | --- | --- |
| trigger | nearest non-ignored player within `TriggerRange` 60, `AttackEvery` 3.5 s after the last recover | - |
| windup | `Yaw` snaps toward the target, he stands; the fan warning (Radius 45, Angle 110) grows over 0.4 s and pulses | **1.2 s** |
| attack | everyone inside the cone is hit at its **first frame** (right under him always counts), then he holds | **0.45 s** |
| recover | stands | **0.6 s** |
Body hitbox: HalfWidth 3.3, Back 1.4, Front 1.8, Height 11.5 model units x Scale 3.5 (+1.5 studs). Height 10.8 x 3.5 = 38
studs; the case overhead reaches ~40. **So the case must land at attack + 0.05 s**: the swing starts in the windup's
last 0.14 s. Before: the case went up in 0.8 s, a linear-ish slam 0.17 s AFTER the hit, a paper burst at +0.16 s.

### Model v2 (`tools/blender/bosses.py`, 68 -> 72 blocks, 7 -> 12 groups; same blocks, same places)
`Brows`, `Glasses`, `Moustache` (on the Head), `Case` (hangs from ArmR's hand on its handle: it trails, judders and
swings like a pendulum) and `CaseLid` (the case's outer half on a hinge along its bottom: it bursts open), with the
files inside (`Files` white + `Folder` manila, hidden until it opens). The other five bosses export byte-identical.

### Storyboard (times from the start of each server state; the floor warning is untouched)
**A. ANTICIPATION (windup, 1.2 s)**
| t (s) | Beat |
| --- | --- |
| 0.00-0.34 | NOTICE: chin up ("hm?"), brows up then down into a scowl; a deliberate turn (code: holds 0.06 s, turns over 0.28 s, his HEAD leads it); the left hand pushes the glasses up the nose (they hop 0.13 and tilt), a harrumph puff (squash 1.04), the moustache twitches |
| 0.30-0.46 | PLANTS HIS STANCE: left foot forward, right foot lifts and STOMPS back (squash 0.94, dust ring at the foot) |
| 0.40-0.84 | RAISE: the case dips back (anticipation), then swings up over his head with a back-out overshoot; he leans back and twists the right shoulder away (torso 0.17 / -0.3); the case TRAILS on its handle and catches up; stretched tall (1.07) |
| 0.68-1.06 | "OBJECTION!": the left arm points at his target |
| 0.72-1.02 | PAPERS SWIRL: the lid bursts open at the top, files spray out, sheets whirl round him and rise, the ankle papers spin 8x faster; the lid snaps shut for the swing. A gleam off the gold clasp at 0.88 |
| 0.86-1.06 | HOLD AT THE TOP: a growing tremble, the moustache bristles |
| 1.06-1.20 | THE SWING BEGINS: a last cock back, then the sweep accelerates (ease-in), the torso untwists |

**B. ATTACK (0.45 s)**
| t (s) | Beat |
| --- | --- |
| 0.00-0.05 | STRIKE: the sweep across and down; the case's corner hits the ground in front of him at 0.05 (bent over 0.37, twisted 0.24 across), IMPACT SQUASH 0.84 |
| 0.05-0.30 | IMPACT: the case judders on its handle and the lid jolts open a crack; a ring in his colour + a white one, a dust ring, dirt clods, ~24 sheets of paperwork thrown forward through the cone, the sheets that were swirling are blown forward; the moustache flaps UP, the glasses jump down the nose and go crooked, the brows shoot up; squash bounces 0.84 -> 1.03 -> 1 |
| 0.30-0.45 | STUCK: a first tug that doesn't come free |

**D. RECOVERY (0.6 s)**
| t (s) | Beat |
| --- | --- |
| 0.00-0.16 | YANK: a heave back pops the case out of the ground (a puff + clods where it was), a half step back; the case swings on its handle like a pendulum (about the handle, so it never dips into the ground) |
| 0.20-0.45 | TIDY UP: the left hand pushes the glasses straight again, brows and moustache settle |
| 0.42-0.60 | HARRUMPH: a last chest puff, back to his stroll |

**C. EFFECTS + SOUND** (`Bosses.client` `partnerFx`; licensed `Shared.Sfx` ids only): glasses click, stomp thud,
lift whoosh, lid pop + papers, clasp glint, the big swing whoosh, the gavel knock + a ground crack + papers at the
strike, a crack as it's yanked. The old 0.16 s-late Cone burst is skipped for a boss with clips. Shake within
Radius x 1.6 at the strike (as before, now on the strike frame).

### PAPER STORM (2+ players; section 4)
`Config.Bosses.List[1].Crowd = { Shape = "Disc", Max = 2, Range = 90, Radius = 10 }`. As the windup begins the server
picks up to 2 other players within 90 studs and publishes where they stand (`Crowd1..N`, `CrowdShape` "Disc",
`CrowdRadius`); every client draws a disc + edge in his colour round each spot from the first frame (1.2 s, like the
fan). When the lid bursts (0.78) a bundle of case files (manila folder, pages, red string) arcs out of the case at
each disc, its shadow growing under it, and lands on the centre exactly as the attack starts - the moment the server
hits everyone within 10 studs of it (`BossService.releaseCrowd`, generic: Lane = race out, Disc = land). Walking 10
studs takes 0.31 s at base speed, so standing still is the only way to be caught. A hit is a normal hit.

### Built (2026-10-19)
- **Engine** (`tools/blender/boss_anims.py`): now generic - each boss has `tools/blender/boss_clips/<boss>.py` (timeline
  + clips) and `<boss>_preview.py` (scene); `boss=SeniorPartner` picks one. Megalodon's export is byte-identical.
  New: per-boss `Turn` (hold / time / lead group, exported only when not the default), a ground check (no block below
  the floor in a clip state), hip FOLDS reported apart (a leg top inside the hips / jacket when he bends: hidden).
- **Clips:** windup 37 frames, attack 15, recover 19 (30 fps) -> `src/BossAnims.lua` (60 KB with both bosses).
- **Clipping check:** worst 0.27 studs (neck into head on the glasses look-up, one frame) on a 38-stud boss; a toe dips
  0.45 studs in the 0.1 s cross-fade from the game's walk (the walk itself does that today); the case
  touches the ground at the strike (dips 0.2-0.45 studs into it for 0.1 s: the "thunk"); hip folds max 0.39 (hidden).
  Found and fixed on the way: the glasses push swung the sleeve through the cheek and jacket (now the head turns into
  the hand, the arm comes in only when raised), the torso-led turn swung the case into his legs (now the head leads),
  the stance sank a toe, the moustache flapped into the face, the pendulum dipped the case into the ground.
- **LIVE in Studio since 2026-10-20** (crnuch approved): `ReplicatedStorage.Bosses` rebuilt (Partner 72 parts / 12 groups,
  the other five unchanged), `Shared.BossAnims`, `Bosses` (client), `Server.BossService`, `Shared.Config` replaced from
  `src/` (the live scripts matched the last push exactly, so no merge was needed). 1-player playtest: windup -> attack ->
  recover -> walk all on the clips, the case reaches the zone floor at attack +0.09 s (0.5 studs into it), the lid opens
  to 78 deg, paper bursts + rings fire, no script errors. The playtest caught one bug, fixed before going live:
  `FindFirstChild("CaseLid", true)` found the GROUP Model of that name (now `blockOf`). The 3-player Paper Storm
  playtest is still to do.
- **Review page for approval:** https://claude.ai/artifact/RNpXrekSGvU3QnjdRBuses (crnuch's private artifact; source
  `art/bosses/senior_partner/review.html`).
- **Preview:** `art/bosses/senior_partner/` - `board_*.png` (15 frames), `senior_partner_swing.mp4`, `..._halfspeed.mp4`,
  `senior_partner_gameplay_view.mp4` (green = target walks out of the fan, orange sidesteps its disc, red stays and the
  bundle lands on them), `senior_partner_swing.blend`.
- Rerun: `Blender -b --factory-startup -P tools/blender/boss_anims.py -- boss=SeniorPartner check stills frames`, then
  `tools/blender/encode_preview.py -- <frames>/cine <out.mp4> [speed] [title] SeniorPartner`.

## 7. Prosecutor Big Cheese: CHEESE ROLL + WHEEL SPLIT (2026-10-20, waiting for crnuch's approval)
### His real timeline (BossService "Line" + Config.Bosses.List[4])
| Phase | Server | Duration |
| --- | --- | --- |
| trigger | nearest non-ignored player within `TriggerRange` 60, `AttackEvery` 3.5 s after the last recover | - |
| windup | `Yaw` snaps toward the target, he stands; the lane warning (Width 22, to where he'll stop) | **1.2 s** |
| roll ("attack") | From -> To linear at 120 studs/s, up to 110 studs (shorter at the zone's edge); anyone within 11 studs of his middle is hit, every 0.05 s | **max(0.25, dist / 120)** = up to 0.917 s |
| recover | stands (no dizzy) | **0.6 s** |
A 6.4 x 3.2 = 20.5-stud wheel (radius 10.24 studs). Before: a sine tip (yaw 90 deg) in 0.72 s, the roll by distance
(`POSES.BigCheese`), and in the recover the wheel UNWOUND backwards while standing still; his block rim corners sank
up to 1.2 studs into the floor every turn, and his arms + sword swept through the floor as he rolled.

### Model v2 (`tools/blender/bosses.py`, 47 blocks, 3 -> 5 groups; same blocks, same places)
`Lids` (his smug half-shut eyelids: they snap open) and `Moustache` (twirls, flutters). Other five export byte-identical.

### The roll is code, the rest is clips
- **Roll** (Bosses.client, as before but exact): the wheel turns by the distance really travelled / (R x Scale), about
  the boss's X axis, so it never slips whatever the roll's length. Plus the clip's **Roll** channel (the windup's
  burnout spin in place); the recover's **Unroll** channel (0..1) turns it to the nearest upright angle while it's in
  the air (no more slipping backwards on the spot).
- **RollLift** (new in `Shared.BossAnims`): the block wheel isn't round - at each roll angle its lowest corner reaches up
  to 0.39 model units (1.2 studs) past the radius. The engine measures that from the model (72 angles) and the client
  lifts the root by it: the corners never sink into the floor, and the wheel BUMPS like a brick wheel would.
- **Arms tucked**: for the roll his arms slide into the wheel (only the cocktail stick pokes out of his face, turning
  like an axle pin), and pop back out in the hop. The clipping check counts an arm inside the wheel then as a FOLD
  (hidden by design), not a clip (`check_fold` in `boss_clips/big_cheese.py`).

### Storyboard (times from the start of each server state; the lane warnings are untouched)
**A. ANTICIPATION (windup, 1.2 s)**
| t (s) | Beat |
| --- | --- |
| 0.00-0.12 | NOTICE: his lids snap wide open, a smug bounce (squash 0.94 -> 1.06); a deliberate turn (code: 0.06 hold, 0.28) |
| 0.12-0.42 | EN GARDE: the cocktail-stick sword up in a salute (a gleam off the olive), the moustache twirled; the left arm out |
| 0.40-0.64 | THE TIP: a hop (root +1.0) with a quarter turn in the air onto his edge (back-out), lands at 0.62 with a squash 0.8 that jiggles (5 Hz, decaying): a dust ring |
| 0.62-0.78 | WEDGES (2+ players): two wedges pop off his top (crumbs) and land at the starts of their lanes; his arms slide into the wheel |
| 0.72-0.86 | ROCK BACK: he rolls back a little (-0.35 rad), squashed, eyes wide again |
| 0.86-1.20 | BURNOUT: spins in place, faster and faster (one whole turn), dust + crumbs flung out behind, gears grinding; the moustache bristles |

**B. ATTACK (the roll)**
| Part | Beat |
| --- | --- |
| launch 0-0.2 s | pops forward stretched along the run (1.28) and lands on it, a dust ring at the start |
| loop | rolling (code) with the bump, a small bounce, stretched 1.1 +- 0.04, a slight wobble, the moustache fluttering; dust + crumbs behind, speed streaks |
| brake last 0.2 s | squashes along the run against the stop (0.82), a dust plume thrown forward |

**D. RECOVERY (0.6 s)**
| t (s) | Beat |
| --- | --- |
| 0.00-0.14 | SETTLE: a coin-wobble about the run as it stops (decaying), a dust ring |
| 0.12-0.42 | HOP UPRIGHT: up 1.2, turns back to face the front and rolls to upright in the air (Unroll), arms pop out |
| 0.42-0.60 | LANDING: a squash 0.8 that jiggles, a boing, a smug moustache twirl |

### WHEEL SPLIT (2+ players; section 4)
`Config.Bosses.List[4].Crowd = { Shape = "Lane", Max = 2, Range = 90, Width = 12, Speed = 110, Length = 100 }` - the
Lane add-on the Megalodon uses (server unchanged). The wedges pop off as he lands on his edge (0.62), wait at their
lane's start, and tumble end over end down the lanes from the moment he starts rolling, leaving crumbs; they crumble
at the end. Lane 12 wide: a player at base speed is out of it in 0.19 s.

### Built (2026-10-20)
- **Clips** (`tools/blender/boss_clips/big_cheese.py`, preview `big_cheese_preview.py`): windup 37 frames, charge_launch
  7, charge_loop 7 (loops), charge_brake 7, recover 19 -> `src/BossAnims.lua` (+ his `RollLift`, 72 values). The
  Megalodon's and the Partner's clips are unchanged.
- **Clipping check:** worst 0.27 studs (the salute arm against the rim, one frame) on a 20-stud boss; the floor:
  0.06 studs at worst (the bump keeps the corners out of it); folds (arms tucked in the wheel): by design.
- **Client** (`src/Bosses.client.lua`): the code roll + RollLift + Unroll, `cheeseFx` (olive gleam, landing dust, the
  wedges popping off / waiting / tumbling / crumbling, burnout dust + crumbs, launch ring, the roll's trail, the brake
  plume, the stop and the hop's landing; sounds from the licensed set). **Config:** his `Crowd`.
- **Review page for approval:** https://claude.ai/artifact/7FKSXgNPpwP2Wnt8WHpmW3 (source `art/bosses/big_cheese/review.html`).
- **Preview:** `art/bosses/big_cheese/` (`board_*.png`, `big_cheese_roll.mp4`, `..._halfspeed.mp4`,
  `big_cheese_gameplay_view.mp4`, `big_cheese_roll.blend`).
- Rerun: `Blender -b --factory-startup -P tools/blender/boss_anims.py -- boss=BigCheese check stills frames`, then
  `tools/blender/encode_preview.py -- <frames>/cine <out.mp4> [speed] [title] BigCheese`.

## 8. Status
| Boss | Storyboard | Blender clips | Preview | Client | In Studio |
| --- | --- | --- | --- | --- | --- |
| Magistrate Megalodon | done | done | done | done | **live** (3-player test to do) |
| The Senior Partner | done | done | done | done | **live** (3-player test to do) |
| Barrister Bulldog | - | - | - | - | - |
| Judge Martello | - | - | - | - | - |
| Prosecutor Big Cheese | done | done | done | in `src/` | waiting for approval |
| Chief Justice Eclipse | - | - | - | - | - |
