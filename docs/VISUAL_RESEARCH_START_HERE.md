# Visual research handoff — 2026-10-22

**For Claude: start with [ACTIONABLE_VISUAL_UPGRADES.md](ACTIONABLE_VISUAL_UPGRADES.md) for concrete current-source tasks, then [VISUAL_POLISH_BRIEF.md](VISUAL_POLISH_BRIEF.md) for the overall direction.**

The user's priorities are map detail and UI, followed by VFX and animation. They requested concrete video research, then asked for all findings to be available in GitHub.

## Current style override — checked 2026-10-24

Read [UI_STYLE_V3.md on current main](https://github.com/crunccy/HatchLawyers/blob/main/docs/UI_STYLE_V3.md) before implementing any older research. It supersedes older font/material suggestions: Gotham Black/Bold, plain deep-purple window bodies, decorated saturated cards, muted-purple inactive states, no gold hover ring, deliberately small pop-ups. Fredoka/LuckiestGuy/BuilderSans recommendations in older notes are retired. Preserve the chunky studded world. Research branch snapshots can lag current main; inspect current source before treating an old finding as an outstanding defect.

**Map status correction:** [current main ART_REMODEL_BRIEF](https://github.com/crunccy/HatchLawyers/blob/main/docs/ART_REMODEL_BRIEF.md) marks the approved stage-1 map plan completed. Treat earlier pending-stage language as historical; inspect current assets/claims and propose focused polish.

## Contents

- [ODDS_BOARD_READABILITY.md](ODDS_BOARD_READABILITY.md): V31; world-sign resolution versus viewing size, local inspection UI, normal/golden/pass labels and base-rarity versus pity semantics, with current-source boundaries.

- [UI_MOTION_LIFECYCLE.md](UI_MOTION_LIFECYCLE.md): current Skin/Rewards motion audit; stop claimed-picture breathing, remove four-Hz tile pulse, suspend hidden glints/sparkles and preserve v3; extended V17 samples.

- [DECOR_CLUSTER_HANDOFF.md](DECOR_CLUSTER_HANDOFF.md): existing library asset reuse, explicit cluster transforms, grounding, collision/query review and scoped export; expanded V14 coverage.

- [REWARD_STATE_CLARITY.md](REWARD_STATE_CLARITY.md): V30 current event/shop hierarchy samples; daily/playtime timer semantics, loading/pending states and inline receipts, based on fresh UI v3 Rewards source.

- [ATMOSPHERE_READABILITY.md](ATMOSPHERE_READABILITY.md): fresh ambience audit, rate-versus-live-particle suppression, mist anchor placement, quality budget and cinematic handoff; expanded V13 coverage (no new video count).

- [MUTATION_UI_CLARITY.md](MUTATION_UI_CLARITY.md): source-backed outcome/consequence copy, input eligibility and persistent result states; V29 secondary machine-framing footage with explicit experience-identity limits.

- [EGG_INTERACTION_CLARITY.md](EGG_INTERACTION_CLARITY.md): V28; readable carry HUD, focused egg cue, perimeter detail and confirmed pickup feedback; source audit and scoped acceptance criteria.

- [TRAVEL_UI_WAYFINDING.md](TRAVEL_UI_WAYFINDING.md): V27; compact travel layout, consistent island/card landmarks and destination status, with current-source boundaries and acceptance criteria.

- [BOSS_AND_HATCH_READABILITY.md](BOSS_AND_HATCH_READABILITY.md): V25–V26; source-confirmed growing warnings, capsule endpoints, cone close-range exception, readable attack poses and hatch layer/cleanup specifications.

- [ACTIONABLE_VISUAL_UPGRADES.md](ACTIONABLE_VISUAL_UPGRADES.md): V23–V24 plus source-grounded compact UI, portrait fitting, runtime hub detailing, firm silhouettes and notification priorities; V23–V24 coverage.

- [VIDEO_REFERENCES.md](VIDEO_REFERENCES.md): first twelve gameplay/tutorial references.
- [VIDEO_RESEARCH_BATCH_03.md](VIDEO_RESEARCH_BATCH_03.md): five additional inspected lighting, map-building, mobile UI, boss and button references (V13–V17).
- [VIDEO_RESEARCH_BATCH_04.md](VIDEO_RESEARCH_BATCH_04.md): three inventory/animation-event references (V18–V20), mode clarity and cue ownership; mobile evidence remains unverified.
- [MOBILE_PRESENTATION_STUDY.md](MOBILE_PRESENTATION_STUDY.md): V21, visibly present touch controls, interaction feedback, duplicate notifications and related stall designs; touch presentation reference.
- [ENVIRONMENT_SCALE_STUDY.md](ENVIRONMENT_SCALE_STUDY.md): V22, avatar-relative scale and reusable prop/effect contact sheets; V22 coverage.
- [MAP_UI_ART_DIRECTION.md](MAP_UI_ART_DIRECTION.md): concrete map-detail kit, screen layouts/states, pop-up behavior, motion rules and visual acceptance board.
- [VISUAL_POLISH_BRIEF.md](VISUAL_POLISH_BRIEF.md): prioritized deliverables, UI states, map-detail kit, effect/animation direction, likely integration points and review criteria.
- [VISUAL_SYSTEMS_AUDIT.md](VISUAL_SYSTEMS_AUDIT.md): existing button, animation and particle systems; implementation guardrails and research gaps.
- [ART_REMODEL_BRIEF.md](ART_REMODEL_BRIEF.md): existing approved map/model scope and staged workflow; remains the authority for that sequence.
- [ZONES_REFERENCE.md](ZONES_REFERENCE.md) and [CHARACTER_STYLE.md](CHARACTER_STYLE.md): existing world/character direction.

## Key conclusions

1. Make destinations recognizable through large shapes, route contrast and grouped detail.
2. Improve current UI v3 purple panels with clearer hierarchy, larger reward pictures, consistent buttons and readable mobile states.
3. Use particles as accents around important content; reserve large effects for exceptional moments.
4. Give attacks a readable preparation, strike and recovery using whole-body poses.
5. Keep warning geometry independent of optional particle quality and exactly aligned with attack dimensions.
6. Preserve the current chunky, studded world and existing gameplay.

These are design recommendations informed by selected footage; they are not claims that each technique caused a game's commercial success.

## Evidence / status

Selected sections of thirty-one videos were played and visually inspected, not watched end-to-end. Audio was not directly captured/listened to; sound notes are explicitly lower confidence. PS99/Steal an Egg footage is mixed with older useful technique references. V29's exact experience is unverified and is labeled a secondary visual reference, not official PS99 gameplay. Timestamps link to the original videos; no third-party assets, videos or plugins were copied into the game.

This package changes documentation only. No Studio installation, runtime implementation or gameplay test was performed for this research. Existing Studio and repo versions may differ. Read current claims and re-export/merge before implementation.

The research branch is `codex/visual-polish-research`; the PR description links directly to these files so they are usable before merge. Do not assume the default branch contains this package until merged.
