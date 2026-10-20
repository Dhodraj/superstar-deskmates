#!/usr/bin/env python3
"""Draw the app icon: a film slate with the red and yellow stripe.

    python3 scripts/make_logo.py build/icon.png

Authored at 16x16 and scaled by a whole number, so the pixels stay square at
every icon size. Drawn here rather than kept as an image file, so the icon
rebuilds with the app and there is nothing to keep in step.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import pixelpng

SIZE = 1024
INK = (24, 22, 30, 255)
PALETTE = {
    ".": None,
    "K": INK,
    "W": (244, 242, 235, 255),
    "R": (214, 48, 45, 255),
    "Y": (243, 186, 54, 255),
}

# The hinged stick with its teeth, then the slate below it.
MARK = [
    "................",
    "................",
    "..KWKKWKKWKKWK..",
    ".WKKWKKWKKWKKWW.",
    ".WWWWWWWWWWWWWW.",
    ".WKKKKKKKKKKKKW.",
    ".WK..........KW.",
    ".WK.RR....YY.KW.",
    ".WK.RR....YY.KW.",
    ".WK.RR....YY.KW.",
    ".WK..........KW.",
    ".WKKKKKKKKKKKKW.",
    ".WWWWWWWWWWWWWW.",
    "................",
    "................",
    "................",
]


def draw(size):
    """The mark on a rounded tile, centred."""
    scale = size // 16
    out = [(0, 0, 0, 0)] * (size * size)
    radius = max(1, int(size * 0.22))
    for y in range(size):
        for x in range(size):
            cx = min(max(x, radius), size - 1 - radius)
            cy = min(max(y, radius), size - 1 - radius)
            if (x - cx) ** 2 + (y - cy) ** 2 <= radius * radius:
                out[y * size + x] = INK
    for y, row in enumerate(MARK):
        for x, char in enumerate(row):
            colour = PALETTE[char]
            if colour is None:
                continue
            for dy in range(scale):
                for dx in range(scale):
                    out[(y * scale + dy) * size + x * scale + dx] = colour
    return out


def main(out_path):
    out = pathlib.Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    pixelpng.write(out, SIZE, SIZE, draw(SIZE))
    print(f"{out} {SIZE}x{SIZE}")


if __name__ == "__main__":
    main(sys.argv[1])
