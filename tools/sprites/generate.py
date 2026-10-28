#!/usr/bin/env python3
"""Pixel Island sprite generator (v2).

Draws every pet on a 16x16 grid in several poses, colours it per breed, adds
the outline and writes:
  * Shared/Sprites/SpriteCatalog.generated.swift  - data the app reads
  * tools/sprites/preview.png                     - a sheet to eyeball the art

Run from the repo root:  python3 tools/sprites/generate.py
Pillow is only needed for the preview (pip install pillow).

How a sprite is described
-------------------------
Poses are drawn with *region* letters, not colours. Regions say what a pixel
is; some regions are "hints" that patterns may recolour:

  a ear fur      p inner ear     h head fur      y head patch (hint)
  r forehead stripe (hint)       M mask around the nose (hint)
  e left eye     j right eye     k closed eye    n nose      m muzzle
  b body fur     s body stripe (hint)            x back patch (hint)
  l chest/belly  t tail          q tail ring (hint)          w tail tip
  f leg          g paw           u ear tuft

Each breed has a palette and a list of patterns. A pattern turns regions into
palette *roles*, the only thing the Swift side knows about:

  o outline  B base  D dark  L light  P pink  E eye  F 2nd eye  K closed eye
  G accent   W white S star  H highlight  Q shade

Breeds whose palette has H and Q get simple volume: base-coloured pixels
on the top edge of the silhouette become H (light), on the bottom edge Q.

The outline is added automatically around the silhouette.
"""
from __future__ import annotations

import os
import sys

SIZE = 16
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SWIFT_OUT = os.path.join(ROOT, "Shared", "Sprites", "SpriteCatalog.generated.swift")
PREVIEW_OUT = os.path.join(ROOT, "tools", "sprites", "preview.png")

ROLES = "oBDLPEFKGWSHQ"
POSES = ["walk", "sit", "loaf", "sleep", "curl", "groom", "stretch", "play"]
TAIL = set("tqw")
HEADISH = set("hyrM")
EMPTY = "." * SIZE


# ---------------------------------------------------------------- helpers

def grid(rows: list[str]) -> list[list[str]]:
    """Bottom-align `rows` in a 16x16 grid and validate the width."""
    rows = list(rows)
    assert len(rows) <= SIZE, f"too many rows: {len(rows)}"
    for r in rows:
        assert len(r) == SIZE, f"row {r!r} is {len(r)} wide"
    rows = [EMPTY] * (SIZE - len(rows)) + rows
    return [list(r) for r in rows]


def copy(g):
    return [row[:] for row in g]


def put(g, y, x, region):
    if 0 <= y < SIZE and 0 <= x < SIZE:
        g[y][x] = region


def cells(g, letters):
    return [(y, x) for y in range(SIZE) for x in range(SIZE) if g[y][x] in letters]


def edit(g, changes):
    """Return a copy with (y, x, region) changes applied."""
    out = copy(g)
    for y, x, region in changes:
        put(out, y, x, region)
    return out


def close_eyes(g):
    """Open eyes (2 px tall dots) become closed eyes: a 2 px line per eye."""
    out = copy(g)
    for letter, outward in (("e", -1), ("j", 1)):
        pts = cells(g, letter)
        for x in sorted({x for _, x in pts}):
            column = sorted(y for y, xx in pts if xx == x)
            for y in column[:-1]:
                out[y][x] = "h"
            bottom = column[-1]
            out[bottom][x] = "k"
            if g[bottom][x + outward] in HEADISH:
                out[bottom][x + outward] = "k"
    return out


def add_outline(g):
    """Every empty pixel touching a filled one (4-neighbourhood) becomes 'o'."""
    out = copy(g)
    for y in range(SIZE):
        for x in range(SIZE):
            if g[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < SIZE and 0 <= ny < SIZE and g[ny][nx] not in ".o":
                    out[y][x] = "o"
                    break
    return out


# ------------------------------------------------------------ cat template
# Facing right. Head is 6 px wide, ears on top, eyes 2 px tall.

WALK_BODY = [
    ".........a....a.",  # 4
    ".........pa..ap.",  # 5
    ".........yyrrhh.",  # 6
    ".........yeMMjh.",  # 7
    ".........hennjh.",  # 8
    "....xxsbshMmmMh.",  # 9
    "...xxxsbsbsbbll.",  # 10
    "...xxxsbsbsbbl..",  # 11
    "...bbllllllbbl..",  # 12
]
WALK_LEGS = [
    ["...f..f...f..f..", "..g....g.g....g."],
    ["...f..f...f..f..", "...g..g...g..g.."],
    ["....f.f....f.f..", "....g.g....g.g.."],
    ["...f..f...f..f..", "...g..g...g..g.."],
]
TAIL_CURLED = [(6, 2, "w"), (7, 1, "q"), (8, 1, "t"), (9, 2, "q"), (10, 2, "t")]
TAIL_UP = [(5, 1, "w"), (6, 1, "t"), (7, 1, "q"), (8, 1, "t"), (9, 2, "q"), (10, 2, "t")]


def walk_frame(i):
    g = grid(WALK_BODY + WALK_LEGS[i] + [EMPTY])
    for y, x, r in (TAIL_CURLED if i < 2 else TAIL_UP):
        put(g, y, x, r)
    return g


SIT = grid([
    "........a....a..",
    "........pa..ap..",
    "........yyrrhh..",
    "........yeMMjh..",
    "........hennjh..",
    "......xshMmmMh..",
    ".....xxsbsblll..",
    "....xxxsbsblll..",
    "....xxsbsbbff...",
    "...xxsbsbsbff...",
    "...xbbbbbbbff...",
    ".wqtqtqtbbbgg...",
    EMPTY,
])

LOAF = grid([
    ".........a....a.",
    ".........pa..ap.",
    ".........yyrrhh.",
    ".........yeMMjh.",
    ".........hennjh.",
    "...xxsbsbhMmmMh.",
    ".txxxsbsbsbbbll.",
    "wqxxsbsbsbbblll.",
    "..bbbbbbbbbbgggg",
    EMPTY,
])

SLEEP = grid([
    ".........a....a.",
    ".........pa..ap.",
    ".........yyrrhh.",
    "...xxsbs.yhMMhh.",
    ".txxxsbsbkknnkk.",
    "wqxxsbsbshMmmMh.",
    "..bbbbbbbbbbgggg",
    EMPTY,
])

CURL = grid([
    ".........a....a.",
    "....xsb..pa..ap.",
    "..xxxsbsbyyrrhh.",
    ".xxxsbsbsyhMMhh.",
    ".xxxsbsbskknnkk.",
    ".xxsbsbsbhMmmMh.",
    "..tqtqtqtqtqtqw.",
    EMPTY,
])

GROOM = grid([
    "........a....a..",
    "........pa..ap..",
    "........yyrrhh..",
    "........yhMMhh.g",
    "........kknnkkff",
    "......xshMmmMhf.",
    ".....xxsbsbllf..",
    "....xxxsbslll...",
    "....xxsbsbbf....",
    "...xxsbsbsbf....",
    ".wqtqtqtbbbg....",
    EMPTY,
])

STRETCH = grid([
    ".w..............",
    ".t..............",
    ".q..............",
    "..xxs...........",
    "..xxsbs...a....a",
    "..xxsbsbs.pa..ap",
    "..ffbsbsbsyyrrhh",
    "..ff..bsbsyeMMjh",
    "..ff....bshennjh",
    "..ff......hMmmMh",
    "..gg.......ggggg",
    EMPTY,
])

PLAY = grid([
    "........a....a..",
    "........pa..ap..",
    "........yyrrhh..",
    "........yeMMjh..",
    "........hennjh..",
    "..xxsbs.hMmmMh..",
    ".txxsbsbsbbll...",
    "wqxxsbsbsbblll..",
    "..bbbbbbbbbbgggg",
    EMPTY,
])

PLAY_SWIPE = grid([
    "........a....a..",
    "........pa..ap..",
    "........yyrrhh..",
    "........yeMMjh.g",
    "........hennjhff",
    "..xxsbs.hMmmMhf.",
    ".txxsbsbsbbllf..",
    "wqxxsbsbsbblll..",
    "..bbbbbbbbbgg...",
    EMPTY,
])


def cat_template():
    return {
        "walk": [walk_frame(i) for i in range(4)],
        "sit": [SIT, close_eyes(SIT), edit(SIT, [(14, 1, "."), (13, 1, "w"), (14, 2, "t")])],
        "loaf": [LOAF, edit(LOAF, [(13, 0, "."), (12, 0, "w"), (13, 1, "t")]), close_eyes(LOAF)],
        "sleep": [SLEEP, edit(SLEEP, [(10, 4, "x"), (10, 5, "s"), (10, 6, "b")])],
        "curl": [CURL, edit(CURL, [(9, 3, "x"), (9, 7, "s")])],
        "groom": [GROOM, edit(GROOM, [(7, 15, "."), (8, 15, "g"), (8, 14, "f")])],
        "stretch": [STRETCH, edit(STRETCH, [(4, 1, "."), (4, 2, "w")])],
        "play": [PLAY, PLAY_SWIPE],
    }


# ---------------------------------------------------------- body variants

def ear_tips(g):
    return [(y, x) for y, x in cells(g, "a") if y == 0 or g[y - 1][x] == "."]


def ears_folded(g):
    for y, x in ear_tips(g):
        g[y][x] = "."
    for y, x in cells(g, "p"):
        g[y][x] = "a"


def ears_small(g):
    for y, x in ear_tips(g):
        g[y][x] = "."


def ears_tufted(g):
    for y, x in ear_tips(g):
        put(g, y - 1, x, "u")


def ears_big(g):
    for y, x in ear_tips(g):
        put(g, y - 1, x, "a")


def tail_fluffy(g):
    for y, x in cells(g, TAIL):
        horizontal = any(0 <= x + d < SIZE and g[y][x + d] in TAIL for d in (-1, 1))
        targets = [(y - 1, x)] if horizontal else [(y, x - 1), (y, x + 1)]
        for ty, tx in targets:
            if 0 <= ty < SIZE and 0 <= tx < SIZE and g[ty][tx] == ".":
                g[ty][tx] = g[y][x]


def tail_bob(g):
    """Keep only the two tail pixels closest to the body."""
    tail = set(cells(g, TAIL))
    body = {(y, x) for y in range(SIZE) for x in range(SIZE)
            if g[y][x] not in "." and (y, x) not in tail}
    dist = {}
    frontier = [p for p in tail
                if any((p[0] + dy, p[1] + dx) in body for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for p in frontier:
        dist[p] = 1
    while frontier:
        nxt = []
        for y, x in frontier:
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (y + dy, x + dx)
                if q in tail and q not in dist:
                    dist[q] = dist[(y, x)] + 1
                    nxt.append(q)
        frontier = nxt
    for p in tail:
        if dist.get(p, 99) > 2:
            g[p[0]][p[1]] = "."


def tail_curl_back(g):
    """Shiba: the tail curls over the back instead of hanging."""
    for y, x in cells(g, TAIL):
        g[y][x] = "."
    tops = cells(g, "xsb")
    if not tops:
        return
    top = min(y for y, _ in tops)
    left = min(x for y, x in tops if y == top)
    for dy, dx in ((-1, 0), (-1, 1), (-2, 0), (-2, 1), (-2, 2), (-1, 3)):
        if 0 <= top + dy and g[top + dy][left + dx] == ".":
            g[top + dy][left + dx] = "t"


def short_legs(frames):
    """Munchkin: drop one leg row from walking frames."""
    for i, g in enumerate(frames["walk"]):
        g = copy(g)
        del g[13]
        g.insert(0, ["."] * SIZE)
        frames["walk"][i] = g


def with_variants(frames, mods=(), legs_short=False):
    out = {}
    for pose, gs in frames.items():
        out[pose] = []
        for g in gs:
            g = copy(g)
            for mod in mods:
                mod(g)
            out[pose].append(g)
    if legs_short:
        short_legs(out)
    return out


# ------------------------------------------------------------- patterns
# A pattern is f(region, x, y) -> role or None. Patterns are tried in order,
# the first non-None answer wins, DEFAULT handles the rest.

DEFAULT = {
    "a": "B", "p": "P", "h": "B", "y": "B", "r": "B", "M": "B", "e": "E", "j": "F",
    "k": "K", "n": "P", "m": "L", "b": "B", "s": "B", "x": "B", "l": "L", "t": "B",
    "q": "B", "w": "B", "f": "B", "g": "B", "u": "D", "z": "W",
}


def tabby(region, x, y):
    return "D" if region in "srq" else None


def spotted(region, x, y):
    if region == "s" and (x + y) % 2 == 0:
        return "D"
    return "D" if region in "rq" else None


def ticked(region, x, y):
    return "D" if region in "rw" else None


def points(region, x, y):
    return "D" if region in "aftqwMmnp" or (region == "g") else None


def white_socks(region, x, y):
    return "L" if region == "g" else None


def calico(region, x, y):
    if region == "x":
        return "G"
    if region in "yq":
        return "D"
    if region == "t":
        return "G"
    return None


def tortie(region, x, y):
    if region in "xyq":
        return "G"
    if region == "s" and (x * 7 + y * 3) % 5 < 2:
        return "G"
    if region in "bh" and (x * 5 + y * 11) % 7 == 0:
        return "G"
    return None


def bicolor(region, x, y):
    return "L" if region in "Mmlfg" else None


def tuxedo(region, x, y):
    return "L" if region in "mlg" else None


def van(region, x, y):
    return "G" if region in "ayrtqw" else None


def harlequin(region, x, y):
    return "D" if region in "xyqt" else None


def wrinkles(region, x, y):
    return "D" if region == "r" else None


def seeds(region, x, y):
    return "G" if region in "sx" and (x + 2 * y) % 4 == 0 else None


def stars(region, x, y):
    return "S" if region in "sxbh" and (x * 3 + y * 5) % 11 == 0 else None


def fox_marks(region, x, y):
    if region in "fg":
        return "D"
    if region in "lmMw":
        return "W"
    return None


def shiba_marks(region, x, y):
    return "L" if region in "lmMg" else None


def painter(*patterns):
    def paint(region, x, y):
        for pattern in patterns:
            role = pattern(region, x, y)
            if role:
                return role
        return DEFAULT[region]
    return paint


def pal(o, B, D, L, P, E, F=None, K=None, G=None, W="#FFFFFF", S="#FFF3A0", H=None, Q=None):
    p = {"o": o, "B": B, "D": D, "L": L, "P": P, "E": E, "F": F or E, "K": K or o,
         "G": G or D, "W": W, "S": S}
    if H and Q:
        p["H"] = H
        p["Q"] = Q
    return p


# ------------------------------------------------------ hand-drawn friends
# Simple critters with walk (2 frames), sit/idle (2) and sleep (2). Missing
# poses fall back on the Swift side (loaf/groom/play -> sit, curl -> sleep).

def friend(walk, sit, sleep):
    def prep(frames):
        return [grid(f) for f in frames]
    w = prep(walk)
    return {"walk": [w[0], w[1], w[0], w[1]], "sit": prep(sit), "sleep": [widen_closed(g) for g in prep(sleep)]}


def widen_closed(g):
    out = copy(g)
    for y in range(SIZE):
        xs = [x for x in range(SIZE) if g[y][x] == "k"]
        if not xs:
            continue
        targets = [xs[0] - 1, xs[-1] + 1] if len(xs) > 1 else [xs[0] + 1]
        for tx in targets:
            if 0 <= tx < SIZE and g[y][tx] in "hb":
                out[y][tx] = "k"
    return out


BUNNY = friend(
    walk=[
        ["..........a..a..", "..........a..a..", "..........p..p..", "..........p..p..",
         ".........hhhhhh.", ".........hehhjh.", ".........hhnnhh.", "...bbbbbbhhmmhh.",
         "..bbbbbbbbbbbb..", ".tbbbbbbbbbbbb..", "..bbbbblllllbb..", "..bbbbbbbbbbb...",
         "...gg.....gg....", EMPTY],
        ["..........a..a..", "..........a..a..", "..........p..p..", "..........p..p..",
         ".........hhhhhh.", ".........hehhjh.", ".........hhnnhh.", "...bbbbbbhhmmhh.",
         "..bbbbbbbbbbbb..", ".tbbbbbbbbbbbb..", "..bbbbblllllbb..", "..bbbbbbbbbbb...",
         ".gg........gg...", EMPTY, EMPTY],
    ],
    sit=[
        ["..........a..a..", "..........a..a..", "..........p..p..", ".........hhhhhh.",
         ".........hehhjh.", ".........hhnnhh.", "...bbbbbbhhmmhh.", "..bbbbbbbbbbbb..",
         ".tbbbbbbbbbbbb..", "..bbbbblllllbb..", "..bbbbbbbbbbb...", "...gg.....gg....", EMPTY],
        ["..........a.....", "..........a..aa.", "..........p..pp.", ".........hhhhhh.",
         ".........hkhhkh.", ".........hhnnhh.", "...bbbbbbhhmmhh.", "..bbbbbbbbbbbb..",
         ".tbbbbbbbbbbbb..", "..bbbbblllllbb..", "..bbbbbbbbbbb...", "...gg.....gg....", EMPTY],
    ],
    sleep=[
        ["........aaaaa...", ".........ppppa..", ".........hhhhhh.", ".........hkhhkh.",
         "...bbbbbbhhnnhh.", "..bbbbbbbhhmmhh.", ".tbbbbbbbbbbbbb.", "..bbbbbbbbbbbb..", EMPTY],
        ["........aaaaa...", ".........ppppa..", ".........hhhhhh.", ".........hkhhkh.",
         "...bbbbbbhhnnhh.", "..bbbbbbbhhmmhh.", ".tbbbbbbbbbbbbb.", ".bbbbbbbbbbbbbb.", EMPTY],
    ],
)

FROG = friend(
    walk=[
        ["..hh......hh....", ".heeh....hjjh...", ".hhhhhhhhhhhh...", ".hhhhhhhhhhhh...",
         ".hmmmmmmmmmmh...", ".bbllllllllbb...", ".bbbbbbbbbbbb...", "gg..........gg..", EMPTY],
        ["...hh......hh...", "..heeh....hjjh..", "..hhhhhhhhhhhh..", "..hhhhhhhhhhhh..",
         "..hmmmmmmmmmmh..", "..bbllllllllbb..", "..bbbbbbbbbbbb..", ".gg..........gg.",
         "gg............gg", EMPTY, EMPTY, EMPTY],
    ],
    sit=[
        ["..hh......hh....", ".heeh....hjjh...", ".hhhhhhhhhhhh...", ".hhhhhhhhhhhh...",
         ".hmmmmmmmmmmh...", ".bbllllllllbb...", ".bbbbbbbbbbbb...", "gg..........gg..", EMPTY],
        ["..hh......hh....", ".hkkh....hkkh...", ".hhhhhhhhhhhh...", ".hhhhhhhhhhhh...",
         ".hmmmmmmmmmmh...", ".bbllllllllbb...", ".bbbbbbbbbbbb...", "gg..........gg..", EMPTY],
    ],
    sleep=[
        ["..hh......hh....", ".hkkh....hkkh...", ".hhhhhhhhhhhh...", ".hmmmmmmmmmmh...",
         ".bbllllllllbb...", "gbbbbbbbbbbbbg..", EMPTY],
        ["..hh......hh....", ".hkkh....hkkh...", ".hhhhhhhhhhhh...", ".hhhhhhhhhhhh...",
         ".bbllllllllbb...", "gbbbbbbbbbbbbg..", EMPTY],
    ],
)

GHOST = friend(
    walk=[
        [".....bbbbbb.....", "....bbbbbbbb....", "...bbbbbbbbbb...", "...bbbebbjbbb...",
         "...bbbebbjbbb...", "...bbpbbbbpbb...", "...bbbbmmbbbb...", "...bbbbbbbbbb...",
         "...bbbbbbbbbb...", "...bbbbbbbbbb...", "...b.bb.bb.bb...", EMPTY, EMPTY],
        [".....bbbbbb.....", "....bbbbbbbb....", "...bbbbbbbbbb...", "...bbbebbjbbb...",
         "...bbbebbjbbb...", "...bbpbbbbpbb...", "...bbbbmmbbbb...", "...bbbbbbbbbb...",
         "...bbbbbbbbbb...", "...bbbbbbbbbb...", "...bb.bb.bb.b...", EMPTY, EMPTY, EMPTY],
    ],
    sit=[
        [".....bbbbbb.....", "....bbbbbbbb....", "...bbbbbbbbbb...", "...bbbebbjbbb...",
         "...bbbebbjbbb...", "...bbpbbbbpbb...", "...bbbbmmbbbb...", "...bbbbbbbbbb...",
         "...bbbbbbbbbb...", "...bbbbbbbbbb...", "...b.bb.bb.bb...", EMPTY, EMPTY],
        [".....bbbbbb.....", "....bbbbbbbb....", "...bbbbbbbbbb...", "...bbbbbbbbbb...",
         "...bbbkbbkbbb...", "...bbpbbbbpbb...", "...bbbbmmbbbb...", "...bbbbbbbbbb...",
         "...bbbbbbbbbb...", "...bbbbbbbbbb...", "...b.bb.bb.bb...", EMPTY, EMPTY],
    ],
    sleep=[
        [".....bbbbbb.....", "....bbbbbbbb....", "...bbbbbbbbbb...", "...bbbkbbkbbb...",
         "...bbpbbbbpbb...", "...bbbbbbbbbb...", "...bbbbbbbbbb...", "...bbbbbbbbbb...",
         "...b.bb.bb.bb...", EMPTY],
        [".....bbbbbb.....", "....bbbbbbbb....", "...bbbbbbbbbb...", "...bbbkbbkbbb...",
         "...bbpbbbbpbb...", "...bbbbbbbbbb...", "...bbbbbbbbbb...", "...bbbbbbbbbb...",
         "...bb.bb.bb.b...", EMPTY],
    ],
)

CAPYBARA = friend(
    walk=[
        ["..........a..a..", "........hhhhhh..", "....bbbbhhhehhh.", "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh", "..bbbbbbbbbbbmm.", "..bbbbbbbbbbbb..", "..bbbbbbbbbbbb..",
         "...f.f....f.f...", "..g...g..g...g..", EMPTY],
        ["..........a..a..", "........hhhhhh..", "....bbbbhhhehhh.", "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh", "..bbbbbbbbbbbmm.", "..bbbbbbbbbbbb..", "..bbbbbbbbbbbb..",
         "....ff.....ff...", "....gg.....gg...", EMPTY],
    ],
    sit=[
        ["..........a..a..", "........hhhhhh..", "....bbbbhhhehhh.", "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh", "..bbbbbbbbbbbmm.", "..bbbbbbbbbbbb..", "..bbbbbbbbbbbb..",
         "...f.f....f.f...", "...g.g....g.g...", EMPTY],
        ["..........a..a..", "........hhhhhh..", "....bbbbhhhkhhh.", "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh", "..bbbbbbbbbbbmm.", "..bbbbbbbbbbbb..", "..bbbbbbbbbbbb..",
         "...f.f....f.f...", "...g.g....g.g...", EMPTY],
    ],
    sleep=[
        ["..........a..a..", "........hhhhhh..", "....bbbbhhhkhhh.", "...bbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh", "..bbbbbbbbbbbmm.", "..bbbbbbbbbbbb..", EMPTY],
        ["..........a..a..", "........hhhhhh..", "...bbbbbhhhkhhh.", "..bbbbbbbhhhhhnn",
         "..bbbbbbbbhhhhhh", "..bbbbbbbbbbbmm.", "..bbbbbbbbbbbb..", EMPTY],
    ],
)

PENGUIN = friend(
    walk=[
        [".......bbbb.....", "......bbbbbb....", ".....bblllllb...", ".....blellljl...",
         ".....bllnnllb...", "....bblllllllb..", "...bbblllllllb..", "...bbblllllllb..",
         "....bblllllllb..", ".....blllllll...", ".....gg...gg....", EMPTY, EMPTY],
        ["........bbbb....", ".......bbbbbb...", "......bblllllb..", "......blellljl..",
         "......bllnnllb..", ".....bblllllllb.", "....bbblllllllb.", "....bbblllllllb.",
         ".....bblllllllb.", "......blllllll..", ".......gg...gg..", EMPTY, EMPTY],
    ],
    sit=[
        [".......bbbb.....", "......bbbbbb....", ".....bblllllb...", ".....blellljl...",
         ".....bllnnllb...", "....bblllllllb..", "...bbblllllllb..", "...bbblllllllb..",
         "....bblllllllb..", ".....blllllll...", ".....gg...gg....", EMPTY, EMPTY],
        [".......bbbb.....", "......bbbbbb....", ".....bblllllb...", ".....blkllkkl...",
         ".....bllnnllb...", "...bbblllllllbb.", "..b.bblllllllb.b", "....bblllllllb..",
         "....bblllllllb..", ".....blllllll...", ".....gg...gg....", EMPTY, EMPTY],
    ],
    sleep=[
        [".......bbbb.....", "......bbbbbb....", ".....bblllllb...", ".....blkllkkl...",
         ".....bllnnllb...", "....bblllllllb..", "...bbblllllllb..", "....bblllllllb..",
         ".....gg...gg....", EMPTY],
        [".......bbbb.....", "......bbbbbb....", ".....bblllllb...", ".....blkllkkl...",
         ".....bllnnllb...", "....bblllllllb..", "...bbblllllllbb.", "....bblllllllb..",
         ".....gg...gg....", EMPTY],
    ],
)

AXOLOTL = friend(
    walk=[
        ["........x....x..", ".........hhhh.x.", ".......xhhhhhh..", "........hehhjh..",
         "........hhmmhh.x", "..tbbbbbbhhhhh..", ".ttbbbbbbbbbb...", "..tbbllllllbb...",
         "...bbbbbbbbbb...", "...f..f...f..f..", "..g....g.g....g.", EMPTY],
        ["........x....x..", ".........hhhh.x.", ".......xhhhhhh..", "........hehhjh..",
         "........hhmmhh.x", "...bbbbbbhhhhh..", ".ttbbbbbbbbbb...", "tt.bbllllllbb...",
         "...bbbbbbbbbb...", "....f.f....f.f..", "....g.g....g.g..", EMPTY],
    ],
    sit=[
        ["........x....x..", ".........hhhh.x.", ".......xhhhhhh..", "........hehhjh..",
         "........hhmmhh.x", "..tbbbbbbhhhhh..", ".ttbbbbbbbbbb...", "..tbbllllllbb...",
         "...bbbbbbbbbb...", "...f..f...f..f..", "...g..g...g..g..", EMPTY],
        [".........x...x..", ".......x.hhhh.x.", "........hhhhhh.x", "........hkhhkh..",
         "........hhmmhh..", "..tbbbbbbhhhhh..", ".ttbbbbbbbbbb...", "..tbbllllllbb...",
         "...bbbbbbbbbb...", "...f..f...f..f..", "...g..g...g..g..", EMPTY],
    ],
    sleep=[
        ["........x....x..", ".........hhhh.x.", ".......xhhhhhh..", "........hkhhkh..",
         "........hhmmhh.x", "..tbbbbbbhhhhh..", ".ttbbbbbbbbbbb..", "..tbbbbbbbbbbb..", EMPTY],
        ["........x....x..", ".........hhhh.x.", ".......xhhhhhh..", "........hkhhkh..",
         "........hhmmhh.x", "...bbbbbbhhhhh..", "..bbbbbbbbbbbb..", ".ttbbbbbbbbbbb..", EMPTY],
    ],
)

DUCK = friend(
    walk=[
        [".........hhhh...", "........hhhhhh..", "........hhhehhnn", "........hhhhhhnn",
         "...b....hhhhhh..", "...bbbbbbhhhh...", "...bbbbbbbbbbb..", "....bbblllbbbb..",
         ".....bbbbbbbb...", "......ff..ff....", ".....ggg.ggg....", EMPTY],
        [".........hhhh...", "........hhhhhh..", "........hhhehhnn", "........hhhhhhnn",
         "...b....hhhhhh..", "...bbbbbbhhhh...", "...bbbbbbbbbbb..", "....bbblllbbbb..",
         ".....bbbbbbbb...", "......ff..ff....", "......ff..ff....", ".....ggg.ggg....", EMPTY],
    ],
    sit=[
        [".........hhhh...", "........hhhhhh..", "........hhhehhnn", "........hhhhhhnn",
         "...b....hhhhhh..", "...bbbbbbhhhh...", "...bbbbbbbbbbb..", "....bbblllbbbb..",
         ".....bbbbbbbb...", "......ff..ff....", ".....ggg.ggg....", EMPTY],
        [".........hhhh...", "........hhhhhh..", "........hhhkhhnn", "........hhhhhhnn",
         "..b.....hhhhhh..", "...bbbbbbhhhh...", "...bbbbbbbbbbb..", "....bbblllbbbb..",
         ".....bbbbbbbb...", "......ff..ff....", ".....ggg.ggg....", EMPTY],
    ],
    sleep=[
        [".........hhhh...", "........hhhhhh..", "........hhhkhhnn", "........hhhhhhnn",
         "...b....hhhhhh..", "...bbbbbbhhhh...", "...bbbbbbbbbbb..", "....bbbbbbbbbb..", EMPTY],
        [".........hhhh...", "........hhhhhh..", "........hhhkhhnn", "........hhhhhhnn",
         "...b....hhhhhh..", "..bbbbbbbhhhh...", "..bbbbbbbbbbbb..", "...bbbbbbbbbbb..", EMPTY],
    ],
)


# ------------------------------------------------------------- catalogue

CAT = cat_template()


def cat(mods=(), legs_short=False):
    return with_variants(CAT, mods, legs_short)


# id, name, group, frames, palette, paint
PETS = [
    # --- classic colours
    ("cat.ginger", "Рыжик", "cats", cat(),
     pal("#3A1F14", "#EE9A4D", "#C4642A", "#FBE3C4", "#F28AA0", "#2A1A14"), painter(tabby)),
    ("cat.peach", "Персик", "cats", cat(),
     pal("#4A2A1C", "#F7C69A", "#E6A06E", "#FFF1E0", "#F29AAE", "#3A2418"), painter(tabby)),
    ("cat.black", "Уголёк", "cats", cat(),
     pal("#100D14", "#34303F", "#26222E", "#4A4458", "#E68AA6", "#F5D547", K="#8C82A0"), painter()),
    ("cat.white", "Снежок", "cats", cat(),
     pal("#5E5A70", "#F4F1EC", "#D9D4E0", "#FFFFFF", "#F6A0B6", "#4FA3F7"), painter()),
    ("cat.oddeye", "Жемчуг", "cats", cat(),
     pal("#5E5A70", "#F7F4EF", "#DCD7E3", "#FFFFFF", "#F6A0B6", "#4FA3F7", F="#F5C542"), painter()),
    ("cat.british", "Британец", "cats", cat(),
     pal("#2B2F3D", "#8E98AB", "#6F788C", "#AEB6C7", "#C99AA8", "#F5A63A"), painter()),
    ("cat.russianblue", "Русская голубая", "cats", cat(),
     pal("#252A36", "#7F8BA3", "#677289", "#98A3B8", "#C99AA8", "#7CD67A"), painter()),
    ("cat.smoke", "Дымка", "cats", cat(),
     pal("#1C1A22", "#5E5A69", "#46424F", "#8D8899", "#D98EA4", "#F2C94C", K="#A59FB2"), painter()),
    ("cat.chocolate", "Шоколадка", "cats", cat(),
     pal("#23140D", "#6B4330", "#52321F", "#8A5C44", "#D9909A", "#F2B33D", K="#B88E77"), painter()),
    ("cat.cinnamon", "Корица", "cats", cat(),
     pal("#3A2014", "#B8754B", "#93583A", "#D9A27C", "#E59A9A", "#F2B33D"), painter(ticked)),
    ("cat.lilac", "Лиловый", "cats", cat(),
     pal("#3D3340", "#C9B7C4", "#A9939F", "#E3D6DF", "#E6A0B4", "#F2B33D"), painter()),
    # --- patterns
    ("cat.tabby", "Полосатик", "cats", cat(),
     pal("#25232B", "#A3A0AC", "#605C6B", "#D9D5DF", "#E59CAE", "#9BD15A"), painter(tabby)),
    ("cat.silver", "Серебро", "cats", cat(),
     pal("#1E1F26", "#CDD2DA", "#3C3F4A", "#EEF1F5", "#E59CAE", "#7CD67A"), painter(tabby)),
    ("cat.calico", "Трёхцветка", "cats", cat(),
     pal("#2E2427", "#F6F0E7", "#3B3236", "#FFFFFF", "#F4A0B0", "#7BC86A", G="#EE9A4D"), painter(calico)),
    ("cat.tortie", "Черепашка", "cats", cat(),
     pal("#141016", "#3A2E30", "#2A2023", "#5A4446", "#D98EA4", "#F2B33D", K="#A08890", G="#D4793A"),
     painter(tortie)),
    ("cat.cow", "Коровка", "cats", cat(),
     pal("#2A262C", "#F5F2EE", "#2B272E", "#FFFFFF", "#F4A0B0", "#5A9E5A"), painter(harlequin)),
    ("cat.tuxedo", "Фрачник", "cats", cat(),
     pal("#100D14", "#34313F", "#24212C", "#F4F2F7", "#E68AA6", "#CDE86A", K="#8C82A0"), painter(tuxedo)),
    ("cat.bicolor", "Биколор", "cats", cat(),
     pal("#100D14", "#2F2C38", "#211E28", "#F4F2F7", "#E68AA6", "#F5D547", K="#8C82A0"), painter(bicolor)),
    ("cat.gingerwhite", "Рыжий с белым", "cats", cat(),
     pal("#3A1F14", "#EE9A4D", "#C4642A", "#FFF8F0", "#F28AA0", "#2A1A14"), painter(bicolor, tabby)),
    ("cat.van", "Ван", "cats", cat(),
     pal("#4A3A3A", "#FAF6F0", "#C4642A", "#FFFFFF", "#F4A0B0", "#4FA3F7", G="#EE9A4D"), painter(van)),
    ("cat.siamese", "Сиамка", "cats", cat(),
     pal("#2E201B", "#F2E4CB", "#5C4136", "#FBF3E4", "#E7A2A6", "#4DA6FF"), painter(points)),
    ("cat.bluepoint", "Голубой поинт", "cats", cat(),
     pal("#2A2D38", "#F1EEEA", "#7E879C", "#FFFFFF", "#D7A6B4", "#4DA6FF"), painter(points)),
    ("cat.ragdoll", "Рэгдолл", "cats", cat(mods=[tail_fluffy]),
     pal("#3A2D28", "#F5EDE2", "#8A6E5E", "#FFFFFF", "#E7A2A6", "#3F8CFF"), painter(white_socks, points)),
    ("cat.birman", "Бирманка", "cats", cat(mods=[tail_fluffy]),
     pal("#2E201B", "#F3E3C3", "#5C4136", "#FFFFFF", "#E7A2A6", "#4DA6FF"), painter(white_socks, points)),
    ("cat.tonkinese", "Тонкинез", "cats", cat(),
     pal("#2E211C", "#C9A27E", "#6A4A3A", "#E2C6A8", "#D9909A", "#5FD1C1"), painter(points)),
    ("cat.bengal", "Бенгал", "cats", cat(),
     pal("#2A180C", "#E8AE5A", "#6B3F22", "#F8E3BF", "#E59A8C", "#79C95A"), painter(spotted)),
    ("cat.mau", "Мау", "cats", cat(),
     pal("#1E1F26", "#C9CDD4", "#3C3F4A", "#EEF1F5", "#E59CAE", "#9BE36A"), painter(spotted)),
    ("cat.abyssinian", "Абиссинец", "cats", cat(mods=[ears_big]),
     pal("#2E1A10", "#C77C45", "#7A4423", "#E8B98E", "#E59A8C", "#F2B33D"), painter(ticked)),
    ("cat.somali", "Сомали", "cats", cat(mods=[ears_big, tail_fluffy]),
     pal("#2E1A10", "#D2874A", "#7A4423", "#F0C79C", "#E59A8C", "#F2B33D"), painter(ticked)),
    # --- shapes
    ("cat.sphynx", "Сфинкс", "cats", cat(mods=[ears_big]),
     pal("#4A2B27", "#EBC3B1", "#D29C88", "#F5DACC", "#E98F9A", "#62C9B4"), painter(wrinkles)),
    ("cat.mainecoon", "Мейн-кун", "cats", cat(mods=[ears_tufted, tail_fluffy]),
     pal("#24150E", "#93603F", "#5A3725", "#EAD4B6", "#E2A08E", "#EBB53B"), painter(tabby)),
    ("cat.norwegian", "Норвежская", "cats", cat(mods=[ears_tufted, tail_fluffy]),
     pal("#25232B", "#8F8A94", "#4E4A56", "#F4F1EC", "#E59CAE", "#9BD15A"), painter(bicolor, tabby)),
    ("cat.scottish", "Вислоухий", "cats", cat(mods=[ears_folded]),
     pal("#2C2832", "#A9AFBE", "#7E8597", "#E3E6EE", "#E2A5AE", "#F2A33A"), painter()),
    ("cat.highland", "Хайленд", "cats", cat(mods=[ears_folded, tail_fluffy]),
     pal("#4A3628", "#F1DDBF", "#D9B98F", "#FFF6E8", "#E7A2A6", "#C27A3A"), painter(tabby)),
    ("cat.persian", "Перс", "cats", cat(mods=[ears_small, tail_fluffy]),
     pal("#4A3A3A", "#F8EFE6", "#E0D2C4", "#FFFFFF", "#F4A0B0", "#E68A2E"), painter()),
    ("cat.angora", "Ангора", "cats", cat(mods=[tail_fluffy]),
     pal("#5E5A70", "#FBF9F6", "#E0DCE6", "#FFFFFF", "#F6A0B6", "#7CD67A", F="#4FA3F7"), painter()),
    ("cat.munchkin", "Манчкин", "cats", cat(legs_short=True),
     pal("#3A1F14", "#EE9A4D", "#C4642A", "#FFF8F0", "#F28AA0", "#2A1A14"), painter(tabby)),
    ("cat.bobtail", "Бобтейл", "cats", cat(mods=[tail_bob]),
     pal("#25232B", "#B8A99A", "#5E5248", "#F4F1EC", "#E59CAE", "#F2B33D"), painter(bicolor, tabby)),
    # --- fantasy
    ("cat.strawberry", "Клубничка", "cats", cat(),
     pal("#5A1F36", "#FF7FA6", "#FF5E95", "#FFE3EE", "#FF5C8A", "#6B2B4A", G="#FFE27A"), painter(seeds)),
    ("cat.cosmic", "Космокот", "cats", cat(),
     pal("#0D0F2E", "#2E3480", "#4B52B8", "#6F75E0", "#FF8FD0", "#8FF3FF", K="#8FA0FF"), painter(stars)),
    ("cat.mint", "Мятный", "cats", cat(),
     pal("#1F3D35", "#9FE8CF", "#6CCFAE", "#E3FFF5", "#FF9FC0", "#2B5C4E"), painter(tabby)),
    ("cat.lavender", "Лаванда", "cats", cat(),
     pal("#2F2347", "#C3A9F0", "#9A7BDB", "#EEE4FF", "#FF9FC9", "#4A3570"), painter(tabby)),
    ("cat.golden", "Золотце", "cats", cat(mods=[tail_fluffy]),
     pal("#3D2A08", "#F7C948", "#E0A21E", "#FFF1B8", "#F29AAE", "#3D2A08", S="#FFFFFF"), painter(stars)),
    ("cat.sakura", "Сакура", "cats", cat(),
     pal("#4A2236", "#FFD3E2", "#FF9EC2", "#FFF4F8", "#FF7FAA", "#7A3555"), painter(seeds)),

    # --- black & white, with volume
    ("cat.bombay", "Бомбей", "cats", cat(),
     pal("#0B090E", "#26222E", "#1A1720", "#3A3546", "#C97A93", "#E8A23A", K="#8C82A0",
         H="#4A4458", Q="#17141C"), painter()),
    ("cat.panther", "Пантера", "cats", cat(),
     pal("#0B090E", "#2A2733", "#1A1820", "#3C3848", "#C97A93", "#8BE07A", K="#8C82A0",
         H="#524C66", Q="#18161E"), painter()),
    ("cat.blackfluffy", "Чёрный пушок", "cats", cat(mods=[ears_tufted, tail_fluffy]),
     pal("#0B090E", "#2C2935", "#1A1820", "#3E3A4A", "#C97A93", "#F2B33D", K="#8C82A0",
         H="#55506A", Q="#19171F"), painter()),
    ("cat.blacklocket", "Медальон", "cats", cat(),
     pal("#0B090E", "#2A2733", "#1A1820", "#F4F2F7", "#C97A93", "#F5D547", K="#8C82A0",
         H="#504A63", Q="#18161E"), painter(lambda r, x, y: "L" if r == "l" else None)),
    ("cat.blacksocks", "Чёрные носочки", "cats", cat(),
     pal("#0B090E", "#2A2733", "#1A1820", "#F4F2F7", "#C97A93", "#7CD67A", K="#8C82A0",
         H="#504A63", Q="#18161E"), painter(white_socks)),
    ("cat.blacksmoke", "Чёрный дым", "cats", cat(mods=[tail_fluffy]),
     pal("#141219", "#3B3946", "#24222B", "#55525F", "#C97A93", "#F2C94C", K="#A59FB2",
         H="#77738A", Q="#24222B"), painter()),
    ("cat.oreo", "Орео", "cats", cat(),
     pal("#0B090E", "#2A2733", "#1A1820", "#F7F5F2", "#E68AA6", "#4FA3F7", K="#8C82A0",
         H="#504A63", Q="#18161E"), painter(bicolor)),
    ("cat.snowwhite", "Белоснежка", "cats", cat(),
     pal("#6E6880", "#F6F4F1", "#D8D3E0", "#FFFFFF", "#F6A0B6", "#4FA3F7",
         H="#FFFFFF", Q="#DCD7E5"), painter()),
    ("cat.whitefluffy", "Белый пушок", "cats", cat(mods=[ears_tufted, tail_fluffy]),
     pal("#6E6880", "#F7F5F2", "#D8D3E0", "#FFFFFF", "#F6A0B6", "#F2B33D",
         H="#FFFFFF", Q="#DDD8E6"), painter()),
    ("cat.whiteemerald", "Белый изумруд", "cats", cat(),
     pal("#6E6880", "#F5F3F0", "#D8D3E0", "#FFFFFF", "#F6A0B6", "#3FCF8E",
         H="#FFFFFF", Q="#DAD5E2"), painter()),
    ("cat.whitecap", "Белый в шапочке", "cats", cat(),
     pal("#3E3A48", "#F6F4F1", "#2A2733", "#FFFFFF", "#F6A0B6", "#7CD67A",
         H="#FFFFFF", Q="#DCD7E5"), painter(lambda r, x, y: "D" if r in "ayr" else None)),
    ("cat.whitetail", "Белый с хвостиком", "cats", cat(),
     pal("#3E3A48", "#F6F4F1", "#2A2733", "#FFFFFF", "#F6A0B6", "#4FA3F7",
         H="#FFFFFF", Q="#DCD7E5"), painter(lambda r, x, y: "D" if r in "tqw" else None)),
    ("cat.whitemask", "Масочка", "cats", cat(),
     pal("#3E3A48", "#F6F4F1", "#2A2733", "#FFFFFF", "#F6A0B6", "#F2B33D",
         H="#FFFFFF", Q="#DCD7E5"), painter(lambda r, x, y: "D" if r in "ayM" else None)),
    ("cat.blackvan", "Чёрно-белый ван", "cats", cat(),
     pal("#3E3A48", "#F6F4F1", "#2A2733", "#FFFFFF", "#F6A0B6", "#4FA3F7", G="#2A2733",
         H="#FFFFFF", Q="#DCD7E5"), painter(van)),

    # --- friends
    ("fox", "Лиса", "friends", cat(mods=[ears_big, tail_fluffy]),
     pal("#2B1408", "#F27A2E", "#3A2318", "#FFF4E8", "#2B1408", "#2B1408", K="#2B1408"), painter(fox_marks)),
    ("dog.shiba", "Сиба", "friends", cat(mods=[tail_curl_back]),
     pal("#2E1A0E", "#E59C55", "#B8733A", "#F8EAD3", "#2E1A0E", "#2E1A0E"), painter(shiba_marks)),
    ("bunny", "Зайка", "friends", BUNNY,
     pal("#4C4256", "#F3EEF5", "#D8D0E0", "#FFFFFF", "#F7A8C0", "#3A2A44"), painter()),
    ("capybara", "Капибара", "friends", CAPYBARA,
     pal("#2B1B10", "#A8754A", "#7C5332", "#C99A6E", "#3B2617", "#1E120A"),
     painter(lambda r, x, y: "D" if r in "na" else None)),
    ("frog", "Лягушка", "friends", FROG,
     pal("#14301A", "#6CCB5F", "#3E9A47", "#E8F7C8", "#F28AA0", "#14301A"),
     painter(lambda r, x, y: "B" if r == "g" else None)),
    ("ghost", "Призрак", "friends", GHOST,
     pal("#3B3A55", "#EDEBFA", "#C9C5E8", "#B9B4E3", "#FFB3CC", "#2A2840"),
     painter(lambda r, x, y: "D" if r == "m" else None)),
    ("penguin", "Пингвин", "friends", PENGUIN,
     pal("#0E1220", "#2C3550", "#1C2238", "#F5F6FA", "#FFB13B", "#0E1220"),
     painter(lambda r, x, y: "P" if r in "gn" else None)),
    ("axolotl", "Аксолотль", "friends", AXOLOTL,
     pal("#5A2340", "#FFB3D1", "#FF7FB0", "#FFE3EF", "#FF5C8A", "#3A1530", G="#FF6FA8"),
     painter(lambda r, x, y: "D" if r == "m" else ("G" if r == "x" else None))),
    ("duck", "Утёнок", "friends", DUCK,
     pal("#4A3A08", "#FFD84A", "#E8B020", "#FFF0A8", "#FF9A2E", "#2A2008"),
     painter(lambda r, x, y: "P" if r in "gfn" else None)),
]


# --------------------------------------------------------------- output

def finalize(g, paint, shaded=False):
    """Outline + region->role (+ optional shading). One 256-char string."""
    lined = add_outline(g)
    roles = [["."] * SIZE for _ in range(SIZE)]
    for y in range(SIZE):
        for x in range(SIZE):
            c = lined[y][x]
            if c in ".o":
                roles[y][x] = c
            else:
                role = paint(c, x, y)
                assert role in ROLES, f"bad role {role!r} for region {c!r}"
                roles[y][x] = role
    if shaded:
        def empty(y, x):
            return not (0 <= y < SIZE and 0 <= x < SIZE) or lined[y][x] in ".o"
        for y in range(SIZE):
            for x in range(SIZE):
                if roles[y][x] != "B":
                    continue
                if empty(y - 1, x):
                    roles[y][x] = "H"
                elif empty(y + 1, x):
                    roles[y][x] = "Q"
    return "".join("".join(r) for r in roles)


def build():
    pets = []
    ids = set()
    for pid, name, group, frames, palette, paint in PETS:
        assert pid not in ids, pid
        ids.add(pid)
        assert "walk" in frames and "sit" in frames and "sleep" in frames, pid
        shaded = "H" in palette
        done = {pose: [finalize(g, paint, shaded) for g in frames[pose]] for pose in POSES if pose in frames}
        pets.append((pid, name, group, palette, done))
    return pets


def hex_to_int(h):
    return int(h.lstrip("#"), 16)


def write_swift(pets):
    out = [
        "// Generated by tools/sprites/generate.py. Do not edit by hand:",
        "// change the generator and run it again.",
        "//",
        "// Each frame is 256 characters: 16 rows of 16, top to bottom. A character",
        "// is a palette role: o outline, B base, D dark, L light, P pink, E eye,",
        "// F second eye, K closed eye, G accent, W white, S star, '.' transparent.",
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
        out.append("            poses: [")
        for pose, strings in frames.items():
            out.append(f'                "{pose}": [')
            for s in strings:
                out.append(f'                    "{s}",')
            out.append("                ],")
        out.append("            ]")
        out.append("        ),")
    out.append("    ]")
    out.append("}")
    os.makedirs(os.path.dirname(SWIFT_OUT), exist_ok=True)
    with open(SWIFT_OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out) + "\n")


def write_preview(pets, scale=4):
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not installed, skipping preview", file=sys.stderr)
        return
    columns = [(pose, i) for pose in POSES for i in range(len(CAT[pose]))]
    cell = (SIZE + 1) * scale
    img = Image.new("RGB", (len(columns) * cell, len(pets) * cell), (0, 0, 0))
    for row, (_, _, _, palette, frames) in enumerate(pets):
        for col, (pose, i) in enumerate(columns):
            seq = frames.get(pose)
            if not seq:
                continue
            f = seq[i % len(seq)]
            for k, c in enumerate(f):
                if c == ".":
                    continue
                y, x = divmod(k, SIZE)
                h = palette[c].lstrip("#")
                rgb = tuple(int(h[j:j + 2], 16) for j in (0, 2, 4))
                x0, y0 = col * cell + x * scale, row * cell + y * scale
                for yy in range(scale):
                    for xx in range(scale):
                        img.putpixel((x0 + xx, y0 + yy), rgb)
    img.save(PREVIEW_OUT)


if __name__ == "__main__":
    data = build()
    write_swift(data)
    write_preview(data)
    print(f"{len(data)} pets -> {os.path.relpath(SWIFT_OUT, ROOT)}")
