# Session log

Newest first. Each entry: what changed, where, and what's left. Keep the **Open items** list current —
it is the to-do list for the next session. Move finished items into the dated entry that finished them.

## Open items
- [ ] **Sync the economy mirror.** Paste `ReplicatedStorage.Shared.Config` (and `Formulas.clientInterval`)
      into a session and replace every `GUESS` in `tools/economy_sim.py` / docs/ECONOMY.md with real values —
      `CaseSeconds` and `clientInterval` first (they move results most). Then rerun docs/ECONOMY_REVIEW.md.
- [ ] **Check AFK before the Manager** (review §3): with nobody assigning, do clients pile up / get dropped?
      If so, add auto-assign after ~10–15 s waiting (queue is ours).
- [ ] **Egg pacing** (review §2): one fixed-price egg is free within minutes. Decide: hub egg tiers and/or
      free multi-hatch. Decide whether the ×2.5 cap covers skins alone or the whole stack.
- [ ] **Train ×10 / Max** on the lawyer card (review §4) — needs a heads-up to mr.robe (`TrainLawyer` remote).
- [ ] Add a `Config` comment next to `Payout.Growth` / `Training.Growth`: their ratio sets the whole curve.
- [ ] Rewrite the tutorial steps for the new firm (waiting room + Assign) — review §7.
- [ ] Late-game content for hours 6–15 (desk tiers, rooms, prestige) — review §5.
- [ ] **Add the user's local files to this repo:** `references/`, `tools/firm_kit.py`, `tools/firm_pieces.py`,
      `tools/voxel_builder.py`, `tools/clients.py`, `ClientPalette.png`. Decide whether `.fbx` exports go in
      (they're big; maybe Git LFS) or stay local.
- [ ] Responsive HUD pass: on narrow/phone screens the left-edge buttons (mr.robe's DAILY gift + our SKINS)
      overlap the coin counter and the lawyer card.
- [ ] Publish the lawyer animations (Animation Editor → import .fbx → publish), play Idle at the desk and
      Objection on a win. `PinstripePartner`'s Idle/Walk/Objection are not published yet (user must do it).
- [ ] Desk tier visuals (Folding Table → Oak → Executive → Mahogany): `UpgradeDesk` exists, model doesn't change.
- [ ] EQUIP on the hatch screen always targets desk 1 — let the player pick a lawyer.
- [ ] More skins: add entries to `Config.SkinCatalog` (recolor) or `SkinModels` + catalog (model skins).
- [ ] Blender remake queue (docs/BLENDER_BRIEF.md): egg machine, palm, props, desk tiers, courtroom pieces.
- [ ] Enable Studio API access (Game Settings → Security) when ready to test saving.
- [ ] Resolve design-doc inconsistencies (listed in docs/ECONOMY.md → "Known inconsistencies").

## 2026-10-08 — cloud session: economy analysis
- `tools/economy_sim.py`: added `--report` (purchases, gaps, prices per window, milestones), `--sweep`
  (sensitivity of the targets to each tunable), `--active` (courtroom bonus), runaway detection; prices are
  tracked in seconds of income. Added `tools/test_economy_sim.py` (12 tests).
- Wrote docs/ECONOMY_REVIEW.md. Key results: the curve hangs on `Training.Growth / Payout.Growth` (income ∝ T^3.35;
  TrainGrowth 1.33 → 1T at 11.4 h, 1.34 → 19.8 h); a fixed-price egg is free within minutes; pre-Manager AFK
  income may be zero; early game is ~1 purchase per 2.5 s; late game is training-only.
- New open items above. Nothing was changed in Studio.

## 2026-10-08 — cloud session: repo set up
- Created this repo's layout: `CLAUDE.md` (rules only), this log, `docs/` (DESIGN, ECONOMY, CLIENTS,
  BLENDER_BRIEF), `tools/economy_sim.py`.
- Rewrote the Python economy sim to mirror the live game (training with coins, Payout.Base 1200 × 1.25^L,
  client arrivals scaling with lawyers, Expand + Hire, eggs/skins, pacing-target checks). Values not known
  outside Studio are tagged `GUESS` and printed on every run — sync them (open item above).

## 2026-10-08 — firm redesign built & tested (local session, Studio)
Layout (inspired by `references/layout-fishing-*.webp`, structure only): Entrance (courthouse portico) →
Waiting room → lawyer offices along both walls with a red-carpet aisle → expansions → back library wall.
- Kit: `tools/firm_kit.py` + `tools/firm_pieces.py` → `Models - Environment/LawFirmKit.fbx` (Entrance,
  WaitingRoom, OfficeSegment, LawyerDesk [right side; rotate 180° for left], BackWall, ExpansionLock).
  Plot width 48, waiting room 21 deep, segments 8 deep, back wall 3. Pieces in `Templates.FirmKit` (attr Offset).
- Clients: voxel characters on the lawyer's R15 rig (`tools/voxel_builder.py` + `tools/clients.py`, shared
  `ClientPalette.png`), in `Templates.Clients`. Roster: docs/CLIENTS.md.
- `Server.FirmBuilder` assembles the kit onto `Workspace.Plots.PlotN` (colliders, sign, WaitSeats, ManagerSpot,
  UpgradeSpot, Desk<N>/HireSlot<N>).
- PlayerData v11 (`Firm.Segments`, 8 starting lawyers). Start = 4 segments × 2 sides = 8 slots.
- `CaseService` queue: arrivals → waiting seats → `Remotes.AssignClient` → walk to desk → case → walk out;
  Manager auto-assigns. Arrivals scale with lawyers (`Formulas.clientInterval`).
- `DeskService`: Expand Firm (+1 segment, 2 slots) and Hire Lawyer, both in place.
- Client scripts: `ClientWalk` (Puppet walk/sit), `AssignClients` (ASSIGN TO LAWYER button + lawyer picker).
- Economy retuned in the Studio sim: Payout.Base 1200, TrainGrowth 1.336, ExpandCosts/UnlockCosts in Config —
  all pacing targets OK.
- Puppet fix: limb pivots use the highest VISIBLE part (fixed arms detaching in the courtroom cheer).

## Earlier
- First model skin `PinstripePartner` (Legendary) = `SkinModels.LawyerSkin_Legendary`, from
  `Models - Characters/LawyerSkin_Legendary.fbx`. Root `RootPart` anchored, limbs on Motor6Ds,
  CanCollide/Query/Touch off, faces −Z, feet at y=0.
- Art direction locked to cartoony voxel; mr.robe's realistic restyle archived (see CLAUDE.md).
- Economy scale decided: big simulator numbers, coin-based training (overrides DESIGN.md's XP/upgrade curve).
