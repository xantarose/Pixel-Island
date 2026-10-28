#!/usr/bin/env python3
"""Draws the 1024x1024 app icon: a white and a black cat under a sakura branch.

Pixel art on a 64x64 grid, scaled 16x. Run from the repo root:
    python3 tools/sprites/make_icon.py
"""
import os
import random
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate  # noqa: E402

OUT = os.path.join(generate.ROOT, "App", "Resources", "Assets.xcassets",
                   "AppIcon.appiconset", "icon.png")

GRID = 64
SCALE = 1024 // GRID

# Night sky fading into a pink glow (top to bottom bands).
SKY = ["#1B1022", "#22132B", "#2B1733", "#361B3C", "#432044", "#52264C", "#632D54"]
BRANCH = "#3A2230"
BRANCH_LIGHT = "#55303F"
BLOSSOM = "#FFB7CE"
BLOSSOM_LIGHT = "#FFE3EE"
BLOSSOM_DARK = "#F58CB0"
CENTER = "#FFE27A"
GROUND = "#2A1A2E"
GROUND_TOP = "#4A2A48"
HEART = ["..PP.PP..", ".PPPPPPP.", ".PWPPPPP.", ".PPPPPPP.", "..PPPPP..", "...PPP...", "....P...."]
HEART_COLORS = {"P": "#FF6F9F", "W": "#FFE3EE"}


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class Canvas:
    def __init__(self):
        self.px = [[rgb(SKY[0])] * GRID for _ in range(GRID)]

    def set(self, x, y, color):
        if 0 <= x < GRID and 0 <= y < GRID:
            self.px[y][x] = rgb(color) if isinstance(color, str) else color

    def image(self):
        img = Image.new("RGB", (GRID * SCALE, GRID * SCALE))
        for y in range(GRID):
            for x in range(GRID):
                img.paste(self.px[y][x], (x * SCALE, y * SCALE, (x + 1) * SCALE, (y + 1) * SCALE))
        return img


def sky(c):
    band = GRID / len(SKY)
    for y in range(GRID):
        for x in range(GRID):
            i = int(y / band)
            # Checker dither on band edges for a soft pixel gradient.
            if i + 1 < len(SKY) and (y % int(band)) >= int(band) - 2 and (x + y) % 2 == 0:
                i += 1
            c.set(x, y, SKY[min(i, len(SKY) - 1)])


def flower(c, x, y, big=False):
    petals = [(0, -1), (-1, 0), (1, 0), (0, 1)] if not big else \
        [(0, -1), (-1, 0), (1, 0), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)]
    for dx, dy in petals:
        c.set(x + dx, y + dy, BLOSSOM)
    if big:
        for dx, dy in [(0, -2), (-2, 0), (2, 0), (0, 2)]:
            c.set(x + dx, y + dy, BLOSSOM_DARK)
        c.set(x - 1, y - 1, BLOSSOM_LIGHT)
    c.set(x, y, CENTER)


def branch(c):
    # A branch reaching in from the top-left corner, with a few twigs.
    path = [(0, 7), (1, 7), (2, 6), (3, 6), (4, 6), (5, 5), (6, 5), (7, 5), (8, 4), (9, 4), (10, 4),
            (11, 4), (12, 3), (13, 3), (14, 3), (15, 3), (16, 2), (17, 2), (18, 2), (19, 2), (20, 2),
            (21, 1), (22, 1), (23, 1), (24, 1), (25, 1), (26, 1), (27, 0), (28, 0), (29, 0)]
    for x, y in path:
        c.set(x, y, BRANCH)
        c.set(x, y + 1, BRANCH)
        c.set(x, y - 1, BRANCH_LIGHT)
    for x, y in [(8, 5), (8, 6), (9, 7), (9, 8), (17, 3), (18, 4), (19, 5), (24, 2), (25, 3)]:
        c.set(x, y, BRANCH)
    for x, y, big in [(3, 9, True), (10, 9, True), (6, 3, False), (14, 6, True), (19, 7, True),
                      (21, 4, False), (27, 4, True), (31, 2, True), (12, 1, False), (35, 1, False),
                      (25, 7, False)]:
        flower(c, x, y, big)


def petals(c):
    rng = random.Random(7)
    for _ in range(26):
        x, y = rng.randrange(GRID), rng.randrange(10, 50)
        color = rng.choice([BLOSSOM, BLOSSOM_LIGHT, BLOSSOM_DARK])
        c.set(x, y, color)
        if rng.random() < 0.5:
            c.set(x + 1, y + (1 if rng.random() < 0.5 else 0), color)


def ground(c):
    for x in range(GRID):
        top = 58 + (1 if (x // 7) % 2 else 0)
        for y in range(top, GRID):
            c.set(x, y, GROUND)
        c.set(x, top, GROUND_TOP)
    for x in range(1, GRID, 5):
        c.set(x, 57, BLOSSOM_DARK)


def cat(c, pet_id, left, top, flipped, scale=2):
    pets = {p[0]: p for p in generate.build()}
    _, _, _, palette, frames = pets[pet_id]
    frame = frames["sit"][0]
    for k, ch in enumerate(frame):
        if ch == ".":
            continue
        y, x = divmod(k, generate.SIZE)
        if flipped:
            x = generate.SIZE - 1 - x
        for yy in range(scale):
            for xx in range(scale):
                c.set(left + x * scale + xx, top + y * scale + yy, palette[ch])


def heart(c, x, y):
    for dy, row in enumerate(HEART):
        for dx, ch in enumerate(row):
            if ch in HEART_COLORS:
                c.set(x + dx, y + dy, HEART_COLORS[ch])


def main():
    c = Canvas()
    sky(c)
    branch(c)
    petals(c)
    ground(c)
    cat(c, "cat.snowwhite", 1, 28, flipped=False)
    cat(c, "cat.bombay", 31, 28, flipped=True)
    heart(c, 27, 24)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    c.image().save(OUT)
    print("icon ->", os.path.relpath(OUT, generate.ROOT))


if __name__ == "__main__":
    main()
