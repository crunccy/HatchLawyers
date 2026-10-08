# Hatch Lawyers and Get Rich

> Design manifesto as written by the team (pasted by crnuch on 2026-10-07). Kept as written — it is the
> vision, not the spec. Where it disagrees with the live game, the live game and these docs win:

| Section | Status | What's current |
| --- | --- | --- |
| Summary, Core Loop, Case Outcomes, Design Philosophy | ✅ current | — |
| Client Rarity Tiers | ✅ mostly | Roster: [CLIENTS.md](CLIENTS.md). Celebrity-style Legendaries must stay fictional |
| Firm Expansion (desk tiers 1–6) | ⚠️ superseded | Segments + Expand/Hire, 8 starting lawyers — [../CLAUDE.md](../CLAUDE.md), [ECONOMY.md](ECONOMY.md) |
| Lawyer Skill Progression | ⚠️ partly | Levels come from **training with coins**, not XP |
| Egg & Skin System | ⚠️ partly | 4 rarities live (58/26.5/13/2.5 %) — [ECONOMY.md](ECONOMY.md) |
| Cash System & Scaling | ❌ superseded | [ECONOMY.md](ECONOMY.md) (Base 1200, TrainGrowth 1.336) |
| Art Direction → Color Palette / "navy, gold, chrome" | ❌ superseded | Cartoony voxel palette in [../CLAUDE.md](../CLAUDE.md) |
| Monetization, Rewards & Engagement | 🕒 post-MVP | Not built; MVP rules in "MVP Risk Fixes" still apply |
| Tutorial, Mini Courtroom, MVP Risk Fixes | ✅ current | — |

## 📌 Summary

**Hatch Lawyers and Get Rich** is a Roblox idle/gacha game designed for a younger audience. Players start in a tiny one-desk law office and work their way up to a Supreme-level empire by rolling for lawyers, taking on randomized client cases, and reinvesting their earnings into upgrades.

The core hook is simple: assign a lawyer to a desk, equip collectible skins earned from eggs, get assigned a random client, and earn a payout based on the lawyer's skill level multiplied by both the client's rarity and the difficulty of their case. The better your lawyers and the rarer your clients, the more money you make. Cases run automatically so players can earn passively while AFK, but active players are rewarded with a bonus payout for watching the mini courtroom verdict live.

As players grow, they unlock a Manager to auto-run their firm, expand their office with more desks and rooms, and watch their lawyers level up and gain random skills through experience. The game blends the addictive pull of gacha collecting with the satisfying progression of a tycoon — keeping it easy to pick up but with enough depth to keep players coming back.

**Core pillars:**

- 🎲 **Roll** for lawyers (gacha)
- ⚖️ **Earn** through randomized client cases
- 🏢 **Build** your firm from one desk to a legal empire
- 🤖 **Automate** with the Manager so the money never stops

---

A Roblox idle/gacha game where players roll for lawyer skins, take on randomized clients, and build a law empire from a single desk to a Supreme-level firm.

---

## ✅ Core Gameplay Loop

1. **Roll** for a lawyer skin, equip it on a base lawyer, and assign them to a desk
2. **Client arrives** randomly — rarity determines payout potential
3. **Assign** lawyer to client — case runs automatically
4. **Watch** the mini courtroom (active bonus) or let it run AFK
5. **Collect** payout — `Skill Level × Client Rarity × Case Difficulty`
6. **Upgrade** — more desks, better rooms, unlock the Manager
7. **Repeat** with more lawyers running simultaneously

---

## ⚖️ Client Rarity Tiers

| Tier | Client | Situation | Multiplier |
| --- | --- | --- | --- |
| Common | Your neighbor Dave | Disputes a parking ticket | 1x |
| Uncommon | A local bakery owner | Suing a supplier for a broken contract | 3x |
| Rare | Tung Tung Sahur | Accused of property damage after a midnight rampage | 8x |
| Epic | A retired CEO | Multi-million dollar inheritance dispute with 12 family members | 20x |
| Legendary | Chef Mega | Sued by contestants claiming a fictional cooking contest was rigged | 50x |
| Legendary | Rocket Baron Rex | Accused of abruptly laying off staff at a fictional launch company | 50x |
| Legendary | Milo Vex | Breach of contract with a fictional fashion label | 50x |
| Legendary | DJ Beatbox | Copyright dispute over a fictional song | 50x |
| Legendary | Kiki Glow | Trademark battle over a fictional beauty brand | 50x |

---

## 🏢 Firm Expansion (Post-MVP vision)

Players start with a single dingy desk and expand over time.

| Tier | Name | Desks | Unlock |
| --- | --- | --- | --- |
| 1 | Closet Office | 1 | Start |
| 2 | Studio Suite | 3 | 500 coins |
| 3 | Small Firm | 6 | 5,000 coins |
| 4 | Mid-Size Practice | 12 | 50,000 coins |
| 5 | Law Tower | 25 | 500,000 coins |
| 6 | Supreme Empire | 50 | Prestige unlock |

**Desk Tiers:** Folding Table → Oak Desk → Executive Desk → Mahogany Partner's Desk
Each desk has a visual tier and a permanent passive stat upgrade for the lawyer assigned to it. Desk upgrades stay with the desk and do not follow a lawyer when reassigned.

**Unlockable Rooms:**

- **Break Room** — passive lawyer XP regen
- **Library** — reduces case research time
- **Conference Room** — group cases for massive payouts
- **Courtroom** — enables the mini courtroom minigame

---

## 🎬 Mini Courtroom (Active vs. AFK)

Clicking an active case zooms into a mini courtroom:

- Lawyer and client on one side, opponent on the other
- Animated arguments, speech bubbles, gavel sounds
- RNG mid-case events (e.g. "Surprise witness! +20% payout")
- Verdict: judge slams gavel, WIN or LOSE screen with coin pop

**"Attend Court" Bonus** — AFK earns full base payout with no penalty. Watching the courtroom cutscene gives a bonus on top:

- Clean win verdict → +15%
- Reacting to a mid-case RNG event → +22%
- Perfect verdict (rare outcome) → +30%

---

## 🗂️ Manager Upgrades (Post-MVP vision)

**Core:**

- **Auto-Assign** — automatically assigns lawyers to incoming cases
- **Case Filter** — ignores cases below a set payout threshold
- **Priority Queue** — routes rarest clients to best lawyers first

**Efficiency:**

- **Paralegal Staff** — reduces case duration
- **Case Research Bonus** — gives lawyers a pre-case skill boost
- **Double Booking** — one lawyer handles two low-tier cases at once
- **Rush Order** — pay coins to instantly complete a case

**Passive Income:**

- **Retainer Clients** — flat fee every X minutes regardless of cases
- **Settlement Bot** — auto-settles low-skill cases for guaranteed (reduced) payout
- **Referral Network** — passively generates new client leads while offline

**Late Game:**

- **Senior Partner** — second manager slot for a second firm wing
- **Reputation Boost** — permanently raises incoming client rarity
- **Case Archive** — completed cases resurface as appeals with bonus payouts
- **Corrupt Judge** — guarantees a win but risks a reputation-tanking scandal

---

## ⚖️ Lawyer Skill Progression

All players start with a base lawyer. Lawyers are not collectible rarities; progression comes from lawyer levels, rolled skills, collectible skins, and the desk where each lawyer works.

- Each unlocked desk hosts one lawyer
- Max 3–5 skills per lawyer
- Lawyers earn random skills every X cases completed (like a loot drop)
- Duplicates stack or upgrade to a stronger version
- Skill rarity uses the full seven-tier system: Common, Uncommon, Rare, Epic, Legendary, Mythic, and Supreme
- Desk upgrades apply a passive boost to the lawyer assigned to that desk

| Rarity | Skill | Effect |
| --- | --- | --- |
| Common | Fast Talker | -10% case duration |
| Common | Organized | +5% base payout |
| Uncommon | Specialist | +25% payout for one case type |
| Uncommon | Charming | Higher chance of Legendary clients requesting them |
| Rare | Silver Tongue | RNG events more likely to swing positive |
| Rare | Never Loses | Once per day, converts a loss into a settlement |
| Legendary | Shark | +50% payout on all cases, doubles AFK earnings |
| Legendary | Supreme | Unlocks a secret "Supreme Court" case tier |
| Mythic | Reality Bender | +75% payout on Legendary and Supreme Court cases |
| Supreme | Perfect Argument | Guarantees a clean win once per day and unlocks a unique courtroom animation |

---

## 🎲 Case Outcome System

### The 3 Outcomes (No Hard Losses)

| Outcome | How It Feels | What Happens |
| --- | --- | --- |
| ✅ Win | "Let's go!" | Full payout |
| 🤝 Settlement | "Still got paid!" | 40–60% payout |
| ⚠️ Mistrial | "Try again!" | Case requeues, no coins lost |

The word "lose" never appears on screen. The floor is always $0, never negative.

### RNG Formula

```
Win Chance = clamp(0.70 + ((Skill Level − Client Difficulty) × 0.003), 0.45, 0.95)
```

**Client Difficulty Values:**

| Client Rarity | Difficulty |
| --- | --- |
| Common | 0 |
| Uncommon | 10 |
| Rare | 25 |
| Epic | 45 |
| Legendary | 70 |

**Sample Win Rates:**

| Skill | vs Common | vs Rare | vs Legendary |
| --- | --- | --- | --- |
| 1 | 70% | 63% | 45% |
| 25 | 77% | 70% | 55% |
| 50 | 85% | 77% | 64% |
| 75 | 92% | 85% | 72% |
| 100 | 95% *(cap)* | 93% | 79% |

**Non-Win Split:**

- 70% of non-wins → Settlement (partial payout)
- 30% of non-wins → Mistrial (case requeues)

Example: Skill 25 vs Legendary = 55% win, 31.5% settlement, 13.5% mistrial — kid still gets paid the vast majority of the time.

---

## 🥚 Egg & Skin System

### How It Works

- Every player starts with a **base lawyer** — each unlocked desk provides another base lawyer slot
- **Eggs roll for skins** only — collectible cosmetic layers that can be equipped on any lawyer
- Skins don't replace lawyers; they dress them up and always provide a fixed passive gameplay buff based on rarity
- Skin buffs can affect case payout, case speed, lawyer XP, client rarity, win chance, AFK income, and skill-roll luck
- Skin, desk, skill, room, Manager, VIP, and Attend Court bonuses stack incrementally using intentionally small values
- One skin can be equipped on each lawyer; the same skin can be equipped on multiple lawyers, swapped freely, and removing it removes its buff immediately
- **Duplicate skins** can be equipped on multiple lawyers or sold for coins
- Skin XP is not used; future updates may add duplicate-skin fusing or mutations
- **Buy eggs at the main hub** in the center of the map using coins earned from cases

### Skin Rarity Tiers

| Tier | Color | Pull Rate | Pity Guarantee | Bonus |
| --- | --- | --- | --- | --- |
| Common | Gray | 55% | — | Cosmetic + small passive buff |
| Uncommon | Green | 25% | — | +2% payout |
| Rare | Blue | 12% | — | +5% payout |
| Epic | Purple | 5% | — | +10% payout + visual FX |
| Legendary | Gold | 2.5% | Every 50 pulls | +20% payout + animated FX |
| Mythic | Red | 0.4% | Every 150 pulls | +35% payout + unique idle animation |
| Supreme | Rainbow | 0.1% | Every 300 pulls | +50% payout + full lawyer transformation |

### Roll Rules

- Mythic and Supreme skins can appear from every egg; no previous rarity unlock is required
- The first free egg is guaranteed Uncommon and does not reset the pity counter
- Pity tracks total egg rolls: Legendary at 50, Mythic at 150, and Supreme at 300
- Skin buff values are fixed, not randomized

### Skill Rolling (Separate from Eggs)

- Click any lawyer to open their **Lawyer UI**
- Roll for skills directly here using coins — no eggs involved
- Lawyers can hold 3–5 skills max
- Duplicate skills stack or upgrade to a stronger version
- Skill rarity follows the same 7-tier system as skins

### Map Layout Note

- The **main hub** sits in the center of the map — egg shop, skin shop, leaderboards, VIP lounge all here
- **Two rows of firm plots** extend from each side of the hub — 4 to 6 firms per row, 8 to 12 total
- Players walk from their firm to the hub to roll eggs and spend earnings
- Passing other players' firms along the way creates organic social interaction

---

## 🎁 Rewards & Engagement Systems (Post-MVP vision)

### Daily Rewards

- Log in each day to claim a reward from a streak chest
- Rewards scale with streak length — Day 1 gets coins, Day 7 gets a guaranteed Rare lawyer egg
- Missing a day resets the streak (or a "streak shield" consumable can protect it)
- **Streak Milestones:** Day 30 = Legendary egg, Day 100 = exclusive cosmetic lawyer outfit

### Playtime Rewards

- Earn bonus coins and eggs just for being in the game
- Reward drops every 15–30 minutes of active playtime
- AFK players still earn passive case income but don't qualify for playtime drops (incentivizes staying active)
- **Playtime Milestones:** 1 hour = bonus case slot, 5 hours total = exclusive desk skin

### Global Leaderboards

- **Richest Firms** — ranked by total coins earned all-time
- **Most Cases Won** — ranked by total case wins
- **Top Lawyers** — ranked by highest individual lawyer skill level
- **Biggest Single Payout** — ranked by the largest single case payout ever earned

### Social Rewards (One-Time)

| Action | Reward |
| --- | --- |
| Like the game | 1 free Common lawyer egg |
| Favorite the game | 500 coins + 1 Uncommon egg |
| Join the Roblox group | 1 Rare lawyer egg + exclusive group badge on your firm |
| Share to social (Roblox feature) | Bonus daily reward chest for 3 days |

---

## 💰 Cash System & Scaling

**Base Payout Formula:**

```
Payout = Base Skill Payout × Client Multiplier × Modifiers
```

**Base Skill Payout (exponential curve):**

```
Base Payout = 10 × (1.25 ^ Skill Level)
```

| Skill Level | Base Payout Per Case |
| --- | --- |
| 1 | ~12 coins |
| 10 | ~93 coins |
| 25 | ~2,800 coins |
| 50 | ~808,000 coins |
| 75 | ~229,000,000 coins |
| 100 | ~65,000,000,000 coins (65B) |

**× Legendary client (50x) at skill 100 = ~3.25 Trillion per case**

**Modifier Stack** (bonuses stack incrementally; each source uses intentionally small values):

| Modifier | Multiplier |
| --- | --- |
| Matching specialty | 1.25x |
| Shark skill | 1.5x |
| Mahogany desk | 1.2x |
| Attend Court bonus | 1.15–1.30x |
| Conference Room group case | 2x |
| Skin buff | Fixed, rarity-based additive bonus |

**Max possible single case** (skill 100 + legendary + all modifiers):

```
65B × 50 × 1.25 × 1.5 × 1.2 × 1.30 × 2 = ~19 Trillion
```

**Upgrade Cost Curve:**

```
Upgrade Cost = 100 × (2 ^ Upgrade Level)
```

| Upgrade Level | Cost |
| --- | --- |
| 1 | 200 coins |
| 5 | 3,200 coins |
| 10 | ~102,000 coins |
| 15 | ~3.3M coins |
| 20 | ~104M coins |
| 25 | ~3.3B coins |
| 30 | ~107B coins |
| 35 | ~3.4T coins |

**Balance Rules:**

- Next upgrade always costs ~10 mins of active earning at current stage
- AFK earns full base rate — no penalty for stepping away
- Watching the courtroom gives +15–30% bonus on top of base
- Legendary case payout should feel like a windfall — enough to skip 2–3 upgrade levels
- Daily reward = ~5 mins of active earning at current stage

---

## 💎 Monetization (Post-MVP — not part of the first release)

**MVP rule:** no Robux coin packs, no Robux-to-egg conversion, and no paid random skin rolls. The ideas below are a future backlog only. Any future paid-random system requires a separate policy review, clear odds disclosure, and age-appropriate safeguards.

### 👑 VIP Pass — 999 R$

*The flagship pass — bundles earnings, gameplay, and flex.*

**Earnings:**

- +25% bonus on all case payouts
- +1 free egg every 24 hours
- Flat coin drop every 5 minutes passively

**Gameplay:**

- Double Case Slots — run 2 cases per lawyer simultaneously
- Lucky Client — raises minimum client rarity
- Cases complete 15% faster

**Cosmetic / Status:**

- Gold VIP crown above your lawyer in the courtroom
- Exclusive VIP badge on your firm + leaderboard
- Golden firm nameplate
- VIP-only lounge area in the main hub

**Social:**

- VIP chat tag in game
- Access to VIP-only leaderboard

---

### Standalone Gamepasses

| Gamepass | What It Does | Price |
| --- | --- | --- |
| **2x Cash** | Doubles all case payouts permanently | 499 R$ |
| **Egg Luck Boost** | Permanently improves pull rates across all tiers | 399 R$ |
| **Pity Halver** | Cuts Legendary pity 50→25 pulls, Mythic 150→75 | 299 R$ |
| **Lucky Client** | Raises minimum client rarity (fewer Commons, more Rares+) | 299 R$ |
| **Daily Free Egg** | One free egg roll every day just for logging in | 149 R$ |
| **Bonus Verdict** | Attend Court bonus increases from 30% max → 50% max | 199 R$ |
| **Instant Egg Hatch** | Skip the hatch animation, get results immediately | 75 R$ |
| **VIP Retainer** | Flat coin income every 5 minutes on top of everything | 199 R$ |
| **Firm Customizer** | Change your firm's name color and theme (color palette + signage) | 99 R$ |
| **Boss Music Pack** | Custom courtroom music and sound FX | 75 R$ |
| **Lucky Penny** | Permanently adds +1% to all case payouts | 5 R$ |
| **Coin Trail** | Your character leaves a coin particle trail in the hub | 3 R$ |

> 💡 VIP Pass overlaps with Lucky Client and VIP Retainer — VIP players don't need those standalone passes.

---

## 🎓 Tutorial & New Player Flow

**Goal:** Get the player from spawn to their first payout in under 2 minutes. Every step rewards them immediately. The word "tutorial" never appears — it just feels like playing.

**Skip button** available for returning players or alts.

---

### Step-by-Step Flow

**Step 1 — Spawn & Greeting (0:00–0:15)**

- Player spawns inside their tiny Closet Office (1 desk, dim lighting, cracked window)
- A friendly paralegal NPC pops up: *"Welcome to the firm! We just got our first client. Let's get to work."*
- Arrow points to the desk

**Step 2 — First Case (0:15–0:45)**

- Player clicks the desk — a Common client auto-assigns (neighbor Dave, parking ticket)
- Case runs immediately — short 10-second version for tutorial
- First case is **scripted: 100% guaranteed win**, no RNG
- Big WIN screen with coin pop and confetti — coins land in their wallet visibly
- NPC: *"Ka-ching! That's how we do it."*

**Step 3 — Level Up Your Lawyer (0:45–1:00)**

- Arrow points to the lawyer — *"Click your lawyer to upgrade them!"*
- Player opens Lawyer UI, one free level-up is pre-loaded and waiting
- Skill bar fills up with a satisfying animation
- NPC: *"The better your lawyer, the bigger the payout."*

**Step 4 — Walk to the Hub (1:00–1:20)**

- Arrow + glowing path leads player from their firm to the main hub
- Hub music kicks in, it's busy and colorful
- NPC: *"This is where the real fun is. Try hatching an egg!"*

**Step 5 — Free First Egg (1:20–1:45)**

- Player walks up to the egg shop — a glowing FREE egg is waiting for them
- They click it — full hatch animation plays (egg shakes, cracks, reveals skin)
- Skin rarity is scripted: guaranteed **Uncommon** on first hatch
- Big popup: *"New Skin Unlocked!"* with equip button

**Step 6 — Apply the Skin (1:45–2:00)**

- Player taps equip — lawyer's appearance updates with the new skin
- Confetti, sound effect, lawyer does a little celebration animation
- NPC: *"Looking sharp, counselor. Now get back to work — clients are waiting!"*

**Step 7 — Tutorial Complete**

- Tutorial banner fades out
- Second client auto-arrives at the desk back in the firm
- Subtle tip appears: *"More desks = more lawyers = more money. Upgrade your firm when you're ready."*
- Game opens fully — all UI unlocked

---

### Tutorial Design Rules

- Total time: **~2 minutes**
- First win is always **100% scripted** — no RNG, always a clean WIN
- First egg is always **free and Uncommon** — sets positive expectations for the gacha
- No walls of text — all guidance is short NPC speech bubbles + glowing arrows
- Each step rewards the player **before** moving to the next one
- The NPC paralegal stays available as a hint system after tutorial ends

---

## 🎨 Art Direction & Vibe

### Overall Tone

**Chaotic professional** — it looks like a real law firm but everything is slightly unhinged. The lawyers are expressive cartoon characters, the clients range from normal people to brainrot icons, and the firm goes from a dingy closet to a glowing skyscraper. The humor is subtle and visual, not text-heavy.

### Color Palette

| Element | Colors |
| --- | --- |
| Early firm (Closet Office) | Dull beige, fluorescent white, dirty brown |
| Mid firm | Warm wood tones, navy, gold accents |
| Late firm (Law Tower+) | Deep charcoal, electric blue, polished chrome |
| Main hub | Bright, saturated — think busy city plaza with neon signs |
| UI | Clean white panels, gold coin icons, rarity colors per tier |
| Win screen | Green burst, gold coins raining |
| Settlement screen | Yellow/orange, calm tone |
| Mistrial screen | Soft blue, neutral — never red or alarming |

### Art Style

- **Roblox-native cartoon** — slightly exaggerated proportions, expressive faces, snappy animations
- Lawyers have distinct silhouettes so players can tell them apart at a glance
- Clients are caricatures — brainrot characters are deliberately chaotic, celebrities are fictionalized and goofy
- The courtroom feels like a toy version of a real courtroom — oversized gavel, dramatic lighting, animated judge

### UI Style

- Clean and minimal — kids shouldn't feel overwhelmed
- Large buttons, bold text, clear icons
- Rarity colors are consistent everywhere (gray/green/blue/purple/gold/red/rainbow)
- Coin counter animates when money comes in — numbers roll up satisfyingly
- Payout pop-ups are big and celebratory, never buried

### Sound Design

- **Upbeat lo-fi hip hop** as the default firm BGM — chill enough for long sessions
- **Hub music** is louder, more energetic — signals you're in the action zone
- **Courtroom** has dramatic orchestral stings during arguments, gavel SFX on verdict
- **Win sound** = satisfying coin chime + crowd cheer
- **Settlement** = lighter chime, no fanfare but still positive
- **Mistrial** = neutral gavel tap, no failure sound
- **Egg hatch** = build-up rattle → crack → reveal sting scaled to rarity (Supreme gets a full fanfare)
- **Level up** = punchy ascending tone

### Character Vibe

- **Base lawyer** = generic office worker type, blank slate for skins
- **Paralegal NPC** = friendly, slightly frantic assistant energy — think a cartoon intern
- **Manager** = smug but helpful, wears a nicer suit than the lawyers
- **Judge** = ancient, sleepy, dramatic — slams gavel with way too much enthusiasm

### World Layout Feel

- **Central hub** sits in the middle of the map — egg shop, skin shop, leaderboards, and the VIP lounge all live here
- **Two rows of firms** extend outward from the hub on each side — 4 to 6 firm plots per row, 8 to 12 total
- Each plot is a player's instanced firm — you own your slot, others can walk past and see in through the windows
- Firms closer to the hub feel more prestigious — top players visually dominate the map
- The layout creates a natural "main street" feel — players pass each other's firms walking to and from the hub
- Players can see each other's firm tier, lawyer skins, and VIP status from the outside — social flex built into the world

---

## 🧭 MVP Risk Fixes (v0.3)

This version fixes the biggest launch risks without killing the core idea.

### 1. Safer monetization

- **During the first release, coins are earned through gameplay only.** Do not sell coins for Robux, and do not let Robux convert into eggs or random skin rolls.
- Eggs use earned coins and show the complete outcome table, exact odds, and pity rules before the player rolls.
- Skins may keep real buffs, but buffed skins are earned through gameplay in the MVP. Any direct Robux skin purchase is cosmetic-only.
- MVP monetization is limited to cosmetic/status items and non-power convenience. No Robux product may increase payout, win chance, egg luck, or progression speed.
- Do not implement paid random items until the game has passed a policy/compliance review and a free-player economy test.

### 2. Smaller, testable MVP

Ship a vertical slice, not the whole empire:

- 1 player plot, 1 desk, 1 lawyer, 1 egg machine
- 3 client tiers, 3 skin rarities, and 3 case outcomes
- 1 courtroom minigame with three evidence-card sets
- 1 desk upgrade path and a small lawyer leveling curve
- No Manager, extra rooms, prestige, trading, leaderboards, offline earnings, daily streaks, social rewards, or large gamepass catalog in MVP

### 3. Make longer sessions come from play, not repetition

- Cases should resolve in roughly 30 seconds to 3 minutes.
- The courtroom challenge is optional and never punishes AFK players.
- Rotate the evidence cards and case prompts so the same 8-second interaction does not feel identical every time.
- A correct answer gives a small capped bonus; a wrong answer or timeout gives the normal payout with no penalty.
- Use lawyer levels, desk upgrades, skin collection, and short-term goals to create 15–30 minute sessions. Do not rely on aggressive timers or spend prompts.

### 4. Put hard limits around the economy

- Start with conservative caps: total payout multiplier ×2.5, win-chance bonus +12 percentage points, case-time reduction −30%, and XP multiplier ×2.0.
- Apply diminishing returns to duplicate buffs and enforce caps server-side.
- Simulate 1, 2, and 4 desks before adding more content. Test ordinary, lucky, and maximum-buff accounts.
- Initial tuning targets: first upgrade in 5–8 minutes, first egg in 8–12 minutes, and the next desk in 20–30 minutes. These are test targets, not promises.
- Defer offline earnings. If added later, cap them at 2 hours and 50% efficiency, with no extra RNG rolls while offline.

### 5. Treat saving and purchases as launch blockers

- Keep payouts, rolls, pity, leveling, and unlocks server-authoritative.
- Version the saved-data schema and write migrations before adding new properties.
- Use session locking, autosaves, safe shutdown saves, and idempotent purchase receipt handling.
- Never trust client-submitted payout amounts, roll results, pity counters, or ownership claims.

### 6. Remove avoidable moderation and legal risk

- Replace real-person names and recognizable likenesses with fictional parody clients.
- Keep the humor cartoonish and avoid claims that imply real misconduct by real people or brands.

### 7. Use a real launch gate

- First test the one-desk slice internally, then with a small consenting playtest group appropriate for the intended audience.
- Track first payout, first egg, repeat-case rate, session length, upgrade timing, and quit points.
- Do not add Robux monetization until players voluntarily repeat the core loop and the free economy is stable.

### Build order

1. Shared `Config` module and economy simulator
2. Server-authoritative desk → client → case → payout loop
3. One courtroom minigame and result screen
4. Lawyer leveling, one desk upgrade, and three earned skin rarities
5. Mobile pass, 8-player server test, and playtest fixes
6. Monetization review only after the free loop earns its place

---

## 📣 Discovery Plan (After the MVP Is Fun)

- Create three thumbnail concepts and three short game-page descriptions.
- Make short clips showing the first case, courtroom choice, egg hatch, and payout moment.
- Run a small private playtest before spending money on promotion.
- Track thumbnail click-through, first payout, first egg, repeat cases, session length, and quit points.
- Only scale promotion after the free loop shows healthy repeat play and stable retention.

---

## 🎯 Design Philosophy

- **Simple systems, expressive characters** — the mechanics are easy to learn, but lawyers have personalities, skills, and outfits that kids get attached to
- **Short feedback loops** — cases resolve in 30 seconds to 3 minutes, upgrades come fast early
- **Active + AFK friendly** — the game rewards watching but never punishes stepping away
