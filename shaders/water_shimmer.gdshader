shader_type canvas_item;

// "Living lake" (expansion backlog): a gentle, low-contrast animated shimmer laid over the
// lake's water footprint (see scenes/main/Main.tscn's "LakeShimmer" ColorRect, sized to the
// lake's world-space bounding rect). Kid-audience: calm, slow, low-alpha highlight streaks,
// never a bright specular flash or busy motion (docs/design/RESEARCH_NOTES.md §7.1/§9.1).
//
// Pure sine-based procedural pattern - no textures, so this degrades gracefully: if this
// shader ever fails to compile, Godot falls back to flat-rendering the CanvasItem (the
// ColorRect's own modulate color), which is itself a very faint, near-invisible tint over the
// water tiles - the lake still reads correctly as flat water, never a crash or a hole.

uniform float scroll_speed : hint_range(0.0, 1.0) = 0.06;
uniform float ripple_scale : hint_range(1.0, 40.0) = 14.0;
uniform float highlight_alpha : hint_range(0.0, 0.3) = 0.10;
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.95, 1.0);

void fragment() {
    vec2 uv = UV;

    // Two slow, offset sine waves crossed together read as a gentle rippled highlight
    // pattern rather than a single obvious scrolling stripe.
    float t = TIME * scroll_speed;
    float wave_a = sin((uv.x + uv.y * 0.5 + t) * ripple_scale);
    float wave_b = sin((uv.x * 0.6 - uv.y + t * 1.3) * ripple_scale * 0.7);
    float ripple = (wave_a + wave_b) * 0.5;

    // Keep only the brightest crests as soft highlights (smoothstep -> a few gentle
    // sparkle bands, not a full-surface glow) and fade them in/out slowly over time so
    // nothing flashes.
    float highlight = smoothstep(0.75, 1.0, ripple);
    float breathing = 0.85 + 0.15 * sin(TIME * 0.4);

    COLOR = highlight_color;
    COLOR.a = highlight * highlight_alpha * breathing;
}
