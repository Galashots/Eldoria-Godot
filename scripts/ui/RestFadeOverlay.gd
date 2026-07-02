extends CanvasLayer

## Diegetic session-end "rest" beat's gentle visual confirmation. A full-screen ColorRect
## fades in to a warm, dim tint and back out over ~2s - deliberately NOT a game-over/quit
## screen, just a calm beat the child sees while resting at the campfire. Purely additive,
## no blocking input, no penalty; gameplay is never paused by this.

@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
    overlay.color.a = 0.0
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_rest_fade() -> void:
    var tween := create_tween()
    tween.tween_property(overlay, "color:a", 0.55, 0.8).set_trans(Tween.TRANS_SINE)
    tween.tween_interval(0.4)
    tween.tween_property(overlay, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
