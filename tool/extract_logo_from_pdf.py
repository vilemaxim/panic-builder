#!/usr/bin/env python3
"""Extract the Panic at the Dojo wordmark from the rulebook PDF (inside cover raster)."""

import os
import shutil
import subprocess
import sys

PDF = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "Source Material",
    "Panic_at_the_Dojo.pdf",
)


def main() -> int:
    if not os.path.isfile(PDF):
        print(f"Missing PDF: {PDF}", file=sys.stderr)
        return 1

    tmp = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "assets",
        "_pdf_logo_extract",
    )
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp, exist_ok=True)
    prefix = os.path.join(tmp, "img")
    subprocess.run(
        ["pdfimages", "-png", "-f", "2", "-l", "2", PDF, prefix],
        check=True,
    )

    # Page 2: 808×330 title treatment (larger asset is the opaque art; smaller is soft-mask).
    candidates = sorted(
        (os.path.getsize(p), p)
        for p in (
            os.path.join(tmp, "img-003.png"),
            os.path.join(tmp, "img-004.png"),
        )
        if os.path.isfile(p)
    )
    if not candidates:
        print("Expected logo rasters not found on PDF page 2.", file=sys.stderr)
        return 1

    _sz, src = candidates[-1]
    dest_dir = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "assets",
        "images",
        "branding",
    )
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, "panic_at_the_dojo_logo.png")
    shutil.copy2(src, dest)
    shutil.rmtree(tmp, ignore_errors=True)
    print(dest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
