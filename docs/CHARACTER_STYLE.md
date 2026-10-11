# Character style — "brick" (2026-10-11)

The look for every character: lawyers, clients and the Judge. It's taken from the characters in the user's
reference recording of a "steal an egg"-style pet game, copying the **style only**: none of its characters, names
or branding. Approved by the user on 2026-10-11, with Rookie Lawyer and Neighbor Dave as the test characters.

Built with `tools/brick/BrickKit.lua` (in Studio as `ServerStorage.BrickKit`). Each character has a builder in
`tools/brick/<Id>.lua`.

## What the reference does (characters only)
- **Proportions:** baby pets are chibi (the head is half the height or more). Big pets have close-to-real animal
  proportions with thick square-post legs and slightly oversized heads.
- **Shapes:** everything is boxes, bricks and plates. Curves come from stepped or tilted bricks, plus a few wedges
  (ears). No balls or cylinders.
- **Surface:** studs on every face of every brick, matching the world.
- **Face:** big flat white square eyes with a square black pupil, often in a dark rim, and no shine dot. A black
  block nose. Mostly no mouth.
- **Colour:** natural colours at medium saturation, 2–3 per character plus the eye white and black. Flat colours,
  with no gradients or painted shading. Characters stand out by value (dark or light against bright ground).
- **No outlines and no textures** other than studs. Detail comes from the number of bricks.
- **Animation:** limbs swing stiffly as whole blocks with no knee bends, and the body stays level. Timing, idles
  and expressions weren't visible in the reference.
- The reference has no styled humans (players are normal avatars), so the people rules below are our translation.

## Rules every character follows
**Body frame (people)**, in studs:

| Part | Size |
|---|---|
| Legs | 0.9 × 1.3 × 0.9 (the shoe is the bottom 0.3) |
| Torso | 2.0 × 1.5 × 1.1 |
| Arms | 0.7 × 1.45 × 0.8, including a 0.42 hand block |
| Head | 2.0 × 1.8 × 1.8, sitting straight on the torso |

- The total is about 4.6 tall plus hair (about 5), so characters still fit desks and chairs.
- The head is about 38% of the height.
- Animal and food lawyers **stay human-shaped** (user's call: up to us). They need that to sit at desks and to use
  Shared.Puppet's walk, sit and court poses. Their heads carry the theme.

**Bricks**
- `Kit:brick` is Plastic with the `MaterialService.BrickStuds` MaterialVariant. That variant uses a normal map
  (`art/materials/stud_normal.png`, made by `tools/stud_normal.py`, asset 90354792169791) with
  `StudsPerTile = 0.5`, which puts one stud every half stud.
- Roblox's own `SurfaceType.Studs` are 1 stud wide. That's twice too coarse on a 2-stud head: two big studs land
  on the cheeks and read as eye bags. The variant costs nothing per part.
- Studs go on every face (user's call).
- `Kit:plate` is smooth, for the face, ties, lapels, trims and buttons.
- No Metal, Glass, Foil or Reflectance (the user found things too shiny). Neon (`Kit:glow`) is only for small
  Legendary accents.

**Face kit**
- **Eyes:** a white plate (0.5 × 0.56) in a thin dark rim (`#1C1C20`, 0.03 per side; thicker reads as glasses),
  with a square pupil `#0F0F12`.
- **Mood** comes from the pupil position (`look`, `inward`), the brow tilt and `lid` (sleepy).
- **Mouths stay** (user's call): `flat`, `smile`, `grin` (with teeth and tongue) or `open` (OBJECTION!).
- **Nose:** a skin-coloured block for people, `#24242C` for animals.

**Colours**
- 2–3 main colours plus at most one accent. Every character needs one dark and one light main colour.
- Use `#F2EFE8` instead of pure white and `#24242C` instead of pure black on bodies.
- Skin tones: `#FFD3A8`, `#E8B087`, `#C68A5E`, `#8D5A3B`, `#5C3A26`.

**Rarity ladder** (lawyers and clients; body size never changes)

| | Common / Tier 1 | Uncommon / T2 | Rare / T3 | Epic / T4 (clients) | Legendary / T5 |
|---|---|---|---|---|---|
| Colour | 2 main | + 1 accent | + blue trim `#3CA0FF` | + purple trim `#B45AFF` | + gold trim `#FFC828` / `#D99A10`, plus 1–2 Neon bricks |
| Shape | plain | + 1 small accessory | + 1 standout feature (hat, hair, prop or oversized head) | + a bigger one | + an oversized signature feature (cape, crown, giant prop) |
| Bricks | ~35 | ~45 | ~60 | ~70 | ~80 |

Lawyers keep their existing sparkle and gold auras (`Shared.Effects`) and the merge-star Gold and Rainbow auras.

**Roblox build notes**
- **Custom Models of Parts:** no R15 or Humanoid, no MeshParts, no decal faces. Part names follow Shared.Puppet,
  which sorts by name first, then by position:
  - `Head` is the head block **only**, because Puppet takes the neck height from it.
  - `HeadDetail` is the face, hair and hats.
  - `UpperTorso`, `Left/RightUpperArm` and `Left/RightUpperLeg` are the body, and every extra brick is named after
    its limb.
  - Clients also get an invisible `HumanoidRootPart` (`Kit:finishClient`).
- **Installing:**
  - `Kit:installLawyer(note)` installs to `ReplicatedStorage.SkinModels.<Id>` and keeps the old model as
    `ServerStorage.RetiredSkinModels.<Id>_preBrick`.
  - `Kit:installClient(note)` installs to `ServerStorage.Templates.Clients.<Id>` and keeps the old one as
    `ServerStorage.RetiredClients.<Id>_v3`.
  - To undo, move the kept model back.
- **Part budget:** under 80 parts per character. A phone may show 20 offices plus a waiting room.

## Character sheets (approved examples)
**Rookie Lawyer** — the starting lawyer (Common, Briefcase). **Built.**
- **Concept:** a first-day lawyer in a hand-me-down suit one size too big.
- **Colours:**

  | Part | Hex |
  |---|---|
  | Suit | `#2C3E60` |
  | Lapels | `#23324F` |
  | Pants | `#202026` |
  | Shirt | `#F2EFE8` |
  | Tie | `#C82832` |
  | Skin | `#FFD3A8` |
  | Hair | `#5A3A22` |
  | Briefcase | `#7A4A24` with a `#FFC828` clasp |
- **Shape:** the jacket hem hangs past the hip, the sleeves cover half the hand, and a side-part swoop plus one
  cowlick brick.
- **Face:** pupils up and in, brows raised, a small flat mouth.

**Hamster Hustle** — Common, Pet. The template for animal-head lawyers.
- **Concept:** a hyper hamster paralegal with paperwork stuffed in its cheeks.
- **Head:** a chibi hamster head 2.2 wide, cheek-pouch bricks, stepped ears and paper corners poking out.
- **Colours:** fur `#E6AA64`, muzzle `#F5E6C8`, inner ear `#F29AA0`, suit `#A03C3C`, pants `#803030`.
- **Face:** rimmed eyes centred, a black nose, two tooth plates and no mouth. A pencil behind the ear.

**Bow Tie Barrister** — Uncommon, Briefcase.
- **Concept:** a showman who argues like it's a stage show.
- **Shape:** a top hat (+1.1 tall), coat tails and a big wedge bow tie.
- **Colours:** suit `#8246C8`, lapels `#5A2E96`, pants `#37235A`, bow tie, hat band and pocket square `#FF50AA`
  (the accent), hat `#2D233C`, skin `#C68A5E`.
- **Face:** one brow up and a smirk.

**Donut Defender** — Rare, Food. The template for food-head lawyers.
- **Shape:** the head is an upright stepped ring 2.6 wide with a real hole through it.
- **Colours:** dough `#DCA05A`, icing and suit `#FF8CBE`, pants `#CC7098`, 8–10 sprinkles
  (`#3CC8FF` / `#FFE150` / `#5CDB4A`).
- **Face:** sly sideways pupils and a small open smile. Blue cuff trim plus the sparkle aura.

**Star Judge** — Legendary, Space.
- **Shape:** a five-point stepped-brick star head 3 wide, and a robe that widens in steps.
- **Colours:** star `#FFE150` with `#E0B420` step edges, robe `#141432`, gold hem `#FFC828`, collar `#F2EFE8`, two
  Neon star tips `#FFF4A0`.
- **Face:** calm half-lidded eyes. A gold gavel.

**Clients**, one per tier
- **Neighbor Dave (T1). Built.**
  - **Colours:** polo `#4F95DC`, collar `#3672B0`, khaki shorts `#C9A66B`, striped tube socks `#F6F6F2` in sandals
    `#7A4A24`, a red cap `#D93B3B`, skin `#F1C49A`.
  - **Face and prop:** a brick mustache over a grin, and a spatula.
- **Rosa the Baker (T2):** chef whites, apron `#FBE6D6`, accent scarf `#D94A5A`, skin `#C68A5E`, a flour-smudge
  plate and a rolling pin.
- **Baron von Banana (T3):** a monkey, fur `#7A4A2A`, face `#E2BF92`, vest `#6A2A8A`, a top hat with a banana band
  `#FFD23C`, a peel prop and blue trim.
- **Retired CEO (T4):** velvet jacket `#7A1A2E`, purple lapel trim, white tufts and a brick mustache, a gold watch
  chain and a gold-topped cane.
- **Chef Mega (T5):** double-breasted whites, gold cuffs, scarf `#D92A3A`, skin `#8D5A3B`, a 1.6-stud stepped
  toque, and a gold ladle with a Neon tip.

**The Judge** (courtroom)
- **Concept:** dozy; wakes up only to shout "Order!"
- **Shape:** a wig of rows of small white bricks `#ECE6DA`, robe `#24242C`, collar `#F2EFE8`, skin `#E8B087`.
- **Face:** two states. Sleepy has the lids half down; awake has the lids up and the mouth open. Reading glasses and
  a wooden gavel `#8A5A32`.

## How the rest of the cast follows

| Group | How many | Template |
|---|---|---|
| Briefcase egg people | 13 | The body frame in suits. Personality comes from hair, a hat or a prop. |
| Brainrot | 8 | Each keeps its own body plan (they aren't human-shaped), rebuilt in studded bricks with the eye kit. |
| Pet and Ocean | 16 | The body frame with a chibi animal head. Fur and scales are bricks sticking out; whiskers and fins are plates. |
| Food | 8 | The body frame with a food-object head as the silhouette. |
| Space | 8 | Helmets, robot heads and aliens. Neon only on Legendary accents. |
| Clients | 44 | The body frame. One big prop or hat tells the job; the ladder by tier. |

The four lawyers that riffed on real creators were renamed on 2026-10-11, keeping their saved Ids:

| Id | Old name | New name |
|---|---|---|
| IShowSued | IShowSued | Livestream Litigator |
| KaiSueNat | Kai Sue-nat | Selfie Counsel |
| KhabyClaim | Khaby Claim | Obvious Advocate |
| BensonBond | Benson Bond | Mic Drop Attorney |

Their designs stay original, with no likeness.
