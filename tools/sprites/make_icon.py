#!/usr/bin/env python3
"""Draws the 1024x1024 app icon from the ginger cat sprite.

Run from the repo root:  python3 tools/sprites/make_icon.py
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate  # noqa: E402

OUT = os.path.join(generate.ROOT, "App", "Resources", "Assets.xcassets",
                   "AppIcon.appiconset", "icon.png")

BACKGROUND = (26, 17, 30)
ISLAND = (0, 0, 0)
HEART = ["..oo.oo..", ".oPPoPPo.", ".oPWPPPo.", ".oPPPPPo.", "..oPPPo..", "...oPo...", "....o...."]
HEART_COLORS = {"o": (90, 31, 54), "P": (255, 111, 159), "W": (255, 227, 238)}


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def blit(img, rows, colors, left, top, scale):
    for y, line in enumerate(rows):
        for x, c in enumerate(line):
            if c in colors:
                x0, y0 = left + x * scale, top + y * scale
                for yy in range(scale):
                    for xx in range(scale):
                        img.putpixel((x0 + xx, y0 + yy), colors[c])


def main():
    pets = {p[0]: p for p in generate.build()}
    _, _, _, palette, frames = pets["cat.ginger"]
    colors = {k: hex_rgb(v) for k, v in palette.items()}

    img = Image.new("RGB", (1024, 1024), BACKGROUND)

    # Dynamic Island pill across the top third.
    pill = Image.new("RGB", (760, 210), ISLAND)
    mask = Image.new("L", (760, 210), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 759, 209), radius=105, fill=255)
    img.paste(pill, (132, 120), mask)

    # Cat in the pill, heart on the right side of the pill.
    blit(img, frames["idle"][0], colors, 190, 76, 14)
    blit(img, HEART, HEART_COLORS, 690, 170, 14)

    # Big walking cat below: "lives on your island".
    blit(img, frames["walk"][0], colors, 160, 272, 44)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT)
    print("icon ->", os.path.relpath(OUT, generate.ROOT))


if __name__ == "__main__":
    main()
