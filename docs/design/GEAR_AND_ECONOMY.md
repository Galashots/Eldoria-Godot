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
| Legendary | gold | the aspirational pinnacle — the top of the shop |

Colors live in `ContentDefinitions.RARITY_COLORS` and are applied to gear labels in both the
shop and the character panel's owned-weapons list.

## Weapons (current roster)

| id | Label | Rarity | Damage bonus | Price |
|----|-------|--------|--------------|-------|
| `worn_dagger` | Worn Dagger | Common | +1 | 3 coins |
| `iron_sword` | Iron Sword | Uncommon | +2 | 8 coins |
| `oakheart_blade` | Oakheart Blade | Rare | +3 | 20 coins |
| `dawnbringer_blade` | Dawnbringer Blade | Legendary | +4 | 30 coins |

Each is a `GearDefinition` `.tres` under `data/gear/`. Damage bonus adds to the player's
`attack_base_damage` before the existing combat-streak multiplier is applied (see
`Player._swing_attack()`), so gear and the math-question streak stack multiplicatively.

## Economy

- Meadow Slimes drop exactly 1 coin on death (`MeadowSlime.gd`'s `coin_drop_value`), tying
  the shop directly to the M2 combat loop rather than to quest rewards.
- Coins are spent at the single `Merchant` NPC's `ShopUI` panel. No sell-back exists yet.
- Weapons are permanent once bought (`GameState.owned_gear`); equipping is a free, instant
  swap via the character panel, not a scarce resource.

## Bonus drop rule

On top of the guaranteed 1-coin drop above, Meadow Slime rolls a small **additive-only**
bonus chance (`MeadowSlime.gd`'s exported `bonus_coin_chance`, default 0.12 / 12%, in the
~10-15% range suggested when this was designed) for exactly one extra coin. This never
replaces or reduces the guaranteed drop — it can only ever add a second coin on top,
honoring the bonus-only/non-punitive rule that governs every reward system in this project
(`docs/design/NORTH_STAR.md`). The roll itself is a pure function,
`MeadowSlime.rolls_bonus_coin(chance, roll)`, so it's covered deterministically by the test
suite (`tests/game_state_tests.gd`) without depending on real engine RNG. This is
deliberately scoped to one exported var on `MeadowSlime.gd` rather than a generic loot-table
framework — revisit that shape only once a second enemy needs the same behavior.

## Deferred (not in M3, flag before building)

- Armor as buyable rarity gear (armor stays the existing quest-granted tier system).
- Sell-back, multi-slot loadouts (rings, trinkets), consumables/potions.
- Real coin & gear icon art (currently placeholder polygons, matching the bootstrap-tileset
  precedent in `docs/design/VISUAL_CONTRACT.md`).
- Gear stat axes beyond `damage_bonus` (defense, max hp, move speed).

## Faucet depth — flagged for a future economy slice

Adding the Legendary Dawnbringer Blade (+4, 30 coins) as the aspirational top-of-shop item
surfaced the real pacing bottleneck: the **coin faucet is thin and non-repeatable within a
session.** The M1 zone has exactly **3 Meadow Slimes, and they do not respawn** (they
`queue_free()` on death), so a fresh session yields only ~3 coins from combat. Coins persist
across sessions, so the shop roster is a *cumulative* goal — but no top-tier item (not even
the existing 20-coin Oakheart Blade) is reachable "within one session," and Dawnbringer at 30
is deliberately priced as a multi-session pinnacle with only a modest 20→30 jump so it does
**not** worsen the grind (per the anti-"pinch point"/anti-scarcity research in
`docs/design/RESEARCH_NOTES.md` §6.2).

The natural next economy slice is therefore on the **faucet** side, not another sink: a small,
*repeatable* coin source (e.g. a modest slime respawn cadence, or a second tiny faucet) so the
existing roster stays reachable without feeling grindy. Left for the architect to prioritize;
Dawnbringer is intentionally the last *sink* added until the faucet is widened.
