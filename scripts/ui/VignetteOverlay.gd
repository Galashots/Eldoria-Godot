extends CanvasLayer

## Day-warmth atmosphere pass: a full-screen, soft-edged radial vignette that gently darkens
## the screen corners so the world reads as a cohesive storybook scene instead of flat, evenly
## lit tiles (docs/design/EXPANSION_BACKLOG.md's "Day-warmth atmosphere pass" slice). Purely
## decorative - never blocks input (mouse_filter IGNORE on both the layer's control and the
## TextureRect) and sits below every interactive UI CanvasLayer (HUD/DialogueBox/panels all use
## layer >= 1; this stays at layer 0). Uses a GradientTexture2D (assets/ui/vignette_gradient.tres)
## rather than a shader, per the acceptance criteria's placeholder-fallback-safe requirement: if
## the texture resource ever failed to load, the TextureRect would simply render nothing -
## never a crash.

func _ready() -> void:
    layer = 0
