extends RefCounted

## "Character-sprite polish pass" (docs/design/EXPANSION_BACKLOG.md) regression test: confirms
## Mossy's placeholder Polygon2D "Body" was upgraded to a real sprite in scenes/pets/Pet.tscn,
## and that the swap kept the node name/structure Pet.gd and PETS.md's contract expect (a
## child named "Body" on the Pet root). Isolated file (registered in tests/test_runner.gd),
## same instantiate/free pattern as tests/map_tests.gd. No behavior assertions here - Pet.gd's
## follow AI is unchanged and already covered by tests/pet_tests.gd.

const PET_SCENE_PATH := "res://scenes/pets/Pet.tscn"

func test_pet_body_is_a_real_sprite_with_a_texture() -> Dictionary:
    var failures: Array[String] = []
    var pet: Node = load(PET_SCENE_PATH).instantiate()

    var body := pet.get_node_or_null("Body")
    _check(failures, body != null, "expected Pet.tscn to have a child named Body")

    if body != null:
        var is_sprite := body is Sprite2D or body is AnimatedSprite2D
        _check(failures, is_sprite,
            "expected Body to be a Sprite2D or AnimatedSprite2D, got %s" % body.get_class())

        if body is AnimatedSprite2D:
            var animated := body as AnimatedSprite2D
            _check(failures, animated.sprite_frames != null,
                "expected AnimatedSprite2D Body to have SpriteFrames assigned")
            if animated.sprite_frames != null:
                _check(failures, animated.sprite_frames.get_animation_names().size() > 0,
                    "expected at least one animation on Body's SpriteFrames")
        elif body is Sprite2D:
            _check(failures, (body as Sprite2D).texture != null,
                "expected Sprite2D Body to have a texture assigned")

    pet.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_pet_no_longer_uses_the_old_placeholder_polygon_body() -> Dictionary:
    var failures: Array[String] = []
    var pet: Node = load(PET_SCENE_PATH).instantiate()

    var body := pet.get_node_or_null("Body")
    _check(failures, body != null and not (body is Polygon2D),
        "expected Body to no longer be the placeholder Polygon2D blob")

    pet.free()
    return {"ok": failures.is_empty(), "failures": failures}


func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
