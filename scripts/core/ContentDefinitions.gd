class_name ContentDefinitions
extends RefCounted

const PROFILE_LABELS := {
    "grade_2_mage": "Grade 2 Mage",
    "grade_5_adventurer": "Grade 5 Adventurer",
}

## Item display labels are loaded from ItemDefinition .tres resources under
## data/items/ -- a small proof of the Resource-backed content pattern before
## it's considered for quest summaries or profile labels (see docs/ROADMAP.md).
const ITEM_DEFINITIONS: Array[ItemDefinition] = [
    preload("res://data/items/golden_star.tres"),
    preload("res://data/items/glowing_herb.tres"),
    preload("res://data/items/shimmering_ore.tres"),
]

const QUEST_SUMMARIES := {
    "elder_golden_star": {
        "not_started": "Talk to Elder Rowan",
        "started": "Find the golden star",
        "ready_to_turn_in": "Return the golden star to Elder Rowan",
        "learning_check": "Answer Elder Rowan's question",
        "completed": "Elder Rowan quest complete",
    },
    "mira_glowing_herb": {
        "not_started": "Talk to Mira the Gardener",
        "started": "Find the glowing herb",
        "ready_to_turn_in": "Return the glowing herb to Mira",
        "learning_check": "Answer Mira's question",
        "completed": "Mira's garden quest complete",
    },
    "finn_shimmering_ore": {
        "not_started": "Talk to Finn the Blacksmith",
        "started": "Find the shimmering ore",
        "ready_to_turn_in": "Return the shimmering ore to Finn",
        "learning_check": "Answer Finn's question",
        "completed": "Finn's forge quest complete",
    },
}

const BADGE_LABELS := {
    "elder_golden_star": "Elder's Wisdom Badge",
    "mira_glowing_herb": "Mira's Garden Badge",
    "finn_shimmering_ore": "Finn's Forge Badge",
}

static func get_profile_label(profile_id: String) -> String:
    if profile_id == "":
        return "None selected"
    return PROFILE_LABELS.get(profile_id, profile_id)

static func get_item_label(item_id: String) -> String:
    for item in ITEM_DEFINITIONS:
        if item.id == item_id:
            return item.label
    return item_id

static func get_quest_summary(quest_id: String, state: String) -> String:
    var summaries: Dictionary = QUEST_SUMMARIES.get(quest_id, {})
    return summaries.get(state, "Unknown quest")

static func get_badge_label(quest_id: String) -> String:
    return BADGE_LABELS.get(quest_id, "Bonus Badge")
