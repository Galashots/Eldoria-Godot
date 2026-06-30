#!/usr/bin/env python3
"""Self-test for the asset normalization pipeline using synthetic fixtures.

No AI-generated art or binary fixtures are committed; every test image is built
in-memory. Run with: python tools/asset_pipeline/test_pipeline.py
"""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

from manifest import (
    apply_color_key,
    apply_edge_flood,
    collect_manifest_errors,
    normalize_asset_sheet,
)

MAGENTA = (255, 0, 255)
GREEN = (0, 200, 0)


def solid(size: tuple[int, int], color: tuple[int, int, int], alpha: int = 255) -> Image.Image:
    return Image.new("RGBA", size, (*color, alpha))


class ColorKeyTests(unittest.TestCase):
    def test_color_key_strips_matching_background(self):
        img = solid((8, 8), MAGENTA)
        arr = np.array(img)
        arr[2:6, 2:6, :3] = GREEN
        img = Image.fromarray(arr, "RGBA")

        out = apply_color_key(img, {"mode": "color_key", "color": "#ff00ff", "tolerance": 0})
        out_arr = np.array(out)

        self.assertEqual(out_arr[0, 0, 3], 0, "magenta background should become transparent")
        self.assertEqual(tuple(out_arr[4, 4, :3]), GREEN, "foreground color should be untouched")
        self.assertEqual(out_arr[4, 4, 3], 255, "foreground alpha should remain opaque")

    def test_color_key_respects_tolerance(self):
        img = solid((4, 4), (250, 5, 250))  # near-magenta, not exact
        out_strict = apply_color_key(img, {"mode": "color_key", "color": "#ff00ff", "tolerance": 0})
        out_loose = apply_color_key(img, {"mode": "color_key", "color": "#ff00ff", "tolerance": 10})

        self.assertEqual(np.array(out_strict)[0, 0, 3], 255, "tight tolerance should not match a near-color")
        self.assertEqual(np.array(out_loose)[0, 0, 3], 0, "loose tolerance should match a near-color")


class EdgeFloodTests(unittest.TestCase):
    def test_enclosed_color_is_preserved(self):
        # 10x10 magenta field; a green ring with a magenta-colored "hole" in the middle.
        img = solid((10, 10), MAGENTA)
        arr = np.array(img)
        arr[2:8, 2:8, :3] = GREEN          # green ring/body
        arr[4:6, 4:6, :3] = list(MAGENTA)  # enclosed magenta hole, not touching the frame edge
        img = Image.fromarray(arr, "RGBA")

        out = apply_edge_flood(img, {"mode": "edge_flood_color_key", "color": "#ff00ff", "tolerance": 0}, (0, 0, 10, 10))
        out_arr = np.array(out)

        self.assertEqual(out_arr[0, 0, 3], 0, "edge-connected magenta should be removed")
        self.assertEqual(out_arr[5, 5, 3], 255, "enclosed magenta hole should survive edge-flood removal")
        self.assertEqual(out_arr[3, 3, 3], 255, "green ring should remain opaque")


class NormalizeEndToEndTests(unittest.TestCase):
    def test_resize_and_anchor_placement(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source_dir = tmp_path / "source"
            source_dir.mkdir()

            # A large (256x256) source: magenta background, a 120x180 green rectangle
            # bottom-anchored in the lower half, simulating an oversized AI render.
            src = solid((256, 256), MAGENTA)
            arr = np.array(src)
            arr[60:240, 68:188, :3] = GREEN
            Image.fromarray(arr, "RGBA").save(source_dir / "source.png")

            manifest = {
                "version": 1,
                "id": "test_hero_idle_s",
                "target": {
                    "outputPath": "../output/test_hero_idle_s.png",
                    "cellPx": [32, 48],
                    "cols": 1,
                    "rows": 1,
                },
                "sources": {
                    "source_sheet": {
                        "path": "../source/source.png",
                        "background": {"mode": "color_key", "color": "#ff00ff", "tolerance": 0},
                    }
                },
                "frames": [
                    {"sourceRef": "source_sheet", "destCell": [0, 0], "trim": "alpha", "fit": "contain", "anchor": "center_bottom"},
                ],
            }
            manifests_dir = tmp_path / "manifests"
            manifests_dir.mkdir()
            manifest_path = manifests_dir / "test_hero_idle_s.manifest.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            result = normalize_asset_sheet(manifest_path)

            self.assertEqual((result["width"], result["height"]), (32, 48))
            out_img = Image.open(tmp_path / "output" / "test_hero_idle_s.png").convert("RGBA")
            out_arr = np.array(out_img)

            self.assertEqual(out_arr.shape, (48, 32, 4))
            rows_with_content = np.where(np.any(out_arr[:, :, 3] > 0, axis=1))[0]
            self.assertGreater(len(rows_with_content), 0, "resized sprite should not be empty")
            self.assertGreaterEqual(rows_with_content.max(), 44, "center_bottom anchor should place content near the cell's bottom edge")

    def test_inherits_grid_mismatch_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            manifests_dir = tmp_path / "manifests"
            manifests_dir.mkdir()

            body = {
                "version": 1, "id": "test_hero_body_idle_s",
                "target": {"outputPath": "body.png", "cellPx": [32, 48], "cols": 4, "rows": 1},
                "sources": {}, "frames": [],
            }
            (manifests_dir / "test_hero_body_idle_s.manifest.json").write_text(json.dumps(body), encoding="utf-8")

            armor = {
                "version": 1, "id": "test_hero_armor_idle_s",
                "target": {
                    "outputPath": "armor.png", "cellPx": [32, 48], "cols": 6, "rows": 1,
                    "inherits": "test_hero_body_idle_s.manifest.json",
                },
                "sources": {}, "frames": [],
            }
            armor_path = manifests_dir / "test_hero_armor_idle_s.manifest.json"
            armor_path.write_text(json.dumps(armor), encoding="utf-8")

            errors = collect_manifest_errors(armor_path, check_output=False)
            self.assertTrue(any("grid mismatch" in e for e in errors), f"expected a grid-mismatch error, got: {errors}")


if __name__ == "__main__":
    sys.exit(unittest.main())
