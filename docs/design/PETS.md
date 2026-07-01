# Pets (M4)

Locks the first pet's name, rarity, stat, and unlock rule for M4, so future roster additions
stay consistent. Deliberately a **tight vertical slice** per `docs/design/NORTH_STAR.md`'s
"cohesion over volume" pillar: one pet species, follow-only (no combat), one passive stat.
See `docs/ROADMAP.md` milestone 13 for the full writeup.

## Unlock rule

Completing all 4 village quests (Elder, Mira, Finn, Yarrow) grants the first pet — the same
gate `GameState._check_and_grant_tier1_armor()` already uses for Tier 1 armor
(`GameState._check_and_grant_first_pet()`). The pet is **auto-equipped** the moment it's
granted (the reward should be immediately visible), and the player is healed to the new
bonus-inclusive max hp.

## Ownership vs. equip

Pets use the same `owned_X` / `equipped_X` shape M3 built for gear
(`owned_gear`/`equipped_weapon`) rather than a single on/off flag — `GameState.owned_pets`
(ids ever unlocked) and `GameState.equipped_pet` (empty = none active). Only one pet can be
equipped at a time. This makes room for a future roster without a data-model change, and
gives "equip" real meaning today: the character panel's Pets section lets the player toggle
the one pet on/off, swapping its stat bonus in and out live.

## Current roster

| id | Label | Rarity | Stat bonus |
|----|-------|--------|------------|
| `mossy_sprite` | Mossy the Sprite | Rare | +2 Max HP |

Each is a `PetDefinition` `.tres` under `data/pets/`, mirroring `GearDefinition`. Pets are
intentionally rarer than gear (a single quest-gated grant vs. a purchasable roster) and boost
a different stat than gear (max HP vs. attack damage), so the two systems complement rather
than duplicate each other.

## Follow behavior

The pet has no combat, no wander/idle states, and no aggro radius — it only ever moves
toward the player once farther than `stop_distance` (24px), reusing the exact chase-state
movement already proven in `MeadowSlime.gd`. It spawns/despawns dynamically as a sibling of
the player whenever `GameState.equipped_pet` changes (including on load, if a save already
has one equipped) rather than living as a static node in `Main.tscn`.

## Deferred (not in M4, flag before building)

- Pet combat/AI (its own HealthComponent/HitboxComponent, attacking nearby enemies).
- A second (or third) pet species / a choice UI at unlock time.
- Buying pets from the Merchant; pet rarity as a purchase mechanic.
- Evolution, leveling, or any pet stat growth over time.
- Real pet art (currently a placeholder colored polygon, matching the bootstrap-placeholder
  precedent used for every prior NPC/monster/item before real art).
