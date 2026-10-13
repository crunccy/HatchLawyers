# Eggs v5: the eggs, the hatch and the incubator, remade in Blender

The user's request (mr.robe, 2026-10-12):
- "remake the animations everything to do with the eggs through blender and add vfx, use examples in github and make them 10000x cooler and more detailled";
- "recreate the eggs itself also", "make the eggs cooler";
- "i dont like the little balls that protrude out of the eggs".

The user's choices:
- **Scope:** the hatch (crack + reveal) and the incubator, plus the egg models themselves.
- **VFX:** the current ladder maxed (Rare ice, Epic energy, Legendary fire, rainbow at the top), scaled by rarity.
- **Cracks:** they glow white, and the 3rd tap turns them the rarity's colour.
- **Incubator, scaled by rarity:**
  - every egg floats in and the dome spins shut;
  - Rare and up get a longer cook;
  - Legendary and up overload and launch the egg into the sky.
- **GitHub:** learn techniques from open repos and write our own code (spr springs and RbxCameraShaker noise shake, both MIT).

## Status (2026-10-12)

**Done**
- The models, textures and clips are built.
- The upload pipeline works.
- The animations were checked in Studio Edit mode: the incubator clips, the cracked egg and the blast break.

**Blocked on the place owner.** Assets uploaded by mr_blox174 don't load in crnuch's place (verified: crnuch's texture renders, ours doesn't; our meshes give "Failed to load mesh asset"). So **crnuch must upload** (below).

**Ready to install afterwards.** The scripts are in `src/` and `tools/zones/eggs_v5_live/`.

## What it looks like

### Eggs (`tools/blender/eggs_v5.py`)
Every egg shares one smooth lathe shell, 3.0 × 3.8 studs, front = −Z.

**Textures.** Each egg has its own **painted texture**, 1024², painted per pixel from 3D patterns, so nothing stretches and there's no seam:
- **Briefcase:** leather with a stitched front panel, side seams and brass corners.
- **Pet:** calico patches and a paw print.
- **Brainrot:** goofy face, pink blobs, lime zigzag.
- **Food:** waffle cone and pink frosting with sprinkles.
- **Ocean:** deep-to-sky gradient, starfish, bubbles.
- **Space:** nebula, stars, a little planet.

**Golden version:** the texture turned gold, with a flush Fabergé lattice and a jewelled band.

**Relief layers** are flush bands that hug the shell and wear the same texture: the belt, the collar, the dripping frosting and the wave.

**Smooth pieces:**
- Briefcase handle and clasp;
- floppy dog ears and a flat bone tag;
- a pink brain cap;
- a cream swirl and a wafer;
- a shark fin;
- a glowing planet ring.

There are **no little balls** anywhere: patterns are painted, not stuck on.

**Hatch shell.** The hatch uses a finer shell, pre-cut into **12 chunks**: a zigzag belt crack plus meandering cracks, smoothed so there are no grid stairs. On top sit **crack ribbons in 3 stages**: A = the belt's front (tap 1), B = the rest of the belt (tap 2), C = everything (tap 3).

### Break (`tools/blender/egg_break.py`)
Blender rigid-body physics on the chunks, with gravity, tumbling and bounces on the floor, baked at 30 fps in three takes:
- **pop** (Common, Uncommon): the top pops off and the cup falls open;
- **burst** (Rare, Epic);
- **blast** (Legendary and up).

### Incubator (`tools/blender/incubator.py`)
**Model:** a white and teal machine with gold trim, a control panel with a screen, a lift cradle, a glass dome that rises and spins, a floating halo ring, two heat lamps on an arch, and glowing side tubes. It's 22 parts.

**Clips** are keyframed in Blender and sampled at 30 fps:
- **Open:** the dome rises 4.7 and turns.
- **Close:** the dome comes down with a bounce.
- **Cook:** the lamps aim at the cradle, the cradle and halo spin.
- **Overload:** rattling, the dome blown off sideways, lamps flailing, the halo spinning hard, and the cradle crouching and launching.

### The hatch (`StarterPlayerScripts.Eggs`, the "hatch, v5" section)
It all plays in the world at your incubator: a scripted camera, depth of field, a vignette, bloom and colour correction.
1. The egg floats out of your arms into the cradle while the dome opens.
2. The dome closes and it cooks:
   - Common and Uncommon get a quick spin.
   - Rare and Epic: the heat lamps swing in.
   - Legendary and up **OVERLOAD**: flashing alarm lights, sparks, the dome blown off, the egg rocketing into the sky with a trail (the camera follows), then crashing back with rings and a shake.
3. The egg floats up and grows. "Tap to crack!" ×3: cracks spread, the egg jolts on springs, dust and sparks fly off, light leaks out. On the 3rd tap everything turns the rarity's colour.
4. Build-up: god rays (Uncommon and up), streaks rushing in (Epic and up, a black hole for Mythic and up), the screen darkening, a rumble. Then the **burst**:
   - the Blender sim;
   - rings, sparks, confetti and coins;
   - `Effects.burst` (ice / energy / fire / rainbow);
   - a light pillar (Legendary and up);
   - slow motion (Epic and up).
5. The lawyer rises out of the cradle as a silhouette, then in colour with its aura: name + "RARITY · x% chance" → "Tap to continue" → the reveal panel.

Everyone near the incubator sees the same thing, without the camera or the words (`Remotes.HatchShow`, now fired for every incubator hatch).

**Tuning:**
- `Shared.HatchFx` `LADDER`: per rarity, the break take, rings, shake, rays, pillar, implosion, slow motion, coins, confetti, build-up time, cook speed and bloom.
- In the Eggs client: `DISPLAY_EGG` 2.5, `HATCH_EGG` 3.3, `HOVER` 0.55.

## Files

| What | Where |
| --- | --- |
| Eggs, chunks, cracks, textures | `tools/blender/eggs_v5.py` → `_egg_export/` (git-ignored); textures copied to `art/eggs/textures/` |
| Incubator + clips (+ the FxRing VFX torus) | `tools/blender/incubator.py` → `_egg_export/`, `tools/zones/incubator.json` |
| Shell break takes | `tools/blender/egg_break.py` → `tools/zones/egg_break.json` |
| Shared mesh helpers | `tools/blender/meshkit.py` |
| Upload + build in Studio | `tools/zones/BuildEggsV5.lua` (data from `ServerStorage.EggV5Data`) |
| Runtime | `src/EggLook.lua` (v5), `src/HatchFx.lua`, `src/Incubator.lua` |
| Live installs (v5 only, no economy pass) | `tools/zones/eggs_v5_live/` (Eggs client, EggServer, FirmBuilder) |
| `src/` twins with v5 merged in | `src/Eggs.client.lua`, `src/EggServer.server.lua` (+ the pending economy pass) |
| Previews | `art/eggs/v5_preview.png`, `art/eggs/incubator_preview_*.png` |

Regenerate everything:
1. Run `eggs_v5.py`, then `incubator.py`, then `egg_break.py` (in that order: `eggs_v5.py` rewrites the manifest).
2. Copy `egg_break.json` and `incubator.json` into `_egg_export/`.
3. Reload `ServerStorage.EggV5Data` from `_egg_export/`.
4. Delete the `ServerStorage.EggV5Assets` attributes of the meshes that changed, then rerun the builder.

## crnuch: the one-time upload (about 5 minutes)

Do this in crnuch's own Studio, in Edit mode. His local Claude can do steps 3 and 4.
1. `git pull`.
2. Studio: **File → Beta Features → tick "CreateAssetAsync Luau API"** → Save → close and reopen Studio and the place.
3. **Textures:**
   - Serve `art/eggs/textures/` locally (`python3 -m http.server 8766 --directory art/eggs/textures`).
   - Upload the 12 PNGs with the Studio MCP's `upload_image` (`http://localhost:8766/<Name>.png`).
   - On `ServerStorage.EggV5Data`, set the string attributes `Texture_<Egg>` = `"rbxassetid://<id of <Egg>.png>"` and `Golden_<Egg>` = `"rbxassetid://<id of <Egg>_Golden.png>"`, for Briefcase, Pet, Brainrot, Food, Ocean and Space.
4. Run `tools/zones/BuildEggsV5.lua`. Through the MCP: put its source in a ModuleScript as `return function() … end`, require it and call it.
   - It uploads for about 90 s per run. Rerun it until it no longer says "run this again".
   - The last run builds everything and should end with "library swapped in | incubator template ready".
5. Push a SESSION_LOG line saying it's done. Then any local session installs the scripts (next section).

## Installing the scripts (after step 4)

Re-export `studio/` first, then install:
- **New modules:** `Shared.HatchFx` ← `src/HatchFx.lua`, `Shared.Incubator` ← `src/Incubator.lua`.
- **`Shared.EggLook` ← `src/EggLook.lua`.** It's a straight replace: the live copy is v4, unchanged since this snapshot. Check with a diff against `studio/`.
- **`StarterPlayerScripts.Eggs`, `Eggs.EggServer`, `Server.FirmBuilder`** ← `tools/zones/eggs_v5_live/*`.
  - These are the live scripts as of commit `8468c2f`'s `studio/` snapshot plus the v5 changes.
  - If the live script changed since, 3-way merge: `git merge-file live.lua base.lua v5.lua`, with base = `studio/` at `8468c2f`. Never paste over.

Playtest afterwards:
- a Common, a Rare and a Legendary hatch, using test results sent client-side, or tokens;
- another player watching (two clients);
- a phone-sized window;
- a firm's incubators facing the aisle.

Then:
- delete `ServerStorage.EggV5Data` (6.5 MB in the place);
- delete `ServerStorage.Old_EggModels_v4` once happy.
