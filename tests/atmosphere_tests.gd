extends RefCounted

## Regression tests for the "Day-warmth atmosphere pass" (docs/design/EXPANSION_BACKLOG.md):
## confirms the world-only warm CanvasModulate wash and the full-screen vignette overlay both
## exist in Main.tscn with subtle, kid-bright bounds - never a heavy tint, never a UI-blocking
## overlay. Kept in its own file (registered in tests/test_runner.gd), same pattern as
## tests/map_tests.gd, rather than appended to game_state_tests.gd.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the other suites.

const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"


func test_world_has_a_subtle_warm_canvas_modulate() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var modulate_node := main.get_node_or_null("World/DayWarmth")
    _check(failures, modulate_node != null, "expected World/DayWarmth to exist")
    if modulate_node != null:
        _check(failures, modulate_node is CanvasModulate,
            "expected World/DayWarmth to be a CanvasModulate")
        var tint: Color = (modulate_node as CanvasModulate).color
        # Subtle and kid-bright: never dim (every channel close to full brightness) and never
        # a strong color cast (barely-there warmth - a very slight amber lean, not orange).
        _check(failures, tint.r >= 0.95 and tint.g >= 0.9 and tint.b >= 0.85,
            "expected a bright, subtle tint (close to white), found %s" % tint)
        _check(failures, tint.r >= tint.g and tint.g >= tint.b,
            "expected a warm lean (red >= green >= blue), found %s" % tint)
        _check(failures, tint.a == 1.0, "expected the tint to be fully opaque (alpha 1.0)")

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_vignette_overlay_exists_and_never_blocks_input() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var overlay := main.get_node_or_null("VignetteOverlay")
    _check(failures, overlay != null, "expected VignetteOverlay to exist")
    if overlay != null:
        _check(failures, overlay is CanvasLayer, "expected VignetteOverlay to be a CanvasLayer")

        var vignette_rect := overlay.get_node_or_null("Vignette") as Control
        _check(failures, vignette_rect != null, "expected VignetteOverlay/Vignette to exist")
        if vignette_rect != null:
            _check(failures, vignette_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE,
                "expected the vignette to never block mouse input")

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_vignette_overlay_layers_below_interactive_ui() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var overlay := main.get_node_or_null("VignetteOverlay") as CanvasLayer
    _check(failures, overlay != null, "expected VignetteOverlay to exist")
    if overlay != null:
        for ui_name in ["HUD", "DialogueBox", "CharacterPanel", "LearningCheck", "ProfileSelect"]:
            var ui_node := main.get_node_or_null(NodePath(ui_name)) as CanvasLayer
            _check(failures, ui_node != null, "expected %s to still exist" % ui_name)
            if ui_node != null:
                _check(failures, overlay.layer < ui_node.layer,
                    "expected VignetteOverlay's layer (%d) below %s's layer (%d)" % [overlay.layer, ui_name, ui_node.layer])

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
