class_name ContentDefinitions
extends RefCounted

const PROFILE_LABELS := {
    "grade_2_mage": "Grade 2 Mage",
    "grade_5_adventurer": "Grade 5 Adventurer",
}

const ITEM_LABELS := {
    "golden_star": "Golden Star",
    "glowing_herb": "Glowing Herb",
}

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
}

static func get_profile_label(profile_id: String) -> String:
    if profile_id == "":
        return "None selected"
    return PROFILE_LABELS.get(profile_id, profile_id)

static func get_item_label(item_id: String) -> String:
    return ITEM_LABELS.get(item_id, item_id)

static func get_quest_summary(quest_id: String, state: String) -> String:
    var summaries: Dictionary = QUEST_SUMMARIES.get(quest_id, {})
    return summaries.get(state, "Unknown quest")
