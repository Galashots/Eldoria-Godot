"""Generates the two Mossy pet idle-bob frames:
  assets/sprites/pets/mossy_idle1.png
  assets/sprites/pets/mossy_idle2.png

"Character-sprite polish pass" (docs/design/EXPANSION_BACKLOG.md): upgrades Mossy the pet
from a flat placeholder Polygon2D blob (scenes/pets/Pet.tscn) to a small generated pixel-art
sprite, honoring docs/art/STYLE_GUIDE.md and docs/design/VISUAL_CONTRACT.md. Deliberately
procedural (Pillow), mirroring assets/sprites/tiles/gen_tileset.py's precedent, so the sprite
is reproducible in-repo with no external asset pack.

Canvas: 24x24, actor pivot at center-bottom (matches VISUAL_CONTRACT's actor-canvas rule),
nearest-neighbor scaling is the project default (see project.godot), so this stays crisp
pixel art at any zoom.

CRITICAL READABILITY RULE: this repo shipped a green-on-green invisible Mossy once. The body
color is kept in the same mint/teal family as the original placeholder (hue ~157 degrees,
clearly separated from the grass ramp's ~126-136 degree green hue in
docs/art/STYLE_GUIDE.md's "Locked shared palette"), AND every shape gets a 2px near-black
outline so Mossy reads as a distinct silhouette against grass_mid (#339E40) regardless of hue
alone. Colors below are picked from/near the locked shared palette where sensible (the leaf
sprout reuses the palette's forest_floor-family green; the body/eye colors are Mossy's own
established identity color, kept from the original placeholder per the "no behavior/identity
change" acceptance criterion).

Run: `python assets/sprites/pets/gen_mossy.py` from the repo root. Requires Pillow.
"""

from PIL import Image, ImageDraw

SIZE = 24
OUT1 = "assets/sprites/pets/mossy_idle1.png"
OUT2 = "assets/sprites/pets/mossy_idle2.png"

# Mossy's identity colors (mint/teal family, matches the original placeholder polygon so this
# is a pure art upgrade, not a redesign).
BODY = (102, 217, 173, 255)       # mint/teal (was Color(0.4, 0.85, 0.68) in Pet.tscn)
BODY_SHADE = (70, 176, 138, 255)  # darker teal for a soft belly/shading accent
OUTLINE = (18, 28, 24, 255)       # near-black, strong contrast vs. grass_mid (#339E40)
LEAF = (33, 102, 51, 255)         # forest_floor from the locked shared palette
EYE_WHITE = (255, 255, 255, 255)
EYE_PUPIL = (26, 38, 33, 255)


def _draw_mossy(draw: ImageDraw.ImageDraw, bob: int) -> None:
    """bob: 0 or -1, a 1px vertical offset for the idle-bob second frame."""
    cx = SIZE // 2
    base_y = 19 + bob  # bottom of the body's rounded footprint

    # Body: a rounded blob silhouette (outline first, body on top, slightly inset).
    body_box = (cx - 8, base_y - 13, cx + 8, base_y)
    draw.ellipse(body_box, fill=OUTLINE)
    inset = (body_box[0] + 2, body_box[1] + 2, body_box[2] - 2, body_box[3] - 1)
    draw.ellipse(inset, fill=BODY)

    # Soft belly shade for a little roundness/depth.
    belly = (cx - 4, base_y - 6, cx + 4, base_y - 1)
    draw.ellipse(belly, fill=BODY_SHADE)

    # Leaf sprout on top.
    leaf_y = base_y - 13 + bob
    draw.polygon(
        [(cx - 1, leaf_y), (cx + 4, leaf_y - 7), (cx + 5, leaf_y - 1)],
        fill=OUTLINE,
    )
    draw.polygon(
        [(cx, leaf_y - 1), (cx + 3, leaf_y - 5), (cx + 4, leaf_y - 1)],
        fill=LEAF,
    )

    # Big friendly eyes (kid-readable, per STYLE_GUIDE "clear silhouettes").
    eye_y = base_y - 9
    for ex in (cx - 4, cx + 2):
        draw.ellipse((ex, eye_y, ex + 4, eye_y + 4), fill=EYE_WHITE, outline=OUTLINE)
        draw.ellipse((ex + 1, eye_y + 1, ex + 3, eye_y + 3), fill=EYE_PUPIL)


def _make_frame(bob: int) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _draw_mossy(draw, bob)
    return img


def main() -> None:
    _make_frame(0).save(OUT1)
    _make_frame(-1).save(OUT2)
    print(f"Wrote {OUT1} and {OUT2}")


if __name__ == "__main__":
    main()
