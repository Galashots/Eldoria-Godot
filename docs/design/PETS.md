# Pets (M4)

Locks the unlock/equip rules and pet roster's stats for the M4 pets slice (and its expansion-
backlog follow-ups), so future pet additions stay consistent. Deliberately a **tight vertical
slice** per `docs/design/NORTH_STAR.md`'s "cohesion over volume" pillar: follow-only AI, no pet
combat, ever. See `docs/ROADMAP.md` milestone 13 for the full M4 writeup.

## Unlock rules

Each pet is earned through a **different** existing accomplishment, so the roster payoff comes
from systems that already exist rather than one repeated gate:

- **Mossy** is granted automatically the moment the player completes **all four village quests**
  (Elder, Mira, Finn, Yarrow) — the exact same gate `_check_and_grant_tier1_armor()` already uses
  for Tier 1 armor (`docs/design/ARMOR_TIERS.md`), reused rather than reinvented.
  `GameState._check_and_grant_first_pet()` is called from `complete_quest()`, fires once
  (idempotent — owning `mossy` already short-circuits it), and is order-independent: whichever of
  the four quests happens to complete last is the one that triggers the grant.
- **Dewdrop** is granted the moment the player **defeats the Elder Slime mini-boss** — the same
  beat that already awards the "Elder Slime's Dewdrop" keepsake (`docs/design/EXPANSION_BACKLOG.md`
  "Second pet" slice). `GameState._check_and_grant_boss_pet()` is called from
  `ElderSlime._on_died()` right alongside `award_keepsake("elder_slime_dewdrop")`, fires once
  (idempotent — owning `dewdrop` already short-circuits it).

There is no buying, finding, or hatching path for a pet yet — these two grant moments are the
only ways to obtain one.

## Pet roster

| id | Label | Rarity | Max HP bonus | Unlock |
|----|-------|--------|---------------|--------|
| `mossy` | Mossy | Rare | +2 | Complete all four village quests |
| `dewdrop` | Dewdrop | Uncommon | +3 | Defeat the Elder Slime mini-boss |

Backed by `PetDefinition.gd` (mirroring `ItemDefinition`/`GearDefinition`) at
`data/pets/mossy.tres` and `data/pets/dewdrop.tres`. Both entries also carry
`sprite_frame1_path`/`sprite_frame2_path`, so `Pet.gd` can build the right 2-frame idle-bob
`SpriteFrames` for whichever pet is spawned without duplicating `scenes/pets/Pet.tscn` per
species — `Player.gd` sets `pet_id` on the spawned instance before adding it to the tree, and an
empty `pet_id` (or empty sprite paths) leaves the scene's baked-in SpriteFrames (Mossy's original
art) untouched, so Mossy needed no data migration.

Mossy's art is a mint/teal body with a leaf sprout, produced by `assets/sprites/pets/
gen_mossy.py` (see the "Character-sprite polish pass" in `docs/CURRENT_STATE.md`). Dewdrop's art
is a blue/water-family teardrop body with a pale glint highlight, hue-separated from both the
grass ramp and Mossy's teal, produced by `assets/sprites/pets/gen_dewdrop.py`. Both share the
same strong dark outline for readability against grass, the same 24x24 canvas, and the same
actor-pivot-at-center-bottom convention from `docs/design/VISUAL_CONTRACT.md`.

## Grant vs. manual equip — auto-equip differs per pet

- **Mossy's grant auto-equips** it and **auto-heals** the player by the bonus amount, so a newly
  widened max HP arrives full rather than leaving the player looking "damaged" for no reason the
  player caused. This was the only pet in the roster at the time, so there was no choice to make.
- **Dewdrop's grant does NOT auto-equip.** With two pets now in the roster, silently swapping
  whichever pet the player had equipped would take away a choice rather than add one — Dewdrop
  simply becomes available to equip from the character panel's Pets list, alongside Mossy if both
  are owned. No auto-heal on this grant either, matching the "grant doesn't force an equip" call.

## Equip / unequip semantics

- Granting a pet **auto-equips** it and **auto-heals** the player by the bonus amount, so a
  newly-widened max HP arrives full rather than leaving the player looking "damaged" for no
  reason the player caused.
- Manually equipping or unequipping via the character panel **never auto-heals**. Equipping
  requires ownership. Unequipping (`equip_pet("")`) always succeeds. Either action **clamps**
  `player_hp` down if it now exceeds the new effective max, but never heals it up.
- `GameState.get_effective_max_hp()` = `PLAYER_MAX_HP` + the equipped pet's `hp_bonus` (0 if
  no pet equipped). `take_player_damage()`, `heal_player_to_full()`, and the HUD's hp readout
  all read this instead of the old fixed max.
- Only one pet can be equipped at a time (single slot, matching the single weapon slot from
  M3's gear system).

## Follow AI

`Pet.gd` is a `CharacterBody2D`, spawned/despawned by `Player.gd` as a sibling node on
`GameState.pet_changed` (and on `_ready()` if a loaded save already has a pet equipped). It
has no `HealthComponent`, no hitbox/hurtbox, and cannot take or deal damage — pet combat is
explicitly out of scope (see below). This is shared by every pet in the roster, including
Dewdrop — only the sprite differs.

- Follow speed: 220 (faster than the player's 160, so it can catch up).
- Follow trigger: moves toward the player whenever farther than 24px away; stops moving once
  back inside that ring. No pathfinding — direct movement toward the player's position, same
  simplicity level as `MeadowSlime`'s chase state.

## Out of scope / deferred

Flagged here explicitly so future work doesn't assume any of this exists:

- Pet combat (no hitbox/hurtbox/HealthComponent on `Pet.gd`, for any pet in the roster).
- A large roster or acquisition paths beyond the two grant moments above (no buying/finding/
  hatching a pet).
- Evolution, leveling, or any pet progression beyond each pet's fixed `hp_bonus`.
- Multiple simultaneous pets / a pet party — single equip slot, same as the M3 weapon slot.

## Adding future pets

A new pet is additive: create a new `PetDefinition` `.tres` under `data/pets/` (id/label/
rarity/hp_bonus, plus `sprite_frame1_path`/`sprite_frame2_path` if it needs its own art) and add
it to `ContentDefinitions`' pet-definitions lookup (mirroring how `GearDefinition`s are
registered for the shop). Reuse `scenes/pets/Pet.tscn` and set `pet_id` on the spawned instance
(see `Player.gd`'s `_spawn_pet()`) rather than forking the scene — a new scene is only needed if
the pet needs genuinely different *behavior* (not just different art) from the shared follow AI.
Per-pet unlock gates are expected to differ (that's the point — see "Unlock rules" above), but
the equip/unequip semantics and follow-AI parameters above should stay the shared contract for
any additional pet unless a specific design reason argues otherwise.
