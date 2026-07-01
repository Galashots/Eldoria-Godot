# Gear & Economy (M3)

Locks the rarity list and coin/price scale for the M3 gear/economy slice, so future gear
additions stay consistent. This is deliberately a **tight vertical slice** per
`docs/design/NORTH_STAR.md`'s "cohesion over volume" pillar: weapons only (one gear slot),
one vendor, manual equip. See `docs/ROADMAP.md` milestone 12 for the full writeup.

## Rarity

| Rarity | Color | Meaning |
|--------|-------|---------|
| Common | white | starter-tier, cheap |
| Uncommon | green | a real upgrade, modest cost |
| Rare | blue | a meaningful cost, a meaningful upgrade |

Colors live in `ContentDefinitions.RARITY_COLORS` and are applied to gear labels in both the
shop and the character panel's owned-weapons list.

## Weapons (current roster)

| id | Label | Rarity | Damage bonus | Price |
|----|-------|--------|--------------|-------|
| `worn_dagger` | Worn Dagger | Common | +1 | 3 coins |
| `iron_sword` | Iron Sword | Uncommon | +2 | 8 coins |
| `oakheart_blade` | Oakheart Blade | Rare | +3 | 20 coins |

Each is a `GearDefinition` `.tres` under `data/gear/`. Damage bonus adds to the player's
`attack_base_damage` before the existing combat-streak multiplier is applied (see
`Player._swing_attack()`), so gear and the math-question streak stack multiplicatively.

## Economy

- Meadow Slimes drop exactly 1 coin on death (`MeadowSlime.gd`'s `coin_drop_value`), tying
  the shop directly to the M2 combat loop rather than to quest rewards.
- Coins are spent at the single `Merchant` NPC's `ShopUI` panel. No sell-back exists yet.
- Weapons are permanent once bought (`GameState.owned_gear`); equipping is a free, instant
  swap via the character panel, not a scarce resource.

## Deferred (not in M3, flag before building)

- Armor as buyable rarity gear (armor stays the existing quest-granted tier system).
- Sell-back, multi-slot loadouts (rings, trinkets), consumables/potions.
- Real coin & gear icon art (currently placeholder polygons, matching the bootstrap-tileset
  precedent in `docs/design/VISUAL_CONTRACT.md`).
- Gear stat axes beyond `damage_bonus` (defense, max hp, move speed).
