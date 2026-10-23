# Video reference library: map, UI, VFX and animation

Researched 2026-10-22 for Hatch a Lawyer. Start with [the implementation brief](VISUAL_POLISH_BRIEF.md).

## Evidence and scope

The user specifically requested actual video inspection and concrete references, then identified map detail, UI, VFX and animation as the priorities. These notes come from selected playback sections and visible frames/captions in twelve YouTube videos. They are **sampled inspections, not twelve complete end-to-end viewings**. Timestamps are navigation anchors for the inspected scenes; surrounding footage supplies motion context. YouTube titles can change.

No direct listening/audio capture was available to the researcher: sound notes are based on the sound-design video's visible presentation/captions, not a verified assessment of any game's mix. No private game code was inspected. Observed presentation does not prove how a competitor implemented it or why its retention is high. Tutorial code/plugins were not installed, security-audited, or endorsed.

Current relevance: Pet Simulator's Hatch Wars footage was listed as two weeks old, and Steal an Egg footage as one month old on the research date. Grow a Garden's selected beginner footage is older (listed one year old); use its presentation examples, not as evidence of the current economy/UI build. Production tutorials are technique references, not popularity rankings. The [October game-chart snapshot](https://bloxradar.github.io/games/) was used for discovery only; player counts fluctuate and are not copied here.

## Watch first

| ID | Video / creator | Inspected anchors | Most useful for |
| --- | --- | --- | --- |
| V01 | [Everything You Need To Know HATCH WARS in Pet Simulator 99 (Roblox) — Elkonn](https://www.youtube.com/watch?v=C3J9iw0n1FI) | [2:30](https://www.youtube.com/watch?v=C3J9iw0n1FI&t=150s), [2:48](https://www.youtube.com/watch?v=C3J9iw0n1FI&t=168s), [6:11](https://www.youtube.com/watch?v=C3J9iw0n1FI&t=371s) | Route contrast, large landmarks, world-space progression |
| V02 | [I Became the #1 Player in Steal an Egg — SkellyPlays](https://www.youtube.com/watch?v=edX3_ddAY70) | [1:48](https://www.youtube.com/watch?v=edX3_ddAY70&t=108s), [5:24 onward](https://www.youtube.com/watch?v=edX3_ddAY70&t=324s), [10:48](https://www.youtube.com/watch?v=edX3_ddAY70&t=648s) | Plot framing, creature cards, reward confirmation |
| V03 | [THE ULTIMATE BEGINNERS Guide For GROW A GARDEN Roblox! — AmazedBot](https://www.youtube.com/watch?v=n3WqE8Pzf8M) | [1:09](https://www.youtube.com/watch?v=n3WqE8Pzf8M&t=69s), [2:18](https://www.youtube.com/watch?v=n3WqE8Pzf8M&t=138s) | Visible ownership/progress, contextual labels, simple navigation |
| V04 | [Make Your Roblox UI Look 10x Better — Develuper](https://www.youtube.com/watch?v=F6AtQKo3uIY) | [3:31 onward](https://www.youtube.com/watch?v=F6AtQKo3uIY&t=211s) | Button depth, borders, lettering, restrained highlights |
| V05 | [How to Make 2D VFX for your UI — MoldySugar](https://www.youtube.com/watch?v=qnqUiSYm4rk) | [6:45](https://www.youtube.com/watch?v=qnqUiSYm4rk&t=405s), [7:43](https://www.youtube.com/watch?v=qnqUiSYm4rk&t=463s) | Edge emission, texture/flipbook accents |
| V06 | [How to ACTUALLY Use VFX in Roblox — Develuper](https://www.youtube.com/watch?v=TkNZETIu0CM) | [4:41 onward](https://www.youtube.com/watch?v=TkNZETIu0CM&t=281s), [8:27](https://www.youtube.com/watch?v=TkNZETIu0CM&t=507s), [9:00](https://www.youtube.com/watch?v=TkNZETIu0CM&t=540s) | Impact placement, attachment organization, aura layers |
| V07 | [How to Animate Combos in Roblox Studio in 3 minutes (Beginner Friendly) — distovi](https://www.youtube.com/watch?v=7cMjUAtkB8k) | [1:00](https://www.youtube.com/watch?v=7cMjUAtkB8k&t=60s), [1:40](https://www.youtube.com/watch?v=7cMjUAtkB8k&t=100s), [2:20](https://www.youtube.com/watch?v=7cMjUAtkB8k&t=140s) | Whole-body poses, curve workflow, attack follow-through |
| V08 | [The ULTIMATE Blender Modeling Guide for Noobs! (Make Assets For Games!) — SmartyRBX](https://www.youtube.com/watch?v=W337AL7n3dc) | [10:17](https://www.youtube.com/watch?v=W337AL7n3dc&t=617s), [20:35](https://www.youtube.com/watch?v=W337AL7n3dc&t=1235s) | Simple component construction, silhouette before detail |
| V09 | [How to make a simulator map (Part 1) — Dexus Studio](https://www.youtube.com/watch?v=_TVjCtChzbE) | [7:41](https://www.youtube.com/watch?v=_TVjCtChzbE&t=461s), [13:50](https://www.youtube.com/watch?v=_TVjCtChzbE&t=830s) | Platforms, edge treatment, assembly workflow |
| V10 | [So You Wanna Make Games?? Episode 8: Sound Design — Riot Games](https://www.youtube.com/watch?v=KcorIwJscFA) | [about 4:22](https://www.youtube.com/watch?v=KcorIwJscFA&t=262s), [about 7:16](https://www.youtube.com/watch?v=KcorIwJscFA&t=436s) | Frequency concepts and creature-sound presentation; caption/visual review only |

## V01 — Pet Simulator 99: readable routes inside a busy world

**Observed:** Around 2:30–2:48, yellow/orange routes contrast strongly with magenta terrain. Large stylized trees and columns establish the perimeter; pickups, character effects and floating numbers occupy the activity space. HUD icons/currencies sit along the left edge. At 6:11, a castle-like structure frames team information, tall colored banners, flame stations and prominent world-space progress labels.

**Interpretation:** Route color and large shapes do much of the navigation work. Small props are not carrying the whole scene. The progress display is attached to a destination rather than requiring a separate explanation screen.

**Apply to Hatch a Lawyer:** Preserve orange paths and lime grass. Give the License Office and each zone threshold a recognizable silhouette; put unlock information at the gate. Place larger scenery around the route with smaller clusters beneath it. Keep boss/egg interaction space open.

**Do not copy:** This event's entire saturated palette, icon density, exact castle design or reward systems. With our already bright floor, matching its glow intensity would likely hurt readability.

## V02 — Steal an Egg: strong reward focus and visible collections

**Observed:** At 1:48, studded grass and tall warm walls provide a simple backdrop, with bright fence pieces marking plots. At 5:24, collection feedback includes large green currency amounts over the play space; the subsequent Fuse Machine screen uses a purple striped header, dark card grid and large creature pictures. At 10:48 a compact dark result panel shows “You fused”, a purple item name, a centered egg image, a green acknowledgment button and a close control.

**Interpretation:** The creature/egg is the main reward image; title and action form a short reading sequence. The visible grid also illustrates a limit: many names/stats compete in small cards.

**Apply:** Make our reward hierarchy item → name/rarity → useful next action. Keep card thumbnails large, reduce competing labels, and expose secondary stats on selection. Aggregate routine money messages instead of filling every desk with overlapping numbers.

**Existing-style fit:** Our purple striped panels are already established. Improve spacing and hierarchy before proposing another visual theme. Our Mutation Machine brief calls for a 3D transformation; use this video's clarity for the result label, not its modal as a replacement for that scene.

## V03 — Grow a Garden: progress lives in the world

**Observed:** At 1:09 the player looks into a planted plot with a local “Collect” prompt and an item/mutation label near the crop. At 2:18, fenced neighboring plots, an owner sign and oversized plants make the player's possessions visible. Three prominent top buttons read SEEDS, GARDEN and SELL.

**Interpretation:** World objects carry progress and ownership; major navigation labels correspond to concrete activities.

**Apply:** Show a firm's progress through entrance trim, office additions, furniture tiers and the lawyers themselves. Keep the player’s current objective visible without giving every subsystem equal HUD weight. Use existing HudMenu conventions rather than copying the three-button layout literally.

**Caveat:** Older footage; not a claim that all current Grow a Garden screens look this way.

## V04 — button artwork: depth from a small number of layers

**Observed:** The 3:31 sequence constructs a rounded yellow/orange RETRY button in Figma: dark outline, darker lower edge, large outlined lettering and an icon. The following portion adds diagonal lighter accents while keeping the label readable.

**Apply:** Build reusable default/hover-or-focus/pressed/disabled states in our UI kit. Use existing FredokaOne, palette, icon assets and panel rules. A visible lower edge can compress on press, with a short scale response.

**Avoid:** Flattening all text into imported button images; keep labels localizable and responsive. Do not require hover on phones. Preserve generous hit areas.

## V05 — UI particles: emit around content

**Observed:** At 6:45, small outlined squares emit around the boundary of a rectangular button while the word “Button” stays central. At 7:43, the tutorial demonstrates a bright star texture in its button-effects section and discusses texture/flipbook choices in captions.

**Apply:** A claim-ready button can get a brief perimeter sparkle; a new lawyer card can get one accent burst. Turn it off after acknowledgment. Keep particles behind/beside text, not in front of prices or actions.

**Avoid:** Always-on sparkles on every button; the demonstrated full-bright star would overwhelm our smaller UI. The tutorial's plugin is optional; prefer our existing Effects.guiBurst facilities after inspecting them.

## V06 — VFX: separate placement from appearance

**Observed:** The impact section shows raycast/hit-position code and spawning effect pieces at the hit position. The aura section shows an attachment for ground effects, position updates and cleanup/toggle logic. At 9:00, the visible final aura combines a ring at the feet, vertical purple/white light, dark floating particles and bright streaks.

**Apply:** Design effects as several named layers: outline/ground cue, focal burst, secondary particles and short decay. Use our existing Effects/HatchFx and LOD systems. Keep boss warning geometry sourced from authoritative attack dimensions.

**Avoid:** Copying tutorial networking verbatim. Its code is a teaching example, not a security/performance review. The bright final aura is useful as a layering reference, but should be reduced substantially for routine office use. Preserve the character's face and body silhouette.

## V07 — animation: move the body around the action

**Observed:** At 1:00 the editor adjusts a combat pose using torso/arm orientation and timeline keys. The 1:40 section shows the curve-editor workflow. At 2:20, the third-attack demonstration uses a visibly leaning body and extended weapon/arm pose, rather than only rotating a hand.

**Apply:** Boss animation phases should read as preparation → strike → recovery. Give lawyers short work/celebration/react clips with shoulders, head and torso participating. Use subtle idle variation so offices do not move in unison.

**Avoid:** Importing a humanoid combat controller into our custom boss/Puppet rigs. Match their actual joint setup. This research does not measure exact animation frame timings or latency tolerance.

## V08 — models: silhouette and component construction

**Observed:** At 10:17 the creator starts a tree trunk from a cylinder. By 20:35, the tree is assembled from a tapering trunk/branches and several faceted canopy masses at different sizes/heights.

**Apply:** Build a small reusable family of props with recognizable large masses, then vary size/orientation. Translate that composition into our approved studded brick style using Blender; do not switch the game wholesale to smooth low-poly meshes.

**Usefulness:** Foundational modeling workflow. It is not a demonstrated production performance budget.

## V09 — map assembly: platforms and edge detail

**Observed:** At 7:41 a simple raised rectangular platform is scaled/assembled from pieces. At 13:50 a wedge is placed along an edge. These are construction references, not proof of a finished polished map.

**Apply:** Add depth to flat attraction pads through plinths, borders, supports and entry ramps. Detail destinations as assemblies with a clear footprint.

**Avoid:** Treating the video's hand-built Studio method as permission to bypass our Blender requirement. Our existing art brief is the stronger guide for the overall layout.

## V10 — sound: supporting reference, lower confidence

**Observed visually / in captions:** A frequency diagram distinguishes low-to-high components around 4:22; the later inspected section presents creature/roar examples. The video's stated topic is communicating game events through sound.

**Recommendation (not a listening finding):** Give hatch anticipation, reveal, reward and confirmation distinct roles. For a gavel, audition a short wooden transient plus restrained low impact and optional debris tail. Keep music/ambience below the cue that matters. Test with headphones and phone speakers before deciding.

**Do not claim:** That the researcher listened to, measured or verified the mix of these videos.

## Current technical references to use alongside the videos

Videos show presentation. Verify engine details with Roblox's documentation:

- [UI tweens](https://create.roblox.com/docs/ui/animation): position, scale, transparency and easing.
- [Accessibility](https://create.roblox.com/docs/production/publishing/accessibility): reduced motion, contrast, text size and avoiding color/sound-only information.
- [ScreenGui safe areas](https://create.roblox.com/docs/reference/engine/classes/ScreenGui).
- [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters): emission and particle behavior.
- [Lighting/atmosphere](https://create.roblox.com/docs/environment): environmental mood controls.
- [Animation events](https://create.roblox.com/docs/animation/events): markers for synchronizing presentation.
- [Performance guidance](https://create.roblox.com/docs/performance-optimization/improve): profile before choosing geometry/effect budgets.
- [Audio objects](https://create.roblox.com/docs/audio/objects): current modular audio routing; older Sound/SoundGroup tutorials are not the preferred architecture for a new system.
- [Greyboxing](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment): validate navigation, scale and sightlines before detail.
- [BIG Games developer updates](https://www.biggames.io/post): primary source for current PS99 event context, separate from video observations.

## Reuse and further review

Link to original footage; do not extract/re-upload creators' assets, soundtracks, models or full videos. No plugins or free-model packs were installed. Before implementation, Claude should reopen the relevant timestamps, inspect the current Studio state, and record before/after views. Any screenshot comparisons added later should retain source URL, timestamp and a clear distinction between external reference and our own game.

## V11 — Fisch: detail clusters and a collection screen

[ FULL GUIDE To FISCHFRIGHT 3 In Fisch Roblox! — Carbon Meister Plays](https://www.youtube.com/watch?v=QkOhdClVIn4). Listed four days old when inspected on 2026-10-22. Sampled scenes only; seasonal styling is not a claim about the entire game.

- [6:06](https://www.youtube.com/watch?v=QkOhdClVIn4&t=366s): a daytime shoreline uses patterned sand, small stones, a large rock/wall mass, a tree trunk and a short rail. Distant water/haze separates the background. Detail occurs at different scales.
- [12:13](https://www.youtube.com/watch?v=QkOhdClVIn4&t=733s): the Bestiary has a location list at left, a central card grid, selected-entry details at right, and a completion footer. Icons, silhouettes and unknown entries communicate different discovery states. Some labels appear small in this footage; do not inherit its exact typography.
- [18:20](https://www.youtube.com/watch?v=QkOhdClVIn4&t=1100s): dock posts and wooden decking lead to sand; orange/purple lights hang above the crossing. Pumpkin, cauldron, character silhouette and cobweb occupy a nearby rock recess. Warm light and a large bright prop mark the transition.

**Application:** Compose the pier entrance as one clear destination: recognizable sign/structure, a medium bench or legal-notice board, and a few briefcases/paper props underneath. Put overhead decoration above the walking lane. Borrow the hierarchy and placement, keeping our bright studded art direction rather than adopting Halloween scenery. For the lawyer collection, explore selected-card details beside a simpler grid on wide screens and a separate detail view on phones. Keep locked/unknown/owned states distinct without relying only on rarity colors.

**Review task:** Before building props, take the approach view, eye-level interaction view and distant overview. The cluster should identify the destination in all three; small paper clutter alone cannot do that.

## V12 — Pet Simulator 99: a rare hatch can overwhelm its subject

[Hatching Titanic Soccerball Cat In Pet Simulator 99! (NO WAYYYY) — Sashamingon](https://www.youtube.com/watch?v=TeFsGfVab6Q). A 33-second clip, listed three months old on inspection.

**Observed:** At [0:02](https://www.youtube.com/watch?v=TeFsGfVab6Q&t=2s), the world includes rainbow steps and a green soccer area, with currencies left and event goals right. At [0:17](https://www.youtube.com/watch?v=TeFsGfVab6Q&t=17s), a large luminous white/blue egg is centered. At [0:22](https://www.youtube.com/watch?v=TeFsGfVab6Q&t=22s), the sampled reveal frame is dominated by white light and outward colored streaks; a lower announcement identifies the Titanic Soccerball Cat. At [0:29](https://www.youtube.com/watch?v=TeFsGfVab6Q&t=29s), bright multicolor streaks remain visible. HUD and world stay present. These samples do not establish exact phase durations or the complete pet presentation.

**Application:** Give our rare hatch separate anticipation, opening, character hold and confirmation stages, but keep the lawyer recognizable during the hold. Use a restrained background flare and a clear name/rarity line. Reserve the strongest burst for the transition, then remove it quickly enough to inspect the reward. This is a recommended sequence, not a measured reproduction of the video's timing.

**Review task:** Check the peak-effect frame and the following character hold separately. Can a player identify the face, outfit, name and next action? If the silhouette disappears in white, reduce overlapping glow layers before adding more particles.
