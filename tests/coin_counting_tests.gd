extends RefCounted

## Coin-counting bonus beat tests. Isolated file (registered in tests/test_runner.gd),
## mirroring tests/campfire_tests.gd's shape for testing a pure static-function-only script
## preloaded directly, with no scene-tree/RNG dependency - CoinCounting has no engine calls at
## all, so every case here is deterministic.

const CoinCounting := preload("res://scripts/core/CoinCounting.gd")

func test_sum_matches_price_true_for_exact_total() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, CoinCounting.sum_matches_price([5, 1, 1, 1], 8),
        "expected [5,1,1,1] to sum to 8")
    _check(failures, CoinCounting.sum_matches_price([10], 10),
        "expected a single 10 coin to sum to 10")

    return {"ok": failures.is_empty(), "failures": failures}

func test_sum_matches_price_false_for_wrong_total() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, not CoinCounting.sum_matches_price([5, 1], 8),
        "expected [5,1] (=6) to not sum to 8")
    _check(failures, not CoinCounting.sum_matches_price([10, 1], 8),
        "expected an over-total to not sum to 8")

    return {"ok": failures.is_empty(), "failures": failures}

func test_sum_matches_price_empty_selection_only_matches_zero_price() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, CoinCounting.sum_matches_price([], 0),
        "expected an empty selection to sum to 0")
    _check(failures, not CoinCounting.sum_matches_price([], 3),
        "expected an empty selection to not sum to a positive price")

    return {"ok": failures.is_empty(), "failures": failures}

func test_minimum_coin_count_uses_greedy_denominations() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, CoinCounting.minimum_coin_count(8) == 4,
        "expected 8 to need 4 coins (5+1+1+1), got %d" % CoinCounting.minimum_coin_count(8))
    _check(failures, CoinCounting.minimum_coin_count(20) == 2,
        "expected 20 to need 2 coins (10+10), got %d" % CoinCounting.minimum_coin_count(20))
    _check(failures, CoinCounting.minimum_coin_count(3) == 3,
        "expected 3 to need 3 coins (1+1+1), got %d" % CoinCounting.minimum_coin_count(3))

    return {"ok": failures.is_empty(), "failures": failures}

func test_minimum_coin_count_non_positive_amount_is_zero() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, CoinCounting.minimum_coin_count(0) == 0,
        "expected an amount of 0 to need 0 coins")
    _check(failures, CoinCounting.minimum_coin_count(-5) == 0,
        "expected a negative amount to need 0 coins")

    return {"ok": failures.is_empty(), "failures": failures}

func test_is_fewest_coins_true_for_optimal_selection() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, CoinCounting.is_fewest_coins([5, 1, 1, 1], 8),
        "expected [5,1,1,1] to be the fewest-coins solution for 8")
    _check(failures, CoinCounting.is_fewest_coins([10, 10], 20),
        "expected [10,10] to be the fewest-coins solution for 20")

    return {"ok": failures.is_empty(), "failures": failures}

func test_is_fewest_coins_false_for_correct_total_but_extra_coins() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, not CoinCounting.is_fewest_coins([1, 1, 1, 1, 1, 1, 1, 1], 8),
        "expected eight 1-coins to sum correctly but not be the fewest-coins solution for 8")

    return {"ok": failures.is_empty(), "failures": failures}

func test_is_fewest_coins_false_when_total_is_wrong() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, not CoinCounting.is_fewest_coins([5, 1], 8),
        "expected an incorrect total to also fail the fewest-coins check")

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
