"""Asset normalization pipeline core: manifest schema, validation, and image
processing. See docs/art/ASSET_NORMALIZATION_PIPELINE.md for the manifest spec.

Pipeline rule: AI source image -> manifest -> normalize -> validate -> repo asset.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

ID_RE = re.compile(r"^[a-z0-9]+(?:_[a-z0-9]+)*$")
HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")
BACKGROUND_MODES = {"alpha", "color_key", "edge_flood_color_key"}
ANCHORS = {"center", "center_bottom", "top_left"}


def load_manifest(manifest_path: Path) -> dict:
    return json.loads(Path(manifest_path).read_text(encoding="utf-8"))


def _err(manifest_path: Path, ctx: str, msg: str) -> str:
    return f"{manifest_path}{f' [{ctx}]' if ctx else ''}: {msg}"


def _pos_int(v: Any) -> bool:
    return isinstance(v, int) and not isinstance(v, bool) and v > 0


def _pair(v: Any, allow_zero: bool = False) -> bool:
    if not (isinstance(v, list) and len(v) == 2):
        return False
    return all(isinstance(x, int) and not isinstance(x, bool) and (x >= 0 if allow_zero else x > 0) for x in v)


def _rect(v: Any) -> bool:
    if not (isinstance(v, list) and len(v) == 4
            and all(isinstance(x, int) and not isinstance(x, bool) and x >= 0 for x in v)):
        return False
    return v[2] > 0 and v[3] > 0


def parse_hex_color(value: Any) -> tuple[int, int, int]:
    if not isinstance(value, str) or not HEX_RE.match(value):
        raise ValueError(f"Invalid color key {value!r}; expected #rrggbb.")
    return int(value[1:3], 16), int(value[3:5], 16), int(value[5:7], 16)


def key_config(bg: dict) -> tuple[int, int, int, int]:
    r, g, b = parse_hex_color(bg.get("color"))
    tol = bg.get("tolerance", 0)
    if not (isinstance(tol, int) and not isinstance(tol, bool) and 0 <= tol <= 255):
        raise ValueError(f"Invalid color-key tolerance {tol!r}; expected an integer from 0 to 255.")
    return r, g, b, tol


def _source_entries(manifest: dict) -> list[dict]:
    sources = manifest.get("sources", {})
    if isinstance(sources, list):
        return [{"ref": s.get("id") or s.get("ref") or f"source_{i}", **s} for i, s in enumerate(sources)]
    return [{"ref": ref, **s} for ref, s in sources.items()]


def read_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def apply_color_key(img: Image.Image, bg: dict | None) -> Image.Image:
    """Zero the alpha of every pixel matching the key color within tolerance."""
    if not bg or bg.get("mode") in (None, "alpha", "edge_flood_color_key"):
        return img
    if bg.get("mode") != "color_key":
        raise ValueError(f"Unsupported background mode: {bg.get('mode')}")
    r, g, b, tol = key_config(bg)
    arr = np.array(img)
    diff = np.abs(arr[:, :, :3].astype(np.int16) - np.array([r, g, b], dtype=np.int16))
    matches = np.all(diff <= tol, axis=-1)
    arr[matches, 3] = 0
    return Image.fromarray(arr, "RGBA")


def apply_edge_flood(img: Image.Image, bg: dict | None, source_rect: tuple[int, int, int, int]) -> Image.Image:
    """Flood-fill-remove key-colored pixels connected to the edge of source_rect,
    preserving same-colored pixels fully enclosed within the sprite."""
    if not bg or bg.get("mode") != "edge_flood_color_key":
        return img
    r, g, b, tol = key_config(bg)
    arr = np.array(img)
    x, y, w, h = source_rect
    region = arr[y:y + h, x:x + w, :3].astype(np.int16)
    diff = np.abs(region - np.array([r, g, b], dtype=np.int16))
    is_key = np.all(diff <= tol, axis=-1)

    visited = np.zeros((h, w), dtype=bool)
    queue: list[tuple[int, int]] = []

    def enqueue(lx: int, ly: int) -> None:
        if 0 <= lx < w and 0 <= ly < h and is_key[ly, lx] and not visited[ly, lx]:
            visited[ly, lx] = True
            queue.append((lx, ly))

    for lx in range(w):
        enqueue(lx, 0)
        enqueue(lx, h - 1)
    for ly in range(h):
        enqueue(0, ly)
        enqueue(w - 1, ly)

    cursor = 0
    while cursor < len(queue):
        lx, ly = queue[cursor]
        cursor += 1
        enqueue(lx - 1, ly)
        enqueue(lx + 1, ly)
        enqueue(lx, ly - 1)
        enqueue(lx, ly + 1)

    sub_alpha = arr[y:y + h, x:x + w, 3]
    sub_alpha[visited] = 0
    arr[y:y + h, x:x + w, 3] = sub_alpha
    return Image.fromarray(arr, "RGBA")


def alpha_bounds(img: Image.Image, rect: tuple[int, int, int, int]) -> tuple[int, int, int, int] | None:
    x, y, w, h = rect
    arr = np.array(img)[y:y + h, x:x + w, 3]
    rows = np.any(arr > 0, axis=1)
    cols = np.any(arr > 0, axis=0)
    if not rows.any():
        return None
    y0, y1 = np.where(rows)[0][[0, -1]]
    x0, x1 = np.where(cols)[0][[0, -1]]
    return int(x + x0), int(y + y0), int(x1 - x0 + 1), int(y1 - y0 + 1)


def resize_contain_premultiplied(img: Image.Image, target_wh: tuple[int, int]) -> Image.Image:
    """Downscale img to fit within target_wh (preserving aspect ratio) using a
    high-quality Lanczos filter on alpha-premultiplied color, then un-premultiply.

    Premultiplying avoids the dark/light fringing that a naive RGBA resize produces
    at transparent edges; this is the fix for the nearest-neighbor quality loss
    found in the prior Node-based pipeline.
    """
    cw, ch = target_wh
    sw, sh = img.size
    scale = min(cw / sw, ch / sh)
    dw, dh = max(1, round(sw * scale)), max(1, round(sh * scale))

    arr = np.array(img).astype(np.float64)
    alpha = arr[:, :, 3:4] / 255.0
    premultiplied = arr[:, :, :3] * alpha
    premult_img = Image.fromarray(premultiplied.astype(np.uint8), "RGB")
    alpha_img = Image.fromarray(arr[:, :, 3].astype(np.uint8), "L")

    premult_resized = np.array(premult_img.resize((dw, dh), Image.LANCZOS)).astype(np.float64)
    alpha_resized = np.array(alpha_img.resize((dw, dh), Image.LANCZOS)).astype(np.float64)

    safe_alpha = np.where(alpha_resized > 0, alpha_resized, 1.0)
    rgb_out = np.clip(premult_resized / (safe_alpha[:, :, None] / 255.0), 0, 255)
    rgb_out[alpha_resized == 0] = 0

    out = np.dstack([rgb_out, alpha_resized]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def paste_anchored(dst: Image.Image, src: Image.Image, dest_cell: tuple[int, int],
                    cell_px: tuple[int, int], anchor: str) -> None:
    cw, ch = cell_px
    dw, dh = src.size
    if anchor == "top_left":
        ox, oy = 0, 0
    elif anchor == "center":
        ox, oy = (cw - dw) // 2, (ch - dh) // 2
    else:  # center_bottom
        ox, oy = (cw - dw) // 2, ch - dh
    base_x = dest_cell[0] * cw + ox
    base_y = dest_cell[1] * ch + oy
    dst.alpha_composite(src, (base_x, base_y))


def _source_rect(img: Image.Image, source: dict, frame: dict) -> tuple[int, int, int, int]:
    if "sourceCell" in frame:
        grid = source.get("grid")
        cw, ch = img.width / grid["cols"], img.height / grid["rows"]
        col, row = frame["sourceCell"]
        return int(col * cw), int(row * ch), int(cw), int(ch)
    if "sourceRect" in frame:
        x, y, w, h = frame["sourceRect"]
        return x, y, w, h
    return 0, 0, img.width, img.height


def collect_manifest_errors(manifest_path: Path, check_output: bool = True) -> list[str]:
    manifest_path = Path(manifest_path)
    out: list[str] = []
    folder = manifest_path.resolve().parent
    try:
        m = load_manifest(manifest_path)
    except (OSError, json.JSONDecodeError) as e:
        return [_err(manifest_path, "", f"failed to parse JSON: {e}")]

    if m.get("version") != 1:
        out.append(_err(manifest_path, "version", "version must be 1."))
    if not (isinstance(m.get("id"), str) and ID_RE.match(m["id"])):
        out.append(_err(manifest_path, "id", "id must be lowercase snake_case."))

    t = m.get("target", {})
    if not (isinstance(t.get("outputPath"), str) and t["outputPath"].strip()):
        out.append(_err(manifest_path, "target.outputPath", "target.outputPath is required."))
    if not _pair(t.get("cellPx")):
        out.append(_err(manifest_path, "target.cellPx", "target.cellPx must be [positiveInt, positiveInt]."))
    if not (_pos_int(t.get("cols")) and _pos_int(t.get("rows"))):
        out.append(_err(manifest_path, "target", "target.cols and target.rows must be positive integers."))

    if t.get("inherits"):
        inherited_path = folder / t["inherits"]
        if not inherited_path.exists():
            out.append(_err(manifest_path, "target.inherits", f"inherited manifest does not exist: {t['inherits']}"))
        else:
            try:
                im = load_manifest(inherited_path)
                it = im.get("target", {})
                if (it.get("cellPx"), it.get("cols"), it.get("rows")) != (t.get("cellPx"), t.get("cols"), t.get("rows")):
                    out.append(_err(
                        manifest_path, "target.inherits",
                        f"grid mismatch with {t['inherits']}: expected cellPx={it.get('cellPx')} "
                        f"cols={it.get('cols')} rows={it.get('rows')}, got cellPx={t.get('cellPx')} "
                        f"cols={t.get('cols')} rows={t.get('rows')}.",
                    ))
            except (OSError, json.JSONDecodeError) as e:
                out.append(_err(manifest_path, "target.inherits", f"failed to parse inherited manifest: {e}"))

    sources = _source_entries(m)
    if not sources:
        out.append(_err(manifest_path, "sources", "sources must be present and non-empty."))
    by_ref: dict[str, dict] = {}
    source_images: dict[str, Image.Image] = {}
    for s in sources:
        if s["ref"] in by_ref:
            out.append(_err(manifest_path, f"sources.{s['ref']}", "duplicate source reference."))
        by_ref[s["ref"]] = s
        p = folder / s.get("path", "")
        if not s.get("path") or not p.exists():
            out.append(_err(manifest_path, f"sources.{s['ref']}", f"source file does not exist: {s.get('path')}"))
            continue
        try:
            img = read_rgba(p)
        except Exception as e:  # noqa: BLE001 - surfacing as a manifest error, not a crash
            out.append(_err(manifest_path, f"sources.{s['ref']}", str(e)))
            continue
        source_images[s["ref"]] = img
        bg = s.get("background")
        if bg and bg.get("mode") not in BACKGROUND_MODES:
            out.append(_err(manifest_path, f"sources.{s['ref']}.background.mode",
                             "background.mode must be alpha, color_key, or edge_flood_color_key."))
        if bg and bg.get("mode") in ("color_key", "edge_flood_color_key"):
            try:
                key_config(bg)
            except ValueError as e:
                out.append(_err(manifest_path, f"sources.{s['ref']}.background", str(e)))
        grid = s.get("grid")
        if grid and not (_pos_int(grid.get("cols")) and _pos_int(grid.get("rows"))
                          and img.width % grid["cols"] == 0 and img.height % grid["rows"] == 0):
            out.append(_err(manifest_path, f"sources.{s['ref']}.grid",
                             "source dimensions must divide evenly by positive grid cols and rows."))

    frames = m.get("frames")
    if not (isinstance(frames, list) and frames):
        out.append(_err(manifest_path, "frames", "frames must be a non-empty array."))
    seen_cells: set[str] = set()
    for i, f in enumerate(frames if isinstance(frames, list) else []):
        c = f"frames[{i}]"
        if not _pair(f.get("destCell"), allow_zero=True):
            out.append(_err(manifest_path, f"{c}.destCell", "destCell must be [col, row]."))
        else:
            if f["destCell"][0] >= t.get("cols", 0) or f["destCell"][1] >= t.get("rows", 0):
                out.append(_err(manifest_path, f"{c}.destCell", "destCell is outside target grid."))
            key = ",".join(map(str, f["destCell"]))
            if key in seen_cells:
                out.append(_err(manifest_path, f"{c}.destCell", "duplicate destCell."))
            seen_cells.add(key)

        s = by_ref.get(f.get("sourceRef")) if f.get("sourceRef") else None
        if not s:
            out.append(_err(manifest_path, c, f"unknown sourceRef: {f.get('sourceRef')}" if f.get("sourceRef")
                             else "frame must include sourceRef."))
            continue
        img = source_images.get(s["ref"])
        if img is None:
            continue
        if "sourceCell" in f:
            grid = s.get("grid")
            if not grid:
                out.append(_err(manifest_path, f"{c}.sourceCell", "sourceCell requires a source grid."))
            elif not _pair(f["sourceCell"], allow_zero=True) or f["sourceCell"][0] >= grid["cols"] or f["sourceCell"][1] >= grid["rows"]:
                out.append(_err(manifest_path, f"{c}.sourceCell", "sourceCell is outside source grid."))
        if "sourceRect" in f:
            r = f["sourceRect"]
            if not _rect(r) or r[0] + r[2] > img.width or r[1] + r[3] > img.height:
                out.append(_err(manifest_path, f"{c}.sourceRect", "sourceRect is invalid or outside source image."))
        if "trim" in f and f["trim"] not in ("alpha", "none"):
            out.append(_err(manifest_path, f"{c}.trim", "trim must be alpha or none."))
        if "fit" in f and f["fit"] != "contain":
            out.append(_err(manifest_path, f"{c}.fit", "only fit contain is supported."))
        if "anchor" in f and f["anchor"] not in ANCHORS:
            out.append(_err(manifest_path, f"{c}.anchor", "anchor must be center, center_bottom, or top_left."))

    expected_empty = t.get("expectedEmptyCells", [])
    if not isinstance(expected_empty, list):
        out.append(_err(manifest_path, "target.expectedEmptyCells", "expectedEmptyCells must be an array."))
    else:
        for i, cell in enumerate(expected_empty):
            if not _pair(cell, allow_zero=True) or cell[0] >= t.get("cols", 0) or cell[1] >= t.get("rows", 0):
                out.append(_err(manifest_path, f"target.expectedEmptyCells[{i}]", "expected empty cell is outside the target grid."))

    if check_output and t.get("outputPath"):
        op = folder / t["outputPath"]
        if not op.exists():
            out.append(_err(manifest_path, "target.outputPath", f"output PNG does not exist: {t['outputPath']}"))
        else:
            try:
                img = read_rgba(op)
                ew, eh = t["cellPx"][0] * t["cols"], t["cellPx"][1] * t["rows"]
                if (img.width, img.height) != (ew, eh):
                    out.append(_err(manifest_path, "target.outputPath",
                                     f"output dimensions {img.width}x{img.height} do not equal expected {ew}x{eh}."))
                for cell in expected_empty if isinstance(expected_empty, list) else []:
                    if _pair(cell, allow_zero=True) and cell[0] < t.get("cols", 0) and cell[1] < t.get("rows", 0):
                        cw, ch = t["cellPx"]
                        region = np.array(img)[cell[1] * ch:(cell[1] + 1) * ch, cell[0] * cw:(cell[0] + 1) * cw, 3]
                        if np.any(region != 0):
                            out.append(_err(manifest_path, "target.expectedEmptyCells",
                                             f"expected empty cell {cell} is not fully transparent."))
            except Exception as e:  # noqa: BLE001
                out.append(_err(manifest_path, "target.outputPath", str(e)))

    return out


def normalize_asset_sheet(manifest_path: Path) -> dict:
    manifest_path = Path(manifest_path)
    errors = collect_manifest_errors(manifest_path, check_output=False)
    if errors:
        raise ValueError("\n".join(errors))

    m = load_manifest(manifest_path)
    folder = manifest_path.resolve().parent
    t = m["target"]
    cw, ch = t["cellPx"]
    output = Image.new("RGBA", (cw * t["cols"], ch * t["rows"]), (0, 0, 0, 0))
    by_ref = {s["ref"]: s for s in _source_entries(m)}
    cache: dict[str, Image.Image] = {}

    for f in m["frames"]:
        s = by_ref[f["sourceRef"]]
        if s["ref"] not in cache:
            cache[s["ref"]] = apply_color_key(read_rgba(folder / s["path"]), s.get("background"))
        source_image = cache[s["ref"]]
        sr = _source_rect(source_image, s, f)
        img = apply_edge_flood(source_image, s.get("background"), sr)
        bounds = alpha_bounds(img, sr)
        if bounds is None:
            raise ValueError(f"frame {f.get('destCell')} contains no non-transparent pixels.")
        region = sr if f.get("trim", "alpha") == "none" else bounds
        cropped = img.crop((region[0], region[1], region[0] + region[2], region[1] + region[3]))
        resized = resize_contain_premultiplied(cropped, (cw, ch))
        paste_anchored(output, resized, tuple(f["destCell"]), (cw, ch), f.get("anchor", "center_bottom"))

    out_path = folder / t["outputPath"]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(out_path)
    print(f"Asset sheet normalized: {m['id']} -> {t['outputPath']} "
          f"({output.width}x{output.height}, {t['cols']}x{t['rows']}, cell {cw}x{ch})")
    return {"id": m["id"], "outputPath": str(out_path), "width": output.width, "height": output.height,
            "cols": t["cols"], "rows": t["rows"], "cellPx": [cw, ch]}
