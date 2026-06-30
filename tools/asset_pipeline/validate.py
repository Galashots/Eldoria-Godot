#!/usr/bin/env python3
"""CLI: validate one asset manifest and its output PNG.

Usage: python tools/asset_pipeline/validate.py --manifest <path>
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from manifest import collect_manifest_errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate an asset manifest and its normalized output PNG.")
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()

    errors = collect_manifest_errors(args.manifest, check_output=True)
    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        return 1
    print(f"{args.manifest}: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
