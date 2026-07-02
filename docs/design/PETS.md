# Pets (M4)

Locks the unlock/equip rules and first pet's stats for the M4 pets slice, so future pet
additions stay consistent. This is deliberately a **tight vertical slice** per
`docs/design/NORTH_STAR.md`'s "cohesion over volume" pillar: one species, follow-only AI, no
pet combat. See `docs/ROADMAP.md` milestone 13 for the full writeup.

## Unlock rule

A pet is granted automatically the moment the player completes **all four village quests**
(Elder, Mira, Finn, Yarrow) — the exact same gate `_check_and_grant_tier1_armor()` already
uses for Tier 1 armor (`docs/design/ARMOR_TIERS.md`), reused rather than reinvented.
`GameState._check_and_grant_first_pet()` is called from `complete_quest()`, fires once
(idempotent — owning a pet already short-circuits it), and is order-independent: whichever of
the four quests happens to complete last is the one that triggers the grant.

There is no buying, finding, or hatching path for a pet yet — the quest-completion grant is
the only way to obtain one.

## Mossy (first and only pet)

| id | Label | Rarity | Max HP bonus |
|----|-------|--------|---------------|
| `mossy` | Mossy | Rare | +2 |

Backed by `PetDefinition.gd` (mirroring `ItemDefinition`/`GearDefinition`) at
`data/pets/mossy.tres`. Art is a placeholder polygon (a mint/teal blob with a leaf and eyes)
in `scenes/pets/Pet.tscn` — not production art.

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
explicitly out of scope (see below).

- Follow speed: 220 (faster than the player's 160, so it can catch up).
- Follow trigger: moves toward the player whenever farther than 24px away; stops moving once
  back inside that ring. No pathfinding — direct movement toward the player's position, same
  simplicity level as `MeadowSlime`'s chase state.

## Out of scope / deferred

Flagged here explicitly so future work doesn't assume any of this exists:

- Pet combat (no hitbox/hurtbox/HealthComponent on `Pet.gd`).
- Multiple species or a real roster — Mossy is the only pet.
- Buying pets, or any acquisition path other than the all-four-quests grant.
- Evolution, leveling, or any pet progression beyond its fixed `hp_bonus`.
- Real (non-placeholder) art.
- Multiple simultaneous pets / a pet party.

## Adding future pets

A new pet is additive: create a new `PetDefinition` `.tres` under `data/pets/` (id/label/
rarity/hp_bonus) and add it to `ContentDefinitions`' pet-definitions lookup (mirroring how
`GearDefinition`s are registered for the shop), plus a scene if it needs distinct art/
behavior from `Pet.tscn`. The unlock gate, equip/unequip semantics, and follow-AI parameters
above should stay the shared contract for any additional pet unless a specific design reason
argues otherwise.
