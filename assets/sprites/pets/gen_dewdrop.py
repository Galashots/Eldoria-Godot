"""Generates the two Dewdrop pet idle-bob frames:
  assets/sprites/pets/dewdrop_idle1.png
  assets/sprites/pets/dewdrop_idle2.png

"Second pet: earn a companion from the Elder Slime keepsake" (docs/design/EXPANSION_BACKLOG.md):
the second pet species, unlocked by defeating the Elder Slime mini-boss (the same beat that
already grants the "Elder Slime's Dewdrop" keepsake - see ContentDefinitions.KEEPSAKE_FACTS).
Mirrors assets/sprites/pets/gen_mossy.py's shape exactly (same 24x24 canvas, same actor
pivot-at-center-bottom convention, same Pillow procedural approach - no external asset pack).

CRITICAL READABILITY RULE (same lesson gen_mossy.py already documents): every shape gets a 2px
near-black outline so Dewdrop reads as a distinct silhouette against grass_mid (#339E40)
regardless of hue alone. The body color is a clear blue/dewdrop-family hue (~215 degrees),
picked to be hue-separated from BOTH the grass ramp (~126-136 degrees, STYLE_GUIDE.md's locked
shared palette) AND Mossy's mint/teal identity color (~157 degrees), so the two pets and the
grass floor never fight for attention when standing together. Sampled near the palette's
`water`/`water_deep` ramp (#3A6EC4 / #224894) for family consistency with the rest of the game's
blue accents, then given its own lighter/brighter variant so it doesn't read as literal water.

Run: `python assets/sprites/pets/gen_dewdrop.py` from the repo root. Requires Pillow.
"""

from PIL import Image, ImageDraw

SIZE = 24
OUT1 = "assets/sprites/pets/dewdrop_idle1.png"
OUT2 = "assets/sprites/pets/dewdrop_idle2.png"

# Dewdrop's identity colors (blue/dewdrop family, distinct from grass and from Mossy's teal).
BODY = (91, 156, 232, 255)        # bright sky-blue, a lighter cousin of the palette's `water`
BODY_SHADE = (58, 110, 196, 255)  # palette `water` (#3A6EC4) as the belly-shade accent
OUTLINE = (16, 22, 34, 255)       # near-black with a cool tint, strong contrast vs. grass_mid
HIGHLIGHT = (214, 236, 255, 255)  # pale glint on top of the drop, like sunlight on water
EYE_WHITE = (255, 255, 255, 255)
EYE_PUPIL = (20, 28, 40, 255)


def _draw_dewdrop(draw: ImageDraw.ImageDraw, bob: int) -> None:
    """bob: 0 or -1, a 1px vertical offset for the idle-bob second frame."""
    cx = SIZE // 2
    base_y = 19 + bob  # bottom of the body's rounded footprint

    # Body: a teardrop silhouette (round base, tapering point on top) - outline first, then
    # the fill inset by 2px so the outline reads as a clean rim.
    body_box = (cx - 7, base_y - 14, cx + 7, base_y)
    draw.ellipse(body_box, fill=OUTLINE)
    point = [(cx, base_y - 17), (cx - 6, base_y - 9), (cx + 6, base_y - 9)]
    draw.polygon(point, fill=OUTLINE)

    inset = (body_box[0] + 2, body_box[1] + 2, body_box[2] - 2, body_box[3] - 1)
    draw.ellipse(inset, fill=BODY)
    inset_point = [(cx, base_y - 15), (cx - 4, base_y - 8), (cx + 4, base_y - 8)]
    draw.polygon(inset_point, fill=BODY)

    # Soft belly shade for roundness/depth.
    belly = (cx - 4, base_y - 6, cx + 4, base_y - 1)
    draw.ellipse(belly, fill=BODY_SHADE)

    # A small glint highlight near the top-left, like light on water.
    glint_y = base_y - 12 + bob
    draw.ellipse((cx - 3, glint_y, cx, glint_y + 3), fill=HIGHLIGHT)

    # Big friendly eyes (kid-readable, per STYLE_GUIDE "clear silhouettes").
    eye_y = base_y - 8
    for ex in (cx - 4, cx + 1):
        draw.ellipse((ex, eye_y, ex + 4, eye_y + 4), fill=EYE_WHITE, outline=OUTLINE)
        draw.ellipse((ex + 1, eye_y + 1, ex + 3, eye_y + 3), fill=EYE_PUPIL)


def _make_frame(bob: int) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _draw_dewdrop(draw, bob)
    return img


def main() -> None:
    _make_frame(0).save(OUT1)
    _make_frame(-1).save(OUT2)
    print(f"Wrote {OUT1} and {OUT2}")


if __name__ == "__main__":
    main()
