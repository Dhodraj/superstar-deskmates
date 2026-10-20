#!/usr/bin/env python3
"""Draw the app icon: a flat cutout of a character, propped on a base.

    python3 scripts/make_logo.py build/icon.png

Authored at 16x16 and scaled by a whole number, so the pixels stay square at
every icon size. Drawn here rather than kept as an image file, so the icon
rebuilds with the app and there is nothing to keep in step.
"""
import pathlib
import subprocess
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
    "S": (232, 180, 140, 255),
    "H": (46, 38, 54, 255),
}

# A cutout on a stand: the flat standee propped outside a theatre, and also
# what a character on a desktop is. The red headband is Vijay's, which keeps
# the mark tied to the cast rather than to a generic figure.
MARK = [
    "................",
    "................",
    "......HHHH......",
    ".....HRRRRH.....",
    ".....SSSSSS.....",
    "......SSSS......",
    "....WWWWWWWW....",
    "...WWWWWWWWWW...",
    "...WWWWWWWWWW...",
    "....WWWWWWWW....",
    ".....WW..WW.....",
    ".....WW..WW.....",
    "...WWWWWWWWWW...",
    "..WWWWWWWWWWWW..",
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


SOURCE = pathlib.Path("Art/icon-source.png")


def round_corners(size, pixels):
    """Cut the tile corners, so a square image becomes an app icon.

    The source is asked for as a solid square because image models are
    unreliable with transparency. The shape is added here instead.
    """
    radius = int(size * 0.22)
    for y in range(size):
        for x in range(size):
            cx = min(max(x, radius), size - 1 - radius)
            cy = min(max(y, radius), size - 1 - radius)
            if (x - cx) ** 2 + (y - cy) ** 2 > radius * radius:
                pixels[y * size + x] = (0, 0, 0, 0)
    return pixels


def from_source(work):
    """Use the drawn artwork when there is some, scaled to the icon size."""
    scaled = work / "icon-source-scaled.png"
    subprocess.run(
        ["sips", "-z", str(SIZE), str(SIZE), str(SOURCE), "--out", str(scaled)],
        capture_output=True,
        check=True,
    )
    _, _, pixels = pixelpng.read(scaled)
    return round_corners(SIZE, list(pixels))


def main(out_path):
    out = pathlib.Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    if SOURCE.exists():
        pixels = from_source(out.parent)
        where = SOURCE
    else:
        pixels = draw(SIZE)
        where = "drawn in code"
    pixelpng.write(out, SIZE, SIZE, pixels)
    print(f"{out} {SIZE}x{SIZE} from {where}")


if __name__ == "__main__":
    main(sys.argv[1])
