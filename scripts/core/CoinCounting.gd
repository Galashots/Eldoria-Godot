class_name CoinCounting
extends RefCounted

## Pure logic for the Merchant's optional "count out the coins" bonus beat
## (docs/design/EXPANSION_BACKLOG.md: "Count-out-the-coins at the Merchant"). Deliberately a
## static-function-only module with no scene/RNG dependency, mirroring
## MeadowSlime.rolls_bonus_coin()'s deterministic-test precedent. Denominations here are a
## small fixed set used only for this counting mini-game, separate from the game's real coin
## economy (which is a flat 1-unit currency) - the same "count out coins" framing Yarrow
## already used for its dime/nickel flavor text.

## The coin denominations offered in the counting UI, largest first (used by the fewest-coins
## check below). Kept small and simple for a Grade 2/5 audience: 1, 5, 10.
const DENOMINATIONS: Array[int] = [10, 5, 1]

## Grade 2 check: does the chosen set of coins add up to exactly the price? `chosen_coins` is
## an Array of ints, each a denomination value (duplicates allowed, e.g. [5, 5, 1]).
static func sum_matches_price(chosen_coins: Array, price: int) -> bool:
    var total := 0
    for coin in chosen_coins:
        total += int(coin)
    return total == price

## Grade 5 check: does the chosen set of coins add up to exactly the price AND use the fewest
## possible coins from `denominations` (greedy-optimal count, since these denominations are a
## canonical system where greedy always finds the minimum)?
static func is_fewest_coins(chosen_coins: Array, price: int, denominations: Array[int] = DENOMINATIONS) -> bool:
    if not sum_matches_price(chosen_coins, price):
        return false
    return chosen_coins.size() == minimum_coin_count(price, denominations)

## The minimum number of coins (from the given denominations, largest first) needed to make
## `amount` exactly, via the standard greedy algorithm. Returns 0 for a non-positive amount.
static func minimum_coin_count(amount: int, denominations: Array[int] = DENOMINATIONS) -> int:
    if amount <= 0:
        return 0

    var remaining := amount
    var count := 0
    for denomination in denominations:
        if denomination <= 0:
            continue
        count += remaining / denomination
        remaining = remaining % denomination

    return count
