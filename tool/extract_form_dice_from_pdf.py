#!/usr/bin/env python3
"""Extract per-form Action Dice art from the Panic at the Dojo 1e rulebook PDF.

Most forms embed dice as a tall raster (~375px wide, height > 236). Dance and Shadow
use a shorter 375×236 strip instead; those are selected by uncompressed size (>15 KiB),
since the book also repeats smaller 375×236 decorations on every spread.
"""

from __future__ import annotations

import glob
import os
import shutil
import struct
import subprocess
import sys

PDF = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "Source Material",
    "Panic_at_the_Dojo.pdf",
)

# PDF page index (1-based) -> rules.json form id (Chapter 4 spreads).
FORM_PAGES: list[tuple[int, str]] = [
    (49, "form_blaster"),
    (50, "form_control"),
    (51, "form_dance"),
    (52, "form_iron"),
    (53, "form_one_two"),
    (54, "form_power"),
    (55, "form_reversal"),
    (56, "form_shadow"),
    (57, "form_song"),
    (58, "form_vigilance"),
    (59, "form_wild"),
    (60, "form_zen"),
]

# Short-strip dice graphic (Dance / Shadow); larger than repeated UI chrome.
_MIN_SHORT_STRIP_BYTES = 15_000


def png_size(path: str) -> tuple[int, int] | None:
    with open(path, "rb") as f:
        if f.read(8) != b"\x89PNG\r\n\x1a\n":
            return None
        f.read(4)
        if f.read(4) != b"IHDR":
            return None
        w, h = struct.unpack(">II", f.read(8))
        return w, h


def pick_action_dice_png(paths: list[str]) -> str | None:
    tall: list[tuple[int, str]] = []
    short_fat: list[tuple[int, str]] = []
    for path in paths:
        wh = png_size(path)
        if not wh:
            continue
        w, h = wh
        if w != 375:
            continue
        sz = os.path.getsize(path)
        if h > 236:
            tall.append((sz, path))
        elif h == 236 and sz >= _MIN_SHORT_STRIP_BYTES:
            short_fat.append((sz, path))
    if tall:
        tall.sort(key=lambda t: -t[0])
        return tall[0][1]
    if short_fat:
        short_fat.sort(key=lambda t: -t[0])
        return short_fat[0][1]
    return None


def main() -> int:
    dest_root = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "assets",
        "images",
        "forms",
        "action_dice",
    )
    os.makedirs(dest_root, exist_ok=True)

    tmp = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "assets",
        "_pdf_extract_run",
    )
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp, exist_ok=True)

    if not os.path.isfile(PDF):
        print(f"Missing PDF: {PDF}", file=sys.stderr)
        return 1

    for page, form_id in FORM_PAGES:
        prefix = os.path.join(tmp, "x")
        subprocess.run(
            [
                "pdfimages",
                "-png",
                "-f",
                str(page),
                "-l",
                str(page),
                PDF,
                prefix,
            ],
            check=True,
        )
        paths = sorted(glob.glob(prefix + "-*.png"))
        src = pick_action_dice_png(paths)
        if src is None:
            print(f"No dice raster on page {page} ({form_id})", file=sys.stderr)
            shutil.rmtree(tmp, ignore_errors=True)
            return 1
        out = os.path.join(dest_root, f"{form_id}_action_dice.png")
        shutil.copy2(src, out)
        wh = png_size(src)
        print(f"{out}  ({wh[0]}×{wh[1]}, {os.path.getsize(src)} bytes)")

    shutil.rmtree(tmp, ignore_errors=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
