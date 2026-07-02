extends Node

signal item_added(item_id: String, amount: int)
signal elder_quest_changed
signal profile_changed(profile_id: String)
signal quest_changed(quest_id: String, state: String)
signal armor_equipped(tier: int)
signal player_damaged(current_hp: int, max_hp: int)
signal player_died
signal combat_streak_changed(streak: int, multiplier: float)
signal coins_changed(coins: int)
signal gear_changed
signal pet_unlocked(pet_id: String)
signal pet_changed
signal creature_met(creature_id: String)
signal keepsake_awarded(keepsake_id: String)

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 3

const PLAYER_MAX_HP := 5

# Combat streak/multiplier: a correct combat math question bumps the streak (capped),
# giving a temporary damage multiplier that decays over time if no further correct
# answers land. Deliberately NOT persisted to save_game() - it's a moment-to-moment
# combat feel mechanic tied to the current play session, not saved progress.
const COMBAT_STREAK_MAX := 3
const COMBAT_STREAK_DECAY_SEC := 8.0
const COMBAT_MULTIPLIER_PER_STACK := 0.5
const COMBAT_QUESTION_COOLDOWN_SEC := 12.0
# Brief immunity after the player takes a hit, so standing in continuous contact with an
# enemy doesn't deal damage every physics frame.
const PLAYER_HIT_COOLDOWN_SEC := 0.5

const QUEST_ELDER_GOLDEN_STAR := "elder_golden_star"
const QUEST_MIRA_GLOWING_HERB := "mira_glowing_herb"
const QUEST_FINN_SHIMMERING_ORE := "finn_shimmering_ore"
const QUEST_YARROW_SILVERLEAF := "yarrow_silverleaf"

const QUEST_NOT_STARTED := "not_started"
const QUEST_STARTED := "started"
const QUEST_READY_TO_TURN_IN := "ready_to_turn_in"
const QUEST_LEARNING_CHECK := "learning_check"
const QUEST_COMPLETED := "completed"

var selected_profile: String = ""
var player_hp: int = PLAYER_MAX_HP
var collected_items: Dictionary = {}
var quest_states: Dictionary = {
    QUEST_ELDER_GOLDEN_STAR: QUEST_NOT_STARTED,
    QUEST_MIRA_GLOWING_HERB: QUEST_NOT_STARTED,
    QUEST_FINN_SHIMMERING_ORE: QUEST_NOT_STARTED,
    QUEST_YARROW_SILVERLEAF: QUEST_NOT_STARTED,
}
var quest_bonuses: Dictionary = {}
var equipped_armor_tier: int = 0
var coins: int = 0
var owned_gear: Array[String] = []
var equipped_weapon: String = ""
var owned_pets: Array[String] = []
var equipped_pet: String = ""
# "Creatures met" codex: permanent world-knowledge earned from combat. Maps creature_id -> true;
# a Dictionary (not an Array) mirrors collected_items' shape and gives O(1) has_met_creature().
var creatures_met: Dictionary = {}
# Boss keepsakes: permanent trophies earned from mini-boss fights. Maps keepsake_id -> true,
# mirroring creatures_met's shape exactly - same idempotent record/has pair, same
# save/load/reset handling, same bonus-only "can only gain, never lose" rule.
var keepsakes: Dictionary = {}

var elder_quest_started: bool = false
var elder_quest_completed: bool = false

# Runtime-only combat state (not persisted - see the constants above).
var combat_streak: int = 0
var _time_since_last_correct_answer: float = 0.0
var _player_hit_cooldown_remaining: float = 0.0
var _combat_question_cooldown_remaining: float = 0.0

func _ready() -> void:
    profile_changed.connect(_on_profile_changed_autosave)
    quest_changed.connect(_on_quest_changed_autosave)
    item_added.connect(_on_item_added_autosave)
    armor_equipped.connect(_on_armor_equipped_autosave)
    coins_changed.connect(_on_coins_changed_autosave)
    gear_changed.connect(_on_gear_changed_autosave)
    pet_changed.connect(_on_pet_changed_autosave)
    creature_met.connect(_on_creature_met_autosave)
    keepsake_awarded.connect(_on_keepsake_awarded_autosave)
    load_game()

func _process(delta: float) -> void:
    if _player_hit_cooldown_remaining > 0.0:
        _player_hit_cooldown_remaining = maxf(0.0, _player_hit_cooldown_remaining - delta)
    if _combat_question_cooldown_remaining > 0.0:
        _combat_question_cooldown_remaining = maxf(0.0, _combat_question_cooldown_remaining - delta)

    if combat_streak > 0:
        _time_since_last_correct_answer += delta
        if _time_since_last_correct_answer >= COMBAT_STREAK_DECAY_SEC:
            _time_since_last_correct_answer = 0.0
            combat_streak -= 1
            combat_streak_changed.emit(combat_streak, get_combat_multiplier())

func set_selected_profile(profile_id: String) -> void:
    selected_profile = profile_id
    profile_changed.emit(profile_id)

func add_item(item_id: String, amount: int = 1) -> void:
    collected_items[item_id] = collected_items.get(item_id, 0) + amount
    item_added.emit(item_id, amount)

    if item_id == "golden_star" and get_quest_state(QUEST_ELDER_GOLDEN_STAR) == QUEST_STARTED:
        mark_quest_ready_to_turn_in(QUEST_ELDER_GOLDEN_STAR)
    elif item_id == "glowing_herb" and get_quest_state(QUEST_MIRA_GLOWING_HERB) == QUEST_STARTED:
        mark_quest_ready_to_turn_in(QUEST_MIRA_GLOWING_HERB)
    elif item_id == "shimmering_ore" and get_quest_state(QUEST_FINN_SHIMMERING_ORE) == QUEST_STARTED:
        mark_quest_ready_to_turn_in(QUEST_FINN_SHIMMERING_ORE)
    elif item_id == "silverleaf" and get_quest_state(QUEST_YARROW_SILVERLEAF) == QUEST_STARTED:
        mark_quest_ready_to_turn_in(QUEST_YARROW_SILVERLEAF)

func has_item(item_id: String) -> bool:
    return collected_items.get(item_id, 0) > 0

func get_quest_state(quest_id: String) -> String:
    return quest_states.get(quest_id, QUEST_NOT_STARTED)

func is_quest_state(quest_id: String, state: String) -> bool:
    return get_quest_state(quest_id) == state

func set_quest_state(quest_id: String, state: String) -> void:
    if get_quest_state(quest_id) == state:
        return

    quest_states[quest_id] = state
    _refresh_elder_quest_flags()
    quest_changed.emit(quest_id, state)

    if quest_id == QUEST_ELDER_GOLDEN_STAR:
        elder_quest_changed.emit()

func start_quest(quest_id: String) -> void:
    if get_quest_state(quest_id) != QUEST_NOT_STARTED:
        return

    set_quest_state(quest_id, QUEST_STARTED)

func mark_quest_ready_to_turn_in(quest_id: String) -> void:
    var state := get_quest_state(quest_id)
    if state == QUEST_COMPLETED or state == QUEST_LEARNING_CHECK:
        return

    set_quest_state(quest_id, QUEST_READY_TO_TURN_IN)

func start_learning_check(quest_id: String) -> void:
    if get_quest_state(quest_id) == QUEST_COMPLETED:
        return

    set_quest_state(quest_id, QUEST_LEARNING_CHECK)

func complete_quest(quest_id: String) -> void:
    if get_quest_state(quest_id) == QUEST_COMPLETED:
        return

    set_quest_state(quest_id, QUEST_COMPLETED)
    _check_and_grant_tier1_armor()
    _check_and_grant_first_pet()

func award_quest_bonus(quest_id: String) -> void:
    quest_bonuses[quest_id] = true

func has_quest_bonus(quest_id: String) -> bool:
    return quest_bonuses.get(quest_id, false)

func start_elder_quest() -> void:
    start_quest(QUEST_ELDER_GOLDEN_STAR)

func mark_elder_quest_ready_to_turn_in() -> void:
    mark_quest_ready_to_turn_in(QUEST_ELDER_GOLDEN_STAR)

func start_elder_learning_check() -> void:
    start_learning_check(QUEST_ELDER_GOLDEN_STAR)

func complete_elder_quest() -> void:
    if not has_item("golden_star"):
        return

    complete_quest(QUEST_ELDER_GOLDEN_STAR)

func _refresh_elder_quest_flags() -> void:
    var state := get_quest_state(QUEST_ELDER_GOLDEN_STAR)
    elder_quest_started = state != QUEST_NOT_STARTED
    elder_quest_completed = state == QUEST_COMPLETED

func _check_and_grant_tier1_armor() -> void:
    if equipped_armor_tier > 0:
        return

    # Extended to include Yarrow's quest when it was added, so armor still means "you've
    # finished every quest the village has to offer" rather than freezing at the original
    # three. Safe for existing saves: this only re-evaluates while armor is still ungranted
    # (the early return above), so a save that already has armor keeps it regardless.
    var required_quests := [QUEST_ELDER_GOLDEN_STAR, QUEST_MIRA_GLOWING_HERB, QUEST_FINN_SHIMMERING_ORE, QUEST_YARROW_SILVERLEAF]
    for quest_id in required_quests:
        if get_quest_state(quest_id) != QUEST_COMPLETED:
            return

    equipped_armor_tier = 1
    armor_equipped.emit(1)

func add_coins(amount: int) -> void:
    if amount <= 0:
        return
    coins += amount
    coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
    if amount <= 0 or amount > coins:
        return false
    coins -= amount
    coins_changed.emit(coins)
    return true

func owns_gear(gear_id: String) -> bool:
    return owned_gear.has(gear_id)

func buy_gear(gear_id: String) -> bool:
    if owns_gear(gear_id):
        return false

    var gear := ContentDefinitions.get_gear(gear_id)
    if gear == null:
        return false

    if not spend_coins(gear.price):
        return false

    owned_gear.append(gear_id)
    gear_changed.emit()
    return true

func equip_weapon(gear_id: String) -> void:
    if gear_id != "" and not owns_gear(gear_id):
        return

    equipped_weapon = gear_id
    gear_changed.emit()

func get_equipped_weapon_bonus() -> int:
    if equipped_weapon == "":
        return 0

    var gear := ContentDefinitions.get_gear(equipped_weapon)
    return gear.damage_bonus if gear else 0

func owns_pet(pet_id: String) -> bool:
    return owned_pets.has(pet_id)

func equip_pet(pet_id: String) -> void:
    # "" unequips. Equipping requires ownership, mirroring equip_weapon().
    if pet_id != "" and not owns_pet(pet_id):
        return
    if equipped_pet == pet_id:
        return

    equipped_pet = pet_id
    # Max hp may have changed; keep current hp within the new effective max so an unequip
    # can't leave hp above max. Never raises hp (equipping grants headroom, not a free heal).
    player_hp = mini(player_hp, get_effective_max_hp())
    pet_changed.emit()
    player_damaged.emit(player_hp, get_effective_max_hp())

func get_equipped_pet_bonus() -> int:
    if equipped_pet == "":
        return 0

    var pet := ContentDefinitions.get_pet(equipped_pet)
    return pet.hp_bonus if pet else 0

func get_effective_max_hp() -> int:
    return PLAYER_MAX_HP + get_equipped_pet_bonus()

func _check_and_grant_first_pet() -> void:
    # Same gate as the Tier 1 armor grant: finishing every village quest. Grants once,
    # auto-equips (the reward should be immediately visible/felt), and heals the player by
    # the pet's bonus so the new max hp arrives full, not as an empty bar segment.
    if owns_pet("mossy"):
        return

    var required_quests := [QUEST_ELDER_GOLDEN_STAR, QUEST_MIRA_GLOWING_HERB, QUEST_FINN_SHIMMERING_ORE, QUEST_YARROW_SILVERLEAF]
    for quest_id in required_quests:
        if get_quest_state(quest_id) != QUEST_COMPLETED:
            return

    owned_pets.append("mossy")
    equip_pet("mossy")
    player_hp = mini(get_effective_max_hp(), player_hp + get_equipped_pet_bonus())
    player_damaged.emit(player_hp, get_effective_max_hp())
    pet_unlocked.emit("mossy")

func record_creature_met(creature_id: String) -> void:
    # Idempotent: only the first meeting emits creature_met, matching the bonus-only,
    # you-can-only-gain-entries rule the codex slice requires.
    if creatures_met.has(creature_id):
        return

    creatures_met[creature_id] = true
    creature_met.emit(creature_id)

func has_met_creature(creature_id: String) -> bool:
    return creatures_met.has(creature_id)

func award_keepsake(keepsake_id: String) -> void:
    # Idempotent: only the first award emits keepsake_awarded - a keepsake can never be lost
    # or re-earned, mirroring record_creature_met()'s bonus-only, gain-only rule exactly.
    if keepsakes.has(keepsake_id):
        return

    keepsakes[keepsake_id] = true
    keepsake_awarded.emit(keepsake_id)

func has_keepsake(keepsake_id: String) -> bool:
    return keepsakes.has(keepsake_id)

func get_combat_multiplier() -> float:
    return 1.0 + combat_streak * COMBAT_MULTIPLIER_PER_STACK

func take_player_damage(amount: int) -> void:
    if player_hp <= 0 or _player_hit_cooldown_remaining > 0.0:
        return

    player_hp = maxi(0, player_hp - amount)
    _player_hit_cooldown_remaining = PLAYER_HIT_COOLDOWN_SEC
    player_damaged.emit(player_hp, get_effective_max_hp())

    if player_hp == 0:
        player_died.emit()

func heal_player_to_full() -> void:
    player_hp = get_effective_max_hp()
    player_damaged.emit(player_hp, get_effective_max_hp())

func can_trigger_combat_question() -> bool:
    return _combat_question_cooldown_remaining <= 0.0

func mark_combat_question_triggered() -> void:
    _combat_question_cooldown_remaining = COMBAT_QUESTION_COOLDOWN_SEC

func answer_combat_question(correct: bool) -> void:
    if not correct:
        return

    _time_since_last_correct_answer = 0.0
    combat_streak = mini(COMBAT_STREAK_MAX, combat_streak + 1)
    combat_streak_changed.emit(combat_streak, get_combat_multiplier())

func save_game() -> void:
    var data := {
        "version": SAVE_VERSION,
        "selected_profile": selected_profile,
        "player_hp": player_hp,
        "collected_items": collected_items,
        "quest_states": quest_states,
        "quest_bonuses": quest_bonuses,
        "equipped_armor_tier": equipped_armor_tier,
        "coins": coins,
        "owned_gear": owned_gear,
        "equipped_weapon": equipped_weapon,
        "owned_pets": owned_pets,
        "equipped_pet": equipped_pet,
        "creatures_met": creatures_met,
        "keepsakes": keepsakes,
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if not file:
        return
    file.store_string(JSON.stringify(data))

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return

    var data: Variant = JSON.parse_string(file.get_as_text())
    if typeof(data) != TYPE_DICTIONARY:
        return

    data = _migrate(data)

    selected_profile = data.get("selected_profile", selected_profile)
    player_hp = data.get("player_hp", player_hp)
    quest_states = data.get("quest_states", quest_states)
    quest_bonuses = data.get("quest_bonuses", quest_bonuses)
    equipped_armor_tier = data.get("equipped_armor_tier", equipped_armor_tier)
    coins = int(data.get("coins", coins))
    equipped_weapon = data.get("equipped_weapon", equipped_weapon)

    # Array elements load as untyped Variant from JSON; coerce back to Array[String] since
    # owned_gear's declared type doesn't auto-convert an untyped Array on assignment.
    var loaded_gear: Array = data.get("owned_gear", [])
    owned_gear = []
    for gear_id in loaded_gear:
        owned_gear.append(String(gear_id))

    equipped_pet = data.get("equipped_pet", equipped_pet)
    var loaded_pets: Array = data.get("owned_pets", [])
    owned_pets = []
    for pet_id in loaded_pets:
        owned_pets.append(String(pet_id))

    # JSON.parse_string() returns every number as float, and Dictionary values have no
    # static type to auto-coerce them back (unlike equipped_armor_tier's declared int type,
    # which does this implicitly on assignment) - item counts must stay whole numbers.
    var loaded_items: Dictionary = data.get("collected_items", {})
    collected_items = {}
    for item_id in loaded_items.keys():
        collected_items[item_id] = int(loaded_items[item_id])

    # Same Dictionary coercion pattern as collected_items above - values are just `true`
    # booleans (bools round-trip through JSON fine), but rebuild the dict explicitly for
    # symmetry and to guard against unexpected key types.
    var loaded_creatures: Dictionary = data.get("creatures_met", {})
    creatures_met = {}
    for creature_id in loaded_creatures.keys():
        creatures_met[creature_id] = true

    # Same Dictionary coercion pattern as creatures_met above.
    var loaded_keepsakes: Dictionary = data.get("keepsakes", {})
    keepsakes = {}
    for keepsake_id in loaded_keepsakes.keys():
        keepsakes[keepsake_id] = true

    _refresh_elder_quest_flags()

func _migrate(data: Dictionary) -> Dictionary:
    # No-op: versions 0-2 (missing coins/gear/pet keys entirely) load fine as-is, since
    # load_game() reads the new keys via .get() with in-code defaults.
    return data

func reset_progress() -> void:
    reset_state()
    if get_tree().current_scene != null:
        get_tree().reload_current_scene()

func reset_state() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)

    selected_profile = ""
    player_hp = PLAYER_MAX_HP
    collected_items = {}
    quest_states = {
        QUEST_ELDER_GOLDEN_STAR: QUEST_NOT_STARTED,
        QUEST_MIRA_GLOWING_HERB: QUEST_NOT_STARTED,
        QUEST_FINN_SHIMMERING_ORE: QUEST_NOT_STARTED,
        QUEST_YARROW_SILVERLEAF: QUEST_NOT_STARTED,
    }
    quest_bonuses = {}
    equipped_armor_tier = 0
    coins = 0
    owned_gear = []
    equipped_weapon = ""
    owned_pets = []
    equipped_pet = ""
    creatures_met = {}
    keepsakes = {}
    combat_streak = 0
    _time_since_last_correct_answer = 0.0
    _player_hit_cooldown_remaining = 0.0
    _combat_question_cooldown_remaining = 0.0
    _refresh_elder_quest_flags()

func _on_profile_changed_autosave(_profile_id: String) -> void:
    save_game()

func _on_quest_changed_autosave(_quest_id: String, _state: String) -> void:
    save_game()

func _on_item_added_autosave(_item_id: String, _amount: int) -> void:
    save_game()

func _on_armor_equipped_autosave(_tier: int) -> void:
    save_game()

func _on_coins_changed_autosave(_coins: int) -> void:
    save_game()

func _on_gear_changed_autosave() -> void:
    save_game()

func _on_pet_changed_autosave() -> void:
    save_game()

func _on_creature_met_autosave(_id: String) -> void:
    save_game()

func _on_keepsake_awarded_autosave(_keepsake_id: String) -> void:
    save_game()
