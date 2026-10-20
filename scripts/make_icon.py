#!/usr/bin/env python3
"""Draw the app icon from a character's standing frame.

    python3 scripts/make_icon.py Sources/DeskmatesCore/Resources/sprites/vijay build/icon.png

The sprite is scaled by a whole number, so the pixels stay square, then
centred on a transparent canvas with a margin.
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import pixelpng

SIZE = 1024
MARGIN = 0.10


def main(sprite_dir, out_path):
    sprite_dir = pathlib.Path(sprite_dir)
    meta = json.loads((sprite_dir / "sheet.json").read_text())
    cell = meta["frames"][0]["frame"]
    width, height, pixels = pixelpng.read(sprite_dir / "sheet.png")

    frame = [
        pixels[(cell["y"] + y) * width + cell["x"] + x]
        for y in range(cell["h"])
        for x in range(cell["w"])
    ]

    # Trim to the drawn pixels, so the margin is measured from the character
    # and not from the empty part of the cell.
    xs = [i % cell["w"] for i, p in enumerate(frame) if p[3] > 8]
    ys = [i // cell["w"] for i, p in enumerate(frame) if p[3] > 8]
    left, right, top, bottom = min(xs), max(xs), min(ys), max(ys)
    art_w, art_h = right - left + 1, bottom - top + 1

    usable = int(SIZE * (1 - MARGIN * 2))
    scale = max(1, min(usable // art_w, usable // art_h))
    drawn_w, drawn_h = art_w * scale, art_h * scale
    offset_x, offset_y = (SIZE - drawn_w) // 2, (SIZE - drawn_h) // 2

    canvas = [(0, 0, 0, 0)] * (SIZE * SIZE)
    for y in range(drawn_h):
        source_row = (top + y // scale) * cell["w"]
        for x in range(drawn_w):
            pixel = frame[source_row + left + x // scale]
            if pixel[3] > 8:
                canvas[(offset_y + y) * SIZE + offset_x + x] = pixel

    out = pathlib.Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    pixelpng.write(out, SIZE, SIZE, canvas)
    print(f"{out} {SIZE}x{SIZE}, character scaled {scale}x")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
