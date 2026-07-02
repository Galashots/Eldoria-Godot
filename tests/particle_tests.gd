extends RefCounted

## "Ambient particle pass" (expansion backlog): unit tests for AmbientParticles.gd's pure
## region -> preset lookup/apply logic, plus scene-assertion tests (mirroring
## tests/lake_tests.gd's style) confirming each region's particle emitter is instanced at the
## expected Main.tscn position and reuses AudioManager.region_for_position()/REGION_RECTS
## rather than duplicating region geometry.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the other suites.

const AmbientParticles := preload("res://scripts/fx/AmbientParticles.gd")
const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"

const FLOWER_MEADOW_POSITION := Vector2(1392, 1216)
const FOREST_EDGE_POSITION := Vector2(336, 1128)
const LAKE_POSITION := Vector2(1552, 928)


func test_get_preset_returns_known_region_presets() -> Dictionary:
    var failures: Array[String] = []
    var meadow := AmbientParticles.get_preset("flower_meadow")
    var forest := AmbientParticles.get_preset("forest_edge")
    var lake := AmbientParticles.get_preset("lake")

    _check(failures, not meadow.is_empty(), "expected a flower_meadow preset")
    _check(failures, not forest.is_empty(), "expected a forest_edge preset")
    _check(failures, not lake.is_empty(), "expected a lake preset")
    return {"ok": failures.is_empty(), "failures": failures}


func test_get_preset_unknown_region_returns_empty() -> Dictionary:
    var failures: Array[String] = []
    var preset := AmbientParticles.get_preset("not_a_real_region")
    _check(failures, preset.is_empty(), "expected an unknown region to return an empty preset")
    return {"ok": failures.is_empty(), "failures": failures}


func test_presets_are_sparse_and_gentle() -> Dictionary:
    var failures: Array[String] = []
    for region_name: String in ["flower_meadow", "forest_edge", "lake"]:
        var preset: Dictionary = AmbientParticles.get_preset(region_name)
        var amount: int = preset.get("amount", 0)
        var color: Color = preset.get("color", Color(1, 1, 1, 1))
        _check(failures, amount > 0 and amount <= 12,
            "expected %s's particle amount to be small (1-12), found %d" % [region_name, amount])
        _check(failures, color.a <= 0.5,
            "expected %s's particle alpha to be low (<= 0.5) for a gentle look, found %s" % [region_name, color.a])
    return {"ok": failures.is_empty(), "failures": failures}


func test_apply_preset_configures_and_enables_emission() -> Dictionary:
    var failures: Array[String] = []
    var particles := CPUParticles2D.new()
    AmbientParticles.apply_preset(particles, AmbientParticles.get_preset("flower_meadow"))

    _check(failures, particles.emitting == true, "expected emitting to be enabled for a known preset")
    _check(failures, particles.amount > 0, "expected amount to be configured from the preset")

    particles.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_apply_preset_with_empty_preset_disables_emission() -> Dictionary:
    var failures: Array[String] = []
    var particles := CPUParticles2D.new()
    particles.emitting = true
    AmbientParticles.apply_preset(particles, {})

    _check(failures, particles.emitting == false,
        "expected an empty/unknown preset to disable emission rather than error")

    particles.free()
    return {"ok": failures.is_empty(), "failures": failures}


## --- Scene assertions: confirm the region emitters are wired into Main.tscn at positions that
## fall inside AudioManager.REGION_RECTS' matching rects, so region and particle sense agree. ---

func test_flower_meadow_particles_are_positioned_inside_the_flower_meadow_region() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var node := main.get_node_or_null("FlowerMeadowParticles") as Node2D
    _check(failures, node != null, "expected FlowerMeadowParticles to exist")
    if node != null:
        _check(failures, node.position.is_equal_approx(FLOWER_MEADOW_POSITION),
            "expected FlowerMeadowParticles at %s, found %s" % [FLOWER_MEADOW_POSITION, node.position])
        var region := AudioManager.region_for_position(node.global_position, AudioManager.REGION_RECTS, AudioManager.DEFAULT_REGION)
        _check(failures, region == "flower_meadow",
            "expected FlowerMeadowParticles' position to resolve to the flower_meadow region, found '%s'" % region)

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_forest_edge_particles_are_positioned_inside_the_forest_edge_region() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var node := main.get_node_or_null("ForestEdgeParticles") as Node2D
    _check(failures, node != null, "expected ForestEdgeParticles to exist")
    if node != null:
        _check(failures, node.position.is_equal_approx(FOREST_EDGE_POSITION),
            "expected ForestEdgeParticles at %s, found %s" % [FOREST_EDGE_POSITION, node.position])
        var region := AudioManager.region_for_position(node.global_position, AudioManager.REGION_RECTS, AudioManager.DEFAULT_REGION)
        _check(failures, region == "forest_edge",
            "expected ForestEdgeParticles' position to resolve to the forest_edge region, found '%s'" % region)

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_lake_particles_are_positioned_inside_the_lake_region() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var node := main.get_node_or_null("LakeParticles") as Node2D
    _check(failures, node != null, "expected LakeParticles to exist")
    if node != null:
        _check(failures, node.position.is_equal_approx(LAKE_POSITION),
            "expected LakeParticles at %s, found %s" % [LAKE_POSITION, node.position])
        var region := AudioManager.region_for_position(node.global_position, AudioManager.REGION_RECTS, AudioManager.DEFAULT_REGION)
        _check(failures, region == "lake",
            "expected LakeParticles' position to resolve to the lake region, found '%s'" % region)

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_particle_nodes_carry_no_collision() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    for node_name in ["FlowerMeadowParticles", "ForestEdgeParticles", "LakeParticles"]:
        var node := main.get_node_or_null(node_name)
        _check(failures, node != null, "expected %s to exist" % node_name)
        if node != null:
            _check(failures, not (node is CollisionObject2D),
                "expected %s to carry no collision (purely visual)" % node_name)

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
