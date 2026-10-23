# Visual research handoff — 2026-10-22

**For Claude: start with [VISUAL_POLISH_BRIEF.md](VISUAL_POLISH_BRIEF.md).**

The user's priorities are map detail and UI, followed by VFX and animation. They requested concrete video research, then asked for all findings to be available in GitHub.

## Contents

- [VIDEO_REFERENCES.md](VIDEO_REFERENCES.md): first twelve gameplay/tutorial references.
- [VIDEO_RESEARCH_BATCH_03.md](VIDEO_RESEARCH_BATCH_03.md): five additional inspected lighting, map-building, mobile UI, boss and button references (V13–V17).
- [VIDEO_RESEARCH_BATCH_04.md](VIDEO_RESEARCH_BATCH_04.md): three inventory/animation-event references (twenty total), mode clarity and cue ownership; mobile evidence remains unverified.
- [MAP_UI_ART_DIRECTION.md](MAP_UI_ART_DIRECTION.md): concrete map-detail kit, screen layouts/states, pop-up behavior, motion rules and visual acceptance board.
- [VISUAL_POLISH_BRIEF.md](VISUAL_POLISH_BRIEF.md): prioritized deliverables, UI states, map-detail kit, effect/animation direction, likely integration points and review criteria.
- [VISUAL_SYSTEMS_AUDIT.md](VISUAL_SYSTEMS_AUDIT.md): existing button, animation and particle systems; implementation guardrails and research gaps.
- [ART_REMODEL_BRIEF.md](ART_REMODEL_BRIEF.md): existing approved map/model scope and staged workflow; remains the authority for that sequence.
- [ZONES_REFERENCE.md](ZONES_REFERENCE.md) and [CHARACTER_STYLE.md](CHARACTER_STYLE.md): existing world/character direction.

## Key conclusions

1. Make destinations recognizable through large shapes, route contrast and grouped detail.
2. Improve existing purple panels with clearer hierarchy, larger reward pictures, consistent buttons and readable mobile states.
3. Use particles as accents around important content; reserve large effects for exceptional moments.
4. Give attacks a readable preparation, strike and recovery using whole-body poses.
5. Keep warning geometry independent of optional particle quality and exactly aligned with attack dimensions.
6. Preserve the current chunky, studded world and existing gameplay.

These are design recommendations informed by selected footage; they are not claims that each technique caused a game's commercial success.

## Evidence / status

Selected sections of twenty videos were played and visually inspected, not watched end-to-end. Audio was not directly captured/listened to; sound notes are explicitly lower confidence. Current PS99/Steal an Egg footage is mixed with older useful technique references. Timestamps link to the original videos; no third-party assets, videos or plugins were copied into the game.

This package changes documentation only. No Studio installation, runtime implementation or gameplay test was performed for this research. Existing Studio and repo versions may differ. Read current claims and re-export/merge before implementation.

The research branch is `codex/visual-polish-research`; the PR description links directly to these files so they are usable before merge. Do not assume the default branch contains this package until merged.
