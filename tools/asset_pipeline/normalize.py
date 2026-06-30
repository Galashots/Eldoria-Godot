#!/usr/bin/env python3
"""CLI: normalize one asset sheet from its manifest.

Usage: python tools/asset_pipeline/normalize.py --manifest <path>
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from manifest import normalize_asset_sheet


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalize an AI-generated source sheet into a Godot-ready PNG.")
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()

    try:
        normalize_asset_sheet(args.manifest)
    except (ValueError, OSError) as e:
        print(str(e), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
