class_name PetDefinition
extends Resource

@export var id: String = ""
@export var label: String = ""
@export var rarity: String = "Common"
@export var hp_bonus: int = 0
## Optional 2-frame idle-bob sprite paths. Empty means "use Pet.tscn's baked-in SpriteFrames"
## (Mossy's original art, kept as the scene default so existing saves/scenes need no changes).
## A second pet sets both so Pet.gd can build its own SpriteFrames at spawn time - data-driven
## sprite selection instead of duplicating Pet.tscn per species.
@export var sprite_frame1_path: String = ""
@export var sprite_frame2_path: String = ""
