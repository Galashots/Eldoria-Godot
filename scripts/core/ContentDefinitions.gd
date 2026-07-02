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
    preload("res://data/items/silverleaf.tres"),
]

## Gear display/stat data is loaded from GearDefinition .tres resources under data/gear/ --
## mirrors the ItemDefinition pattern above, promoted per docs/ROADMAP.md's M3 note now that
## gear stats (rarity, damage_bonus, price) need structured data, not just display text.
const GEAR_DEFINITIONS: Array[GearDefinition] = [
    preload("res://data/gear/worn_dagger.tres"),
    preload("res://data/gear/iron_sword.tres"),
    preload("res://data/gear/oakheart_blade.tres"),
    preload("res://data/gear/dawnbringer_blade.tres"),
]

## Pet display/stat data mirrors the GearDefinition pattern above (see docs/design/PETS.md).
const PET_DEFINITIONS: Array[PetDefinition] = [
    preload("res://data/pets/mossy.tres"),
]

const RARITY_COLORS := {
    "Common": Color.WHITE,
    "Uncommon": Color(0.35, 0.75, 0.35),
    "Rare": Color(0.35, 0.55, 0.95),
    "Legendary": Color(0.95, 0.75, 0.2),
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
    "finn_shimmering_ore": {
        "not_started": "Talk to Finn the Blacksmith",
        "started": "Find the shimmering ore",
        "ready_to_turn_in": "Return the shimmering ore to Finn",
        "learning_check": "Answer Finn's question",
        "completed": "Finn's forge quest complete",
    },
    "yarrow_silverleaf": {
        "not_started": "Talk to Yarrow the Healer",
        "started": "Find silverleaf",
        "ready_to_turn_in": "Return silverleaf to Yarrow",
        "learning_check": "Pay Yarrow for the remedy jar",
        "completed": "Yarrow's remedy is brewed",
    },
}

const BADGE_LABELS := {
    "elder_golden_star": "Elder's Wisdom Badge",
    "mira_glowing_herb": "Mira's Garden Badge",
    "finn_shimmering_ore": "Finn's Forge Badge",
    "yarrow_silverleaf": "Yarrow's Remedy Badge",
}

const ARMOR_TIER_LABELS := {
    1: "Leather Armor",
}

## "Creatures met" codex factoids (display-only text, no stats) - a plain dictionary rather
## than a .tres Resource, since two entries still doesn't meet the repo's "more content, or a
## second consumer needing structured data" bar for Resource promotion (see AGENTS.md).
const CREATURE_FACTS := {
    "meadow_slime": {
        "label": "Meadow Slime",
        "fact": "A bouncy meadow friend that loves sunny grass — drops a coin when bested!",
    },
    "elder_slime": {
        "label": "Elder Slime",
        "fact": "A big, wise old slime who winds up before a hop — watch for the glow, then dodge!",
    },
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

static func get_armor_tier_label(tier: int) -> String:
    return ARMOR_TIER_LABELS.get(tier, "Tier %d Armor" % tier)

static func get_gear(gear_id: String) -> GearDefinition:
    for gear in GEAR_DEFINITIONS:
        if gear.id == gear_id:
            return gear
    return null

static func get_gear_label(gear_id: String) -> String:
    var gear := get_gear(gear_id)
    return gear.label if gear else gear_id

static func get_pet(pet_id: String) -> PetDefinition:
    for pet in PET_DEFINITIONS:
        if pet.id == pet_id:
            return pet
    return null

static func get_pet_label(pet_id: String) -> String:
    var pet := get_pet(pet_id)
    return pet.label if pet else pet_id

static func get_rarity_color(rarity: String) -> Color:
    return RARITY_COLORS.get(rarity, Color.WHITE)

## Boss keepsake display text (label + one-line flavor), mirroring CREATURE_FACTS' plain-
## dictionary shape exactly - one entry so far, well under the repo's "more content, or a
## second consumer needing structured data" bar for Resource promotion (see AGENTS.md).
const KEEPSAKE_FACTS := {
    "elder_slime_dewdrop": {
        "label": "Elder Slime's Dewdrop",
        "fact": "A cool, glimmering drop left behind by the Elder Slime — proof you outlasted its lunge.",
    },
}

static func get_keepsake_label(keepsake_id: String) -> String:
    var keepsake: Dictionary = KEEPSAKE_FACTS.get(keepsake_id, {})
    return keepsake.get("label", keepsake_id)

static func get_keepsake_fact(keepsake_id: String) -> String:
    var keepsake: Dictionary = KEEPSAKE_FACTS.get(keepsake_id, {})
    return keepsake.get("fact", "")

static func get_creature_label(creature_id: String) -> String:
    var creature: Dictionary = CREATURE_FACTS.get(creature_id, {})
    return creature.get("label", creature_id)

static func get_creature_fact(creature_id: String) -> String:
    var creature: Dictionary = CREATURE_FACTS.get(creature_id, {})
    return creature.get("fact", "")

## "Places discovered" codex factoids (display-only text, no stats), mirroring
## CREATURE_FACTS/KEEPSAKE_FACTS' plain-dictionary shape exactly - four entries, one per
## sparkle spot, well under the repo's "more content, or a second consumer needing
## structured data" bar for Resource promotion (see AGENTS.md).
const PLACE_FACTS := {
    "flower_meadow_sparkle": {
        "label": "Flower Meadow Sparkle",
        "fact": "A shimmering patch of wildflowers south of the village green.",
    },
    "forest_edge_sparkle": {
        "label": "Forest Edge Hollow",
        "fact": "A quiet, shady hollow tucked into the forest's edge.",
    },
    "lake_shore_sparkle": {
        "label": "Lake Shore Glint",
        "fact": "A glint of light on the sandy shore near the lake.",
    },
    "rocky_border_sparkle": {
        "label": "Rocky Border Nook",
        "fact": "A hidden nook tucked against the map's rocky far edge.",
    },
}

static func get_place_label(place_id: String) -> String:
    var place: Dictionary = PLACE_FACTS.get(place_id, {})
    return place.get("label", place_id)

static func get_place_fact(place_id: String) -> String:
    var place: Dictionary = PLACE_FACTS.get(place_id, {})
    return place.get("fact", "")
