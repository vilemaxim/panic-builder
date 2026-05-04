#!/usr/bin/env python3
"""Build PWA / install icons and favicon from the Panic at the Dojo wordmark."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "assets" / "images" / "branding" / "panic_at_the_dojo_logo.png"
WEB = ROOT / "web"
ICONS = WEB / "icons"


def _parse_hex_rgb(s: str) -> tuple[int, int, int]:
    s = s.strip().lstrip("#")
    return int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)


def _manifest_bg_rgb() -> tuple[int, int, int]:
    manifest = WEB / "manifest.json"
    raw = manifest.read_text(encoding="utf-8")
    m = re.search(r'"background_color"\s*:\s*"([^"]+)"', raw)
    if not m:
        return 246, 238, 214
    hexv = m.group(1)
    if hexv.startswith("#") and len(hexv) == 7:
        return _parse_hex_rgb(hexv[1:])
    return _parse_hex_rgb(hexv)


def _square_with_logo(
    logo_rgba: Image.Image,
    size: int,
    *,
    logo_max_frac: float,
    bg_rgb: tuple[int, int, int],
) -> Image.Image:
    """Place the logo centered on a square; logo_max_frac caps max(width,height) vs canvas."""
    canvas = Image.new("RGBA", (size, size), (*bg_rgb, 255))
    lw, lh = logo_rgba.size
    cap = int(size * logo_max_frac)
    scale = min(cap / lw, cap / lh)
    nw = max(1, int(round(lw * scale)))
    nh = max(1, int(round(lh * scale)))
    resized = logo_rgba.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (size - nw) // 2
    y = (size - nh) // 2
    canvas.alpha_composite(resized, (x, y))
    return canvas


def main() -> int:
    if not LOGO.is_file():
        print(f"Missing logo: {LOGO}", file=sys.stderr)
        return 1

    bg = _manifest_bg_rgb()
    logo = Image.open(LOGO).convert("RGBA")

    ICONS.mkdir(parents=True, exist_ok=True)

    # Regular: readable on home screen; maskable: smaller mark for OS mask / corner radius.
    specs: list[tuple[str, int, float]] = [
        ("Icon-180.png", 180, 0.78),  # iOS home-screen (preferred over generic 192)
        ("Icon-192.png", 192, 0.78),
        ("Icon-512.png", 512, 0.78),
        ("Icon-maskable-192.png", 192, 0.52),
        ("Icon-maskable-512.png", 512, 0.52),
    ]
    for name, px, frac in specs:
        out = _square_with_logo(logo, px, logo_max_frac=frac, bg_rgb=bg)
        out.save(ICONS / name, format="PNG", optimize=True)

    fav = _square_with_logo(logo, 32, logo_max_frac=0.85, bg_rgb=bg)
    fav.save(WEB / "favicon.png", format="PNG", optimize=True)

    for p in [ICONS / "Icon-512.png", WEB / "favicon.png"]:
        print(p.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
