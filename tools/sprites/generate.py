#!/usr/bin/env python3
"""Pixel Island sprite generator.

Draws every pet on a 16x16 grid, colours it per breed, adds the outline and
writes two things:
  * Shared/Sprites/SpriteCatalog.generated.swift  - data the app reads
  * tools/sprites/preview.png                     - a sheet to eyeball the art

Run from the repo root:  python3 tools/sprites/generate.py
Needs Pillow only for the preview (pip install pillow).

How a sprite is described
-------------------------
Templates are drawn with *region* letters, not colours:
  a ear fur   p inner ear   h head fur   e eye    k closed eye   n nose
  m muzzle    b body fur    l belly      t tail   f legs         w tail tip
  u ear tuft  z sleep "Z"   x extra (species specific)
Each pet has a `paint(region, x, y)` function that turns a region into a
palette *role*. Roles are what the Swift side knows about:
  o outline  B base  D dark  L light  P pink  E eye  G accent  W white  S star
The outline is added automatically around the silhouette, so templates only
contain fills.
"""
from __future__ import annotations

import os
import sys

SIZE = 16
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SWIFT_OUT = os.path.join(ROOT, "Shared", "Sprites", "SpriteCatalog.generated.swift")
PREVIEW_OUT = os.path.join(ROOT, "tools", "sprites", "preview.png")

ROLES = "oBDLPEGWS"
NO_OUTLINE = {"z"}  # regions drawn without an outline ring


# ---------------------------------------------------------------- helpers

def g(rows: list[str]) -> list[list[str]]:
    """Validate and turn a list of 16 strings into a mutable grid."""
    assert len(rows) == SIZE, f"need {SIZE} rows, got {len(rows)}"
    for r in rows:
        assert len(r) == SIZE, f"row {r!r} is {len(r)} wide"
    return [list(r) for r in rows]


def copy(grid):
    return [row[:] for row in grid]


def put(grid, y, x, region):
    if 0 <= y < SIZE and 0 <= x < SIZE:
        grid[y][x] = region


def replace_region(grid, src, dst):
    for row in grid:
        for i, c in enumerate(row):
            if c == src:
                row[i] = dst


def add_outline(grid):
    """Every empty pixel touching a filled one (4-neighbourhood) becomes 'o'."""
    out = copy(grid)
    for y in range(SIZE):
        for x in range(SIZE):
            if grid[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < SIZE and 0 <= ny < SIZE:
                    c = grid[ny][nx]
                    if c != "." and c not in NO_OUTLINE and c != "o":
                        out[y][x] = "o"
                        break
    return out


# ------------------------------------------------------------ cat template
# Head occupies columns 9..14, ears start on `top` row. Walk/idle top = 4,
# sleep top = 7. Everything faces right; the app mirrors for walking left.

HEAD = [
    ".........a....a.",
    ".........pa..ap.",
    ".........hhhhhh.",
    ".........hehheh.",
    ".........hhnnhh.",
]

WALK_BODY = [
    "....bbbbbhhmmhh.",  # 9
    "...bbbbbbbbbbbb.",  # 10
    "...bbbbbbbbbbb..",  # 11
    "...bbllllllbbb..",  # 12
]

LEGS = [
    ["...f..f...f..f..", "..f....f.f....f."],
    ["...f..f...f..f..", "...f..f...f..f.."],
    ["....f.f....f.f..", "....f.f....f.f.."],
    ["...f..f...f..f..", "...f..f...f..f.."],
]

# (y, x) pixels of the tail for the two sway positions.
TAIL_A = [(6, 2), (7, 1), (8, 1), (9, 2), (10, 2)]
TAIL_B = [(5, 1), (6, 1), (7, 1), (8, 1), (9, 2), (10, 2)]

SLEEP_BODY = [
    "...bbbbbbhhnnhh.",  # 11 (head row with nose drawn over)
    "..bbbbbbbhhmmhh.",  # 12
    "..bbbbbbbbbbbbb.",  # 13
    ".ttttttttttttt..",  # 14 tail wrapped in front
]

Z_SMALL = [(5, 4), (5, 5), (5, 6), (6, 5), (7, 4), (7, 5), (7, 6)]
Z_BIG = [(2, 5), (2, 6), (2, 7), (3, 7), (4, 6), (5, 5), (6, 5), (6, 6), (6, 7)]


def blank():
    return [["."] * SIZE for _ in range(SIZE)]


def place_rows(grid, top, rows):
    for i, r in enumerate(rows):
        for x, c in enumerate(r):
            if c != ".":
                grid[top + i][x] = c


def cat_walk(frame: int):
    grid = blank()
    place_rows(grid, 4, HEAD)
    place_rows(grid, 9, WALK_BODY)
    place_rows(grid, 13, LEGS[frame])
    for y, x in (TAIL_A if frame < 2 else TAIL_B):
        put(grid, y, x, "t")
    return grid


def cat_idle(frame: int):
    grid = cat_walk(1)
    if frame == 1:
        replace_region(grid, "e", "k")
        for y, x in TAIL_A:
            put(grid, y, x, ".")
        for y, x in TAIL_B:
            put(grid, y, x, "t")
    return grid


def cat_sleep(frame: int):
    grid = blank()
    head = HEAD[:]
    head[3] = ".........hkhhkh."
    place_rows(grid, 7, head[:4])
    place_rows(grid, 11, SLEEP_BODY)
    if frame == 1:  # breathing: back rises a pixel
        for x in range(4, 8):
            put(grid, 10, x, "b")
    for y, x in (Z_SMALL if frame == 0 else Z_BIG):
        put(grid, y, x, "z")
    return grid


# ---------------------------------------------------------- variant tweaks

def ears_folded(grid, top):
    for x in range(SIZE):
        if grid[top][x] in "ap":
            grid[top][x] = "."
    for x in range(SIZE):
        if grid[top + 1][x] in "ap":
            grid[top + 1][x] = "."
    for x in (9, 10, 13, 14):
        put(grid, top + 1, x, "a")


def ears_tufted(grid, top):
    put(grid, top - 1, 9, "u")
    put(grid, top - 1, 14, "u")


def ears_big(grid, top):
    put(grid, top - 1, 9, "a")
    put(grid, top - 1, 14, "a")
    put(grid, top, 10, "p")
    put(grid, top, 13, "p")
    put(grid, top + 1, 10, "p")
    put(grid, top + 1, 13, "p")


def ears_tall(grid, top):
    """Fox: one extra pixel of ear above the normal tip."""
    put(grid, top - 1, 9, "a")
    put(grid, top - 1, 14, "a")
    put(grid, top, 10, "a")
    put(grid, top, 13, "a")


def tail_fluffy(grid):
    pts = [(y, x) for y in range(SIZE) for x in range(SIZE) if grid[y][x] == "t"]
    for y, x in pts:
        if x + 1 < SIZE and grid[y][x + 1] == ".":
            grid[y][x + 1] = "t"
        if x - 1 >= 0 and grid[y][x - 1] == ".":
            grid[y][x - 1] = "t"


def tail_white_tip(grid):
    """Topmost tail pixels become 'w' (fox tip)."""
    pts = sorted((y, x) for y in range(SIZE) for x in range(SIZE) if grid[y][x] == "t")
    if not pts:
        return
    top = pts[0][0]
    for y, x in pts:
        if y <= top + 1:
            grid[y][x] = "w"


def tail_curl(grid):
    """Shiba: replace the upright tail with a curl sitting on the back."""
    replace_region(grid, "t", ".")
    for y, x in ((8, 3), (8, 4), (7, 3), (7, 4), (7, 5), (8, 6)):
        if grid[y][x] == ".":
            grid[y][x] = "t"


def apply_cat_variant(frames, ears=None, tail=None):
    """Apply ear/tail tweaks to walk/idle (head top 4) and sleep (head top 7)."""
    out = {}
    for kind, grids in frames.items():
        top = 7 if kind == "sleep" else 4
        new = []
        for grid in grids:
            grid = copy(grid)
            if ears:
                ears(grid, top)
            if tail and kind != "sleep":
                for t in tail:
                    t(grid)
            elif tail and kind == "sleep" and tail_white_tip in tail:
                # fox sleeps with its white tip in front
                put(grid, 14, 1, "w")
                put(grid, 14, 2, "w")
            new.append(grid)
        out[kind] = new
    return out


def cat_frames(ears=None, tail=None):
    base = {
        "walk": [cat_walk(i) for i in range(4)],
        "idle": [cat_idle(i) for i in range(2)],
        "sleep": [cat_sleep(i) for i in range(2)],
    }
    return apply_cat_variant(base, ears, tail)


# ------------------------------------------------------- colour mappings

DEFAULT = {
    "a": "B", "p": "P", "h": "B", "e": "E", "k": "o", "n": "P", "m": "L",
    "b": "B", "l": "L", "t": "B", "f": "B", "w": "W", "u": "D", "z": "W",
    "x": "G",
}


def painter(rules=None):
    """rules(region, x, y) -> role or None (None = use DEFAULT)."""
    def paint(region, x, y):
        if rules:
            r = rules(region, x, y)
            if r:
                return r
        return DEFAULT[region]
    return paint


def stripes(region, x, y):
    if region in "bt" and region != "l":
        if region == "b" and y in (10, 11) and x in (5, 8, 11):
            return "D"
        if region == "t" and y % 2 == 0:
            return "D"
    if region == "h" and y in (6, 9) and x in (11, 12):  # forehead "M"
        return "D"
    return None


def siamese(region, x, y):
    if region in "aftun":
        return "D"
    if region == "h" and 10 <= x <= 13 and y in (8, 12):  # mask around the nose
        return "D"
    if region == "h" and x in (11, 12) and y in (7, 10):  # between the eyes
        return "D"
    if region == "m":
        return "D"
    return None


def calico(region, x, y):
    if region == "b" and 4 <= x <= 6 and 9 <= y <= 11:
        return "G"
    if region == "b" and 9 <= x <= 11 and 10 <= y <= 11:
        return "D"
    if region == "b" and 2 <= x <= 5 and y == 13:  # sleep loaf patch
        return "G"
    if region in "ah" and x <= 10 and y in (4, 5, 6, 7, 8, 9, 10):
        return "G"
    if region in "ah" and x >= 14 and y in (4, 5, 6, 7, 8, 9, 10):
        return "D"
    if region == "t":
        return "D" if y % 2 else "G"
    return None


def tuxedo(region, x, y):
    if region in "lm":
        return "L"
    if region == "f" and y == 14:
        return "L"
    if region == "b" and x >= 12 and y >= 10:
        return "L"
    return None


def bengal(region, x, y):
    spots = {(10, 4), (10, 7), (11, 6), (10, 10), (11, 9), (11, 4), (12, 12),
             (13, 4), (13, 7), (13, 10), (12, 5)}
    if region == "b" and (y, x) in spots:
        return "D"
    if region == "t" and y % 2:
        return "D"
    return None


def sphynx(region, x, y):
    if region == "h" and y in (6, 9) and x in (11, 12):  # forehead wrinkles
        return "D"
    return None


def strawberry(region, x, y):
    heart = {(10, 5), (10, 7), (11, 5), (11, 6), (11, 7), (12, 6)}
    if region == "b" and (y, x) in heart:
        return "D"
    return None


def cosmic(region, x, y):
    stars = {(10, 5), (11, 9), (6, 11), (13, 7), (13, 4), (12, 11)}
    if region in "bht" and (y, x) in stars:
        return "S"
    return None


def fox(region, x, y):
    if region == "f":
        return "D"
    if region == "a" and y <= 4:
        return "D"
    if region == "a" and y == 7:  # sleep frame ear tips
        return "D"
    if region == "b" and x >= 12 and y >= 10:
        return "L"
    return None


def shiba(region, x, y):
    if region == "h" and x in (9, 14) and y in (8, 9, 11, 12):
        return "L"
    if region == "b" and x >= 12 and y >= 10:
        return "L"
    if region == "t":
        return "L" if (y, x) == (8, 6) else None
    return None


# ------------------------------------------------- non-cat species (fills)
# Frames below are drawn directly. Same region letters as above.

BUNNY = {
    "walk": [
        ["................",
         "..........a..a..",
         "..........a..a..",
         "..........p..p..",
         "..........p..p..",
         ".........hhhhhh.",
         ".........hehheh.",
         ".........hhnnhh.",
         "...bbbbbbhhmmhh.",
         "..bbbbbbbbbbbb..",
         ".tbbbbbbbbbbbb..",
         "..bbbbblllllbb..",
         "..bbbbbbbbbbb...",
         "...ff.....ff....",
         "................",
         "................"],
        ["..........a..a..",
         "..........a..a..",
         "..........p..p..",
         "..........p..p..",
         ".........hhhhhh.",
         ".........hehheh.",
         ".........hhnnhh.",
         "...bbbbbbhhmmhh.",
         "..bbbbbbbbbbbb..",
         ".tbbbbbbbbbbbb..",
         "..bbbbblllllbb..",
         "..bbbbbbbbbbb...",
         ".ff........ff...",
         "................",
         "................",
         "................"],
    ],
    "idle": [
        ["................",
         "................",
         "..........a..a..",
         "..........a..a..",
         "..........p..p..",
         ".........hhhhhh.",
         ".........hehheh.",
         ".........hhnnhh.",
         "...bbbbbbhhmmhh.",
         "..bbbbbbbbbbbb..",
         ".tbbbbbbbbbbbb..",
         "..bbbbblllllbb..",
         "..bbbbbbbbbbb...",
         "...ff.....ff....",
         "................",
         "................"],
        ["................",
         "................",
         "..........a.....",
         "..........a..aa.",
         "..........p..pp.",
         ".........hhhhhh.",
         ".........hkhhkh.",
         ".........hhnnhh.",
         "...bbbbbbhhmmhh.",
         "..bbbbbbbbbbbb..",
         ".tbbbbbbbbbbbb..",
         "..bbbbblllllbb..",
         "..bbbbbbbbbbb...",
         "...ff.....ff....",
         "................",
         "................"],
    ],
    "sleep": [
        ["................",
         "................",
         "................",
         "................",
         "....z...........",
         "....zz..........",
         "................",
         "........aaaaa...",
         ".........ppppa..",
         ".........hhhhhh.",
         ".........hkhhkh.",
         "...bbbbbbhhnnhh.",
         "..bbbbbbbhhmmhh.",
         ".tbbbbbbbbbbbbb.",
         "..bbbbbbbbbbbb..",
         "................"],
        ["................",
         "................",
         ".....zzz........",
         ".......z........",
         "......z.........",
         ".....zzz........",
         "................",
         "........aaaaa...",
         ".........ppppa..",
         ".........hhhhhh.",
         ".........hkhhkh.",
         "...bbbbbbhhnnhh.",
         "..bbbbbbbhhmmhh.",
         ".tbbbbbbbbbbbbb.",
         ".bbbbbbbbbbbbbb.",
         "................"],
    ],
}

FROG = {
    "walk": [
        ["................",
         "................",
         "................",
         "................",
         "................",
         "................",
         "..hh......hh....",
         ".heeh....heeh...",
         ".hhhhhhhhhhhh...",
         ".hhhhhhhhhhhh...",
         ".hmmmmmmmmmmh...",
         ".bbllllllllbb...",
         ".bbbbbbbbbbbb...",
         "ff..........ff..",
         "................",
         "................"],
        ["................",
         "................",
         "................",
         "...hh......hh...",
         "..heeh....heeh..",
         "..hhhhhhhhhhhh..",
         "..hhhhhhhhhhhh..",
         "..hmmmmmmmmmmh..",
         "..bbllllllllbb..",
         "..bbbbbbbbbbbb..",
         ".ff..........ff.",
         "ff............ff",
         "................",
         "................",
         "................",
         "................"],
    ],
    "idle": [
        ["................",
         "................",
         "................",
         "................",
         "................",
         "................",
         "..hh......hh....",
         ".heeh....heeh...",
         ".hhhhhhhhhhhh...",
         ".hhhhhhhhhhhh...",
         ".hmmmmmmmmmmh...",
         ".bbllllllllbb...",
         ".bbbbbbbbbbbb...",
         "ff..........ff..",
         "................",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         "................",
         "................",
         "..hh......hh....",
         ".hkkh....hkkh...",
         ".hhhhhhhhhhhh...",
         ".hhhhhhhhhhhh...",
         ".hmmmmmmmmmmh...",
         ".bbllllllllbb...",
         ".bbbbbbbbbbbb...",
         "ff..........ff..",
         "................",
         "................"],
    ],
    "sleep": [
        ["................",
         "................",
         "................",
         "................",
         "............z...",
         "............zz..",
         "................",
         "................",
         "..hh......hh....",
         ".hkkh....hkkh...",
         ".hhhhhhhhhhhh...",
         ".hmmmmmmmmmmh...",
         ".bbllllllllbb...",
         "fbbbbbbbbbbbbf..",
         "................",
         "................"],
        ["................",
         "................",
         "............zzz.",
         "..............z.",
         ".............z..",
         "............zzz.",
         "................",
         "................",
         "..hh......hh....",
         ".hkkh....hkkh...",
         ".hhhhhhhhhhhh...",
         ".hhhhhhhhhhhh...",
         ".bbllllllllbb...",
         "fbbbbbbbbbbbbf..",
         "................",
         "................"],
    ],
}

GHOST = {
    "walk": [
        ["................",
         "................",
         "................",
         ".....bbbbbb.....",
         "....bbbbbbbb....",
         "...bbbbbbbbbb...",
         "...bbbebbebbb...",
         "...bbbebbebbb...",
         "...bbpbbbbpbb...",
         "...bbbbmmbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...b.bb.bb.bb...",
         "................",
         "................"],
        ["................",
         "................",
         ".....bbbbbb.....",
         "....bbbbbbbb....",
         "...bbbbbbbbbb...",
         "...bbbebbebbb...",
         "...bbbebbebbb...",
         "...bbpbbbbpbb...",
         "...bbbbmmbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bb.bb.bb.b...",
         "................",
         "................",
         "................"],
    ],
    "idle": [
        ["................",
         "................",
         "................",
         ".....bbbbbb.....",
         "....bbbbbbbb....",
         "...bbbbbbbbbb...",
         "...bbbebbebbb...",
         "...bbbebbebbb...",
         "...bbpbbbbpbb...",
         "...bbbbmmbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...b.bb.bb.bb...",
         "................",
         "................"],
        ["................",
         "................",
         "................",
         ".....bbbbbb.....",
         "....bbbbbbbb....",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bbbkbbkbbb...",
         "...bbpbbbbpbb...",
         "...bbbbmmbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bb.bb.bb.b...",
         "................",
         "................"],
    ],
    "sleep": [
        ["................",
         "................",
         "..........z.....",
         "..........zz....",
         "................",
         "................",
         ".....bbbbbb.....",
         "....bbbbbbbb....",
         "...bbbbbbbbbb...",
         "...bbbkbbkbbb...",
         "...bbpbbbbpbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...b.bb.bb.bb...",
         "................"],
        ["................",
         ".........zzz....",
         "...........z....",
         "..........z.....",
         ".........zzz....",
         "................",
         ".....bbbbbb.....",
         "....bbbbbbbb....",
         "...bbbbbbbbbb...",
         "...bbbkbbkbbb...",
         "...bbpbbbbpbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bbbbbbbbbb...",
         "...bb.bb.bb.b...",
         "................"],
    ],
}

CAPYBARA = {
    "walk": [
        ["................",
         "................",
         "................",
         "................",
         "................",
         "..........a..a..",
         "........hhhhhh..",
         "....bbbbhhhehhh.",
         "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh",
         "..bbbbbbbbbbbmm.",
         "..bbbbbbbbbbbb..",
         "..bbbbbbbbbbbb..",
         "...f.f....f.f...",
         "..f...f..f...f..",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         "................",
         "..........a..a..",
         "........hhhhhh..",
         "....bbbbhhhehhh.",
         "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh",
         "..bbbbbbbbbbbmm.",
         "..bbbbbbbbbbbb..",
         "..bbbbbbbbbbbb..",
         "...f.f....f.f...",
         "...f.f....f.f...",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         "................",
         "..........a..a..",
         "........hhhhhh..",
         "....bbbbhhhehhh.",
         "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh",
         "..bbbbbbbbbbbmm.",
         "..bbbbbbbbbbbb..",
         "..bbbbbbbbbbbb..",
         "....ff.....ff...",
         "....ff.....ff...",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         "................",
         "..........a..a..",
         "........hhhhhh..",
         "....bbbbhhhehhh.",
         "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh",
         "..bbbbbbbbbbbmm.",
         "..bbbbbbbbbbbb..",
         "..bbbbbbbbbbbb..",
         "...f.f....f.f...",
         "...f.f....f.f...",
         "................"],
    ],
    "idle": [
        ["................",
         "................",
         "................",
         "................",
         "................",
         "..........a..a..",
         "........hhhhhh..",
         "....bbbbhhhehhh.",
         "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh",
         "..bbbbbbbbbbbmm.",
         "..bbbbbbbbbbbb..",
         "..bbbbbbbbbbbb..",
         "...f.f....f.f...",
         "...f.f....f.f...",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         "................",
         "..........a..a..",
         "........hhhhhh..",
         "....bbbbhhhkhhh.",
         "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh",
         "..bbbbbbbbbbbmm.",
         "..bbbbbbbbbbbb..",
         "..bbbbbbbbbbbb..",
         "...f.f....f.f...",
         "...f.f....f.f...",
         "................"],
    ],
    "sleep": [
        ["................",
         "................",
         "................",
         "................",
         "....z...........",
         "....zz..........",
         "................",
         "................",
         "..........a..a..",
         "........hhhhhh..",
         "....bbbbhhhkhhh.",
         "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh",
         "..bbbbbbbbbbbmm.",
         "..bbbbbbbbbbbb..",
         "................"],
        ["................",
         "................",
         ".....zzz........",
         ".......z........",
         "......z.........",
         ".....zzz........",
         "................",
         "................",
         "..........a..a..",
         "........hhhhhh..",
         "...bbbbbhhhkhhh.",
         "..bbbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh",
         "..bbbbbbbbbbbmm.",
         "..bbbbbbbbbbbb..",
         "................"],
    ],
}

PENGUIN = {
    "walk": [
        ["................",
         "................",
         "................",
         ".......bbbb.....",
         "......bbbbbb....",
         ".....bblllllb...",
         ".....blelleel...",
         ".....bllnnllb...",
         "....bblllllllb..",
         "...bbblllllllb..",
         "...bbblllllllb..",
         "....bblllllllb..",
         ".....blllllll...",
         ".....ff...ff....",
         "................",
         "................"],
        ["................",
         "................",
         "................",
         "........bbbb....",
         ".......bbbbbb...",
         "......bblllllb..",
         "......blelleel..",
         "......bllnnllb..",
         ".....bblllllllb.",
         "....bbblllllllb.",
         "....bbblllllllb.",
         ".....bblllllllb.",
         "......blllllll..",
         ".......ff...ff..",
         "................",
         "................"],
    ],
    "idle": [
        ["................",
         "................",
         "................",
         ".......bbbb.....",
         "......bbbbbb....",
         ".....bblllllb...",
         ".....blelleel...",
         ".....bllnnllb...",
         "....bblllllllb..",
         "...bbblllllllb..",
         "...bbblllllllb..",
         "....bblllllllb..",
         ".....blllllll...",
         ".....ff...ff....",
         "................",
         "................"],
        ["................",
         "................",
         "................",
         ".......bbbb.....",
         "......bbbbbb....",
         ".....bblllllb...",
         ".....blkllkkl...",
         ".....bllnnllb...",
         "...bbblllllllbb.",
         "..b.bblllllllb.b",
         "....bblllllllb..",
         "....bblllllllb..",
         ".....blllllll...",
         ".....ff...ff....",
         "................",
         "................"],
    ],
    "sleep": [
        ["................",
         "................",
         "...........z....",
         "...........zz...",
         "................",
         "................",
         ".......bbbb.....",
         "......bbbbbb....",
         ".....bblllllb...",
         ".....blkllkkl...",
         ".....bllnnllb...",
         "....bblllllllb..",
         "...bbblllllllb..",
         "....bblllllllb..",
         ".....ff...ff....",
         "................"],
        ["................",
         "..........zzz...",
         "............z...",
         "...........z....",
         "..........zzz...",
         "................",
         ".......bbbb.....",
         "......bbbbbb....",
         ".....bblllllb...",
         ".....blkllkkl...",
         ".....bllnnllb...",
         "....bblllllllb..",
         "...bbblllllllbb.",
         "....bblllllllb..",
         ".....ff...ff....",
         "................"],
    ],
}

AXOLOTL = {
    "walk": [
        ["................",
         "................",
         "................",
         "................",
         "........x....x..",
         ".........hhhh.x.",
         ".......xhhhhhh..",
         "........hehheh..",
         "........hhmmhh.x",
         "..tbbbbbbhhhhh..",
         ".ttbbbbbbbbbb...",
         "..tbbllllllbb...",
         "...bbbbbbbbbb...",
         "...f..f...f..f..",
         "..f....f.f....f.",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         "........x....x..",
         ".........hhhh.x.",
         ".......xhhhhhh..",
         "........hehheh..",
         "........hhmmhh.x",
         "...bbbbbbhhhhh..",
         ".ttbbbbbbbbbb...",
         "tt.bbllllllbb...",
         "...bbbbbbbbbb...",
         "...f..f...f..f..",
         "...f..f...f..f..",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         "........x....x..",
         ".........hhhh.x.",
         ".......xhhhhhh..",
         "........hehheh..",
         "........hhmmhh.x",
         "..tbbbbbbhhhhh..",
         ".ttbbbbbbbbbb...",
         "..tbbllllllbb...",
         "...bbbbbbbbbb...",
         "....f.f....f.f..",
         "....f.f....f.f..",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         "........x....x..",
         ".........hhhh.x.",
         ".......xhhhhhh..",
         "........hehheh..",
         "........hhmmhh.x",
         "...bbbbbbhhhhh..",
         ".ttbbbbbbbbbb...",
         "tt.bbllllllbb...",
         "...bbbbbbbbbb...",
         "...f..f...f..f..",
         "...f..f...f..f..",
         "................"],
    ],
    "idle": [
        ["................",
         "................",
         "................",
         "................",
         "........x....x..",
         ".........hhhh.x.",
         ".......xhhhhhh..",
         "........hehheh..",
         "........hhmmhh.x",
         "..tbbbbbbhhhhh..",
         ".ttbbbbbbbbbb...",
         "..tbbllllllbb...",
         "...bbbbbbbbbb...",
         "...f..f...f..f..",
         "...f..f...f..f..",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         ".........x...x..",
         ".......x.hhhh.x.",
         "........hhhhhh.x",
         "........hkhhkh..",
         "........hhmmhh..",
         "..tbbbbbbhhhhh..",
         ".ttbbbbbbbbbb...",
         "..tbbllllllbb...",
         "...bbbbbbbbbb...",
         "...f..f...f..f..",
         "...f..f...f..f..",
         "................"],
    ],
    "sleep": [
        ["................",
         "................",
         "................",
         "................",
         "....z...........",
         "....zz..........",
         "................",
         "........x....x..",
         ".........hhhh.x.",
         ".......xhhhhhh..",
         "........hkhhkh..",
         "........hhmmhh.x",
         "..tbbbbbbhhhhh..",
         ".ttbbbbbbbbbbb..",
         "..tbbbbbbbbbbb..",
         "................"],
        ["................",
         "................",
         ".....zzz........",
         ".......z........",
         "......z.........",
         ".....zzz........",
         "................",
         "........x....x..",
         ".........hhhh.x.",
         ".......xhhhhhh..",
         "........hkhhkh..",
         "........hhmmhh.x",
         "...bbbbbbhhhhh..",
         "..bbbbbbbbbbbb..",
         ".ttbbbbbbbbbbb..",
         "................"],
    ],
}

DUCK = {
    "walk": [
        ["................",
         "................",
         "................",
         "................",
         ".........hhhh...",
         "........hhhhhh..",
         "........hhhehhnn",
         "........hhhhhhnn",
         "...b....hhhhhh..",
         "...bbbbbbhhhh...",
         "...bbbbbbbbbbb..",
         "....bbblllbbbb..",
         ".....bbbbbbbb...",
         "......ff..ff....",
         ".....fff.fff....",
         "................"],
        ["................",
         "................",
         "................",
         ".........hhhh...",
         "........hhhhhh..",
         "........hhhehhnn",
         "........hhhhhhnn",
         "...b....hhhhhh..",
         "...bbbbbbhhhh...",
         "...bbbbbbbbbbb..",
         "....bbblllbbbb..",
         ".....bbbbbbbb...",
         "......ff..ff....",
         "......ff..ff....",
         ".....fff.fff....",
         "................"],
    ],
    "idle": [
        ["................",
         "................",
         "................",
         "................",
         ".........hhhh...",
         "........hhhhhh..",
         "........hhhehhnn",
         "........hhhhhhnn",
         "...b....hhhhhh..",
         "...bbbbbbhhhh...",
         "...bbbbbbbbbbb..",
         "....bbblllbbbb..",
         ".....bbbbbbbb...",
         "......ff..ff....",
         ".....fff.fff....",
         "................"],
        ["................",
         "................",
         "................",
         "................",
         ".........hhhh...",
         "........hhhhhh..",
         "........hhhkhhnn",
         "........hhhhhhnn",
         "..b.....hhhhhh..",
         "...bbbbbbhhhh...",
         "...bbbbbbbbbbb..",
         "....bbblllbbbb..",
         ".....bbbbbbbb...",
         "......ff..ff....",
         ".....fff.fff....",
         "................"],
    ],
    "sleep": [
        ["................",
         "................",
         "................",
         "................",
         "....z...........",
         "....zz..........",
         "................",
         ".........hhhh...",
         "........hhhhhh..",
         "........hhhkhhnn",
         "........hhhhhhnn",
         "...b....hhhhhh..",
         "...bbbbbbhhhh...",
         "...bbbbbbbbbbb..",
         "....bbbbbbbbbb..",
         "................"],
        ["................",
         "................",
         ".....zzz........",
         ".......z........",
         "......z.........",
         ".....zzz........",
         "................",
         ".........hhhh...",
         "........hhhhhh..",
         "........hhhkhhnn",
         "........hhhhhhnn",
         "...b....hhhhhh..",
         "..bbbbbbbhhhh...",
         "..bbbbbbbbbbbb..",
         "...bbbbbbbbbbb..",
         "................"],
    ],
}


def hand_drawn(spec):
    out = {}
    for kind, frames in spec.items():
        grids = [g(f) for f in frames]
        if kind == "walk" and len(grids) == 2:  # 2-frame walkers -> 4 slots
            grids = [grids[0], grids[1], grids[0], grids[1]]
        out[kind] = grids
    return out


# ------------------------------------------------------------- catalogue

def pal(o, B, D, L, P, E, G=None, W="#FFFFFF", S="#FFF3A0"):
    return {"o": o, "B": B, "D": D, "L": L, "P": P, "E": E, "G": G or D, "W": W, "S": S}


PETS = [
    # id, Russian name, group, frames, palette, paint
    ("cat.ginger", "Рыжик", "cats", cat_frames(),
     pal("#3A1F14", "#EE9A4D", "#C4642A", "#FBE3C4", "#F28AA0", "#2A1A14"), painter(stripes)),
    ("cat.black", "Уголёк", "cats", cat_frames(),
     pal("#141019", "#3D3850", "#2A2638", "#57506E", "#E68AA6", "#F5D547"), painter()),
    ("cat.white", "Снежок", "cats", cat_frames(),
     pal("#5E5A70", "#F4F1EC", "#D9D4E0", "#FFFFFF", "#F6A0B6", "#4FA3F7"), painter()),
    ("cat.british", "Британец", "cats", cat_frames(),
     pal("#2B2F3D", "#8E98AB", "#6F788C", "#AEB6C7", "#C99AA8", "#F5A63A"), painter()),
    ("cat.siamese", "Сиамка", "cats", cat_frames(),
     pal("#2E201B", "#F2E4CB", "#5C4136", "#FBF3E4", "#E7A2A6", "#4DA6FF"), painter(siamese)),
    ("cat.calico", "Трёхцветка", "cats", cat_frames(),
     pal("#2E2427", "#F6F0E7", "#3B3236", "#FFFFFF", "#F4A0B0", "#7BC86A", G="#EE9A4D"), painter(calico)),
    ("cat.tabby", "Полосатик", "cats", cat_frames(),
     pal("#25232B", "#A3A0AC", "#605C6B", "#D9D5DF", "#E59CAE", "#9BD15A"), painter(stripes)),
    ("cat.tuxedo", "Фрачник", "cats", cat_frames(),
     pal("#121016", "#34313F", "#24212C", "#F4F2F7", "#E68AA6", "#CDE86A"), painter(tuxedo)),
    ("cat.sphynx", "Сфинкс", "cats", cat_frames(ears=ears_big),
     pal("#4A2B27", "#EBC3B1", "#D29C88", "#F5DACC", "#E98F9A", "#62C9B4"), painter(sphynx)),
    ("cat.mainecoon", "Мейн-кун", "cats", cat_frames(ears=ears_tufted, tail=[tail_fluffy]),
     pal("#24150E", "#93603F", "#5A3725", "#EAD4B6", "#E2A08E", "#EBB53B"), painter(stripes)),
    ("cat.scottish", "Вислоухий", "cats", cat_frames(ears=ears_folded),
     pal("#2C2832", "#C8C1B7", "#9D958A", "#EFEAE2", "#E2A5AE", "#F2A33A"), painter()),
    ("cat.bengal", "Бенгал", "cats", cat_frames(),
     pal("#2A180C", "#E8AE5A", "#6B3F22", "#F8E3BF", "#E59A8C", "#79C95A"), painter(bengal)),
    ("cat.strawberry", "Клубничка", "cats", cat_frames(),
     pal("#5A1F36", "#FF9FC3", "#FF5E95", "#FFE3EE", "#FF5C8A", "#6B2B4A"), painter(strawberry)),
    ("cat.cosmic", "Космокот", "cats", cat_frames(),
     pal("#0D0F2E", "#2E3480", "#4B52B8", "#6F75E0", "#FF8FD0", "#8FF3FF", S="#FFF3A0"), painter(cosmic)),

    ("fox", "Лиса", "friends", cat_frames(ears=ears_tall, tail=[tail_fluffy, tail_white_tip]),
     pal("#2B1408", "#F27A2E", "#3A2318", "#FFF4E8", "#2B1408", "#2B1408"), painter(fox)),
    ("dog.shiba", "Сиба", "friends", cat_frames(tail=[tail_curl]),
     pal("#2E1A0E", "#E59C55", "#B8733A", "#F8EAD3", "#2E1A0E", "#2E1A0E"), painter(shiba)),
    ("bunny", "Зайка", "friends", hand_drawn(BUNNY),
     pal("#4C4256", "#F3EEF5", "#D8D0E0", "#FFFFFF", "#F7A8C0", "#3A2A44"), painter()),
    ("capybara", "Капибара", "friends", hand_drawn(CAPYBARA),
     pal("#2B1B10", "#A8754A", "#7C5332", "#C99A6E", "#3B2617", "#1E120A"),
     painter(lambda r, x, y: "D" if r == "n" else ("D" if r == "a" else None))),
    ("frog", "Лягушка", "friends", hand_drawn(FROG),
     pal("#14301A", "#6CCB5F", "#3E9A47", "#E8F7C8", "#F28AA0", "#14301A"),
     painter(lambda r, x, y: "W" if r == "e" else ("B" if r == "f" else None))),
    ("ghost", "Призрак", "friends", hand_drawn(GHOST),
     pal("#3B3A55", "#EDEBFA", "#C9C5E8", "#B9B4E3", "#FFB3CC", "#2A2840"),
     painter(lambda r, x, y: "D" if r == "m" else None)),
    ("penguin", "Пингвин", "friends", hand_drawn(PENGUIN),
     pal("#0E1220", "#2C3550", "#1C2238", "#F5F6FA", "#FFB13B", "#0E1220"),
     painter(lambda r, x, y: "P" if r in "fn" else None)),
    ("axolotl", "Аксолотль", "friends", hand_drawn(AXOLOTL),
     pal("#5A2340", "#FFB3D1", "#FF7FB0", "#FFE3EF", "#FF5C8A", "#3A1530", G="#FF6FA8"),
     painter(lambda r, x, y: "D" if r == "m" else None)),
    ("duck", "Утёнок", "friends", hand_drawn(DUCK),
     pal("#4A3A08", "#FFD84A", "#E8B020", "#FFF0A8", "#FF9A2E", "#2A2008"),
     painter(lambda r, x, y: "P" if r in "fn" else None)),
]


# --------------------------------------------------------------- output

def finalize(grid, paint):
    """Outline + region->role. Returns 16 strings of role letters ('.' empty)."""
    lined = add_outline(grid)
    rows = []
    for y in range(SIZE):
        row = ""
        for x in range(SIZE):
            c = lined[y][x]
            if c == ".":
                row += "."
            elif c == "o":
                row += "o"
            else:
                role = paint(c, x, y)
                assert role in ROLES, f"bad role {role!r} for region {c!r}"
                row += role
        rows.append(row)
    return rows


def hex_to_int(h):
    return int(h.lstrip("#"), 16)


def build():
    pets = []
    ids = set()
    for pid, name, group, frames, palette, paint in PETS:
        assert pid not in ids, pid
        ids.add(pid)
        for kind in ("walk", "idle", "sleep"):
            assert kind in frames, f"{pid} misses {kind}"
        done = {k: [finalize(gr, paint) for gr in v] for k, v in frames.items()}
        pets.append((pid, name, group, palette, done))
    return pets


def swift_frames(frames):
    lines = []
    for f in frames:
        body = ",\n                ".join(f'"{r}"' for r in f)
        lines.append(f"            [\n                {body},\n            ]")
    return "[\n" + ",\n".join(lines) + ",\n        ]"


def write_swift(pets):
    out = [
        "// Generated by tools/sprites/generate.py. Do not edit by hand:",
        "// change the generator and run it again.",
        "//",
        "// Each frame is 16 rows of 16 characters. A character is a palette role:",
        "// o outline, B base, D dark, L light, P pink, E eye, G accent, W white,",
        "// S star, '.' transparent.",
        "",
        "enum SpriteCatalog {",
        "    static let pets: [PetSpriteData] = [",
    ]
    for pid, name, group, palette, frames in pets:
        palette_items = ", ".join(f'"{k}": 0x{hex_to_int(v):06X}' for k, v in palette.items())
        out.append("        PetSpriteData(")
        out.append(f'            id: "{pid}",')
        out.append(f'            name: "{name}",')
        out.append(f"            group: .{group},")
        out.append(f"            palette: [{palette_items}],")
        out.append(f"            walk: {swift_frames(frames['walk'])},")
        out.append(f"            idle: {swift_frames(frames['idle'])},")
        out.append(f"            sleep: {swift_frames(frames['sleep'])}")
        out.append("        ),")
    out.append("    ]")
    out.append("}")
    os.makedirs(os.path.dirname(SWIFT_OUT), exist_ok=True)
    with open(SWIFT_OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out) + "\n")


def write_preview(pets, scale=6):
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not installed, skipping preview", file=sys.stderr)
        return
    cols = 8  # 4 walk + 2 idle + 2 sleep
    cell = (SIZE + 2) * scale
    img = Image.new("RGB", (cols * cell, len(pets) * cell), (0, 0, 0))
    for row, (_, _, _, palette, frames) in enumerate(pets):
        seq = frames["walk"] + frames["idle"] + frames["sleep"]
        for col, f in enumerate(seq):
            for y, line in enumerate(f):
                for x, c in enumerate(line):
                    if c == ".":
                        continue
                    h = palette[c].lstrip("#")
                    rgb = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
                    x0 = col * cell + (x + 1) * scale
                    y0 = row * cell + (y + 1) * scale
                    for yy in range(scale):
                        for xx in range(scale):
                            img.putpixel((x0 + xx, y0 + yy), rgb)
    img.save(PREVIEW_OUT)


if __name__ == "__main__":
    data = build()
    write_swift(data)
    write_preview(data)
    print(f"{len(data)} pets -> {os.path.relpath(SWIFT_OUT, ROOT)}")
