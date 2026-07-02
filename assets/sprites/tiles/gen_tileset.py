"""Generates assets/sprites/tiles/placeholder_tileset.png.

Bootstrap placeholder tileset for the M1 world (see docs/CURRENT_STATE.md).
Deliberately flat-color/programmatic, not AI source art, matching how the
original 4-tile tileset (grass/path/water/rock) was authored, extended here
with a richer tile set for the "epic map pass" (docs/design/NORTH_STAR.md,
kid-audience: bright, readable, colorful, not busy).

IMPORTANT: tile indices 0-3 (grass, dirt path, water, rock) keep their exact
existing atlas coordinates/colors so already-painted TileMapLayer cells do not
change meaning. New tiles are appended after index 3.

Layout: single row of 16x16 tiles, one PNG, indices left to right:
  0 grass (original)
  1 dirt path (original)
  2 water (original)
  3 rock (original)
  4 grass variant A (lighter, subtle texture)
  5 grass variant B (darker, subtle texture)
  6 flower meadow A (small colorful dots on grass)
  7 flower meadow B (different colorful dots on grass)
  8 forest-floor grass (darker, cooler green)
  9 sand / shore
  10 deep water (darker blue)
  11 stone / cliff border tile

Run: `python assets/sprites/tiles/gen_tileset.py` from the repo root.
Requires Pillow (already a dependency of tools/asset_pipeline/).

--- Palette (locked, see docs/art/STYLE_GUIDE.md "Locked shared palette") ---

This is Eldoria's single shared color source of truth (RESEARCH_NOTES.md §9.1
palette discipline): a small number of named ramps, each already following
the "brightness up / saturation eased at the bright end / gentle per-ramp hue
shift" rule the research calls the cheapest cohesion lever. Every tile below
draws its colors from PALETTE instead of an inline literal. This pass is a
pure reorganization -- every RGBA value is byte-identical to what shipped
before, so the generated PNG does not change. Future procedural art (new
tiles, polygon props, particles) should sample from PALETTE rather than
inventing a fresh RGB.
"""

from PIL import Image, ImageDraw

TILE = 16
NUM_TILES = 12
OUT_PATH = "assets/sprites/tiles/placeholder_tileset.png"

# Named value ramps. Each ramp is dark -> light within its hue family, with
# saturation easing off at the bright end (see the module docstring).
PALETTE = {
    # Grass ramp (hue ~126-136, green): dark forest floor -> mid grass ->
    # light grass highlight.
    "grass_dark": (40, 138, 54, 255),
    "grass_mid": (51, 158, 64, 255),
    "grass_light": (74, 176, 84, 255),
    "forest_floor": (33, 102, 51, 255),
    # Earth ramp (hue ~36-42, warm tan/brown): dirt path, sand shore.
    "path": (176, 141, 87, 255),
    "sand": (231, 205, 146, 255),
    # Water ramp (hue ~217-220, blue): mid water -> deep water.
    "water": (58, 110, 196, 255),
    "water_deep": (34, 72, 148, 255),
    # Stone ramp (near-desaturated, cool gray): rock, cliff border.
    "rock": (115, 115, 120, 255),
    "cliff": (94, 90, 92, 255),
    # Accent dots for flower meadows -- kept few and saturated on purpose
    # (small high-chroma accents against a desaturated/mid-value ground read
    # as "epic" without overwhelming a young-eyes audience; see the style
    # guide's saturation-at-bright-end rule).
    "flower_gold": (255, 223, 90, 255),
    "flower_white": (255, 255, 255, 255),
    "flower_pink": (255, 140, 170, 255),
    "flower_violet": (190, 130, 230, 255),
    "flower_amber": (255, 180, 60, 255),
}

# Original 4 tiles' flat colors, unchanged -- sourced from PALETTE.
GRASS = PALETTE["grass_mid"]
PATH = PALETTE["path"]
WATER = PALETTE["water"]
ROCK = PALETTE["rock"]

# New tile base colors -- sourced from PALETTE.
GRASS_LIGHT = PALETTE["grass_light"]
GRASS_DARK = PALETTE["grass_dark"]
FOREST_FLOOR = PALETTE["forest_floor"]
SAND = PALETTE["sand"]
DEEP_WATER = PALETTE["water_deep"]
CLIFF = PALETTE["cliff"]

FLOWER_COLORS_A = [PALETTE["flower_gold"], PALETTE["flower_white"], PALETTE["flower_pink"]]
FLOWER_COLORS_B = [PALETTE["flower_violet"], PALETTE["flower_amber"], PALETTE["flower_white"]]


def tile_canvas(color):
    img = Image.new("RGBA", (TILE, TILE), color)
    return img


def add_speckle(img, color, points):
    draw = ImageDraw.Draw(img)
    for (x, y) in points:
        draw.point((x, y), fill=color)


def make_grass_variant(base_color, texture_color, seed_points):
    img = tile_canvas(base_color)
    add_speckle(img, texture_color, seed_points)
    return img


def make_flower_meadow(dot_colors):
    img = tile_canvas(GRASS)
    draw = ImageDraw.Draw(img)
    spots = [(3, 3), (11, 4), (6, 8), (12, 11), (2, 12), (9, 2)]
    for i, (x, y) in enumerate(spots):
        color = dot_colors[i % len(dot_colors)]
        draw.point((x, y), fill=color)
        draw.point((x + 1, y), fill=color)
    return img


def make_sand():
    img = tile_canvas(SAND)
    speckle = (208, 181, 122, 255)
    add_speckle(img, speckle, [(2, 2), (5, 9), (9, 4), (12, 12), (7, 13), (13, 6)])
    return img


def make_deep_water():
    img = tile_canvas(DEEP_WATER)
    highlight = (60, 104, 180, 255)
    add_speckle(img, highlight, [(3, 4), (10, 8), (6, 12), (13, 3)])
    return img


def make_cliff():
    img = tile_canvas(CLIFF)
    draw = ImageDraw.Draw(img)
    shadow = (70, 67, 69, 255)
    highlight = (140, 136, 138, 255)
    draw.line([(0, 12), (16, 10)], fill=shadow, width=2)
    draw.line([(0, 4), (16, 6)], fill=highlight, width=1)
    return img


def build():
    tiles = [
        tile_canvas(GRASS),
        tile_canvas(PATH),
        tile_canvas(WATER),
        tile_canvas(ROCK),
        make_grass_variant(GRASS_LIGHT, (86, 190, 96, 255), [(2, 3), (9, 5), (13, 10), (5, 13)]),
        make_grass_variant(GRASS_DARK, (28, 120, 42, 255), [(4, 2), (11, 6), (7, 11), (13, 13)]),
        make_flower_meadow(FLOWER_COLORS_A),
        make_flower_meadow(FLOWER_COLORS_B),
        make_grass_variant(FOREST_FLOOR, (24, 84, 40, 255), [(3, 4), (10, 9), (6, 13), (13, 2)]),
        make_sand(),
        make_deep_water(),
        make_cliff(),
    ]

    sheet = Image.new("RGBA", (TILE * NUM_TILES, TILE), (0, 0, 0, 0))
    for i, tile in enumerate(tiles):
        sheet.paste(tile, (i * TILE, 0))

    sheet.save(OUT_PATH)
    print(f"Wrote {OUT_PATH} ({sheet.size[0]}x{sheet.size[1]}, {NUM_TILES} tiles)")


if __name__ == "__main__":
    build()
