#!/usr/bin/env python3
"""Draw the placeholder sprite sheet and its Aseprite-shaped JSON.

Real characters come from Aseprite. This exists so the spike has art to load
before anyone draws a frame, and so the loader is tested against the same JSON
shape Aseprite writes.
"""
import json
import pathlib
import struct
import sys
import zlib

CELL = 16          # art is authored at 16x16
SCALE = 2          # and doubled, so one cell on the sheet is 32x32
PALETTE = {
    ".": (0, 0, 0, 0),
    "H": (40, 32, 48, 255),        # hair
    "S": (232, 180, 140, 255),     # skin
    "E": (32, 24, 32, 255),        # eye
    "K": (24, 20, 28, 255),        # outline, mouth
    "B": (64, 120, 200, 255),      # shirt
    "F": (90, 70, 55, 255),        # shoe
}

BODY = [
    "................",
    ".....HHHHHH.....",
    "....HHHHHHHH....",
    "....HSSSSSSH....",
    "....SSSSSSSS....",
    "....SSESSESS....",
    "....SSSSSSSS....",
    ".....SKKKKS.....",
    "......SSSS......",
    "...BBBBBBBBBB...",
    "..SBBBBBBBBBBS..",
    "..SBBBBBBBBBBS..",
    "...BBBBBBBBBB...",
]
LEGS_TOGETHER = ["...BBBB..BBBB...", "...BBBB..BBBB...", "...FFFF..FFFF..."]
LEGS_APART = ["..BBBB....BBBB..", "..BBBB....BBBB..", "..FFFF....FFFF.."]


def frame(legs, drop=0):
    rows = BODY + legs
    if drop:
        rows = ["." * CELL] * drop + rows[:-drop]
    assert len(rows) == CELL, len(rows)
    for r in rows:
        assert len(r) == CELL, (len(r), r)
    return rows


FRAMES = [
    ("idle", frame(LEGS_TOGETHER)),
    ("idle", frame(LEGS_TOGETHER, drop=1)),
    ("walk", frame(LEGS_APART)),
    ("walk", frame(LEGS_TOGETHER, drop=1)),
    ("walk", frame(LEGS_APART)),
    ("walk", frame(LEGS_TOGETHER)),
]
DURATION_MS = {"idle": 400, "walk": 120}


def write_png(path, width, height, pixels):
    rows = b"".join(
        b"\x00" + bytes(v for x in range(width) for v in pixels[y * width + x])
        for y in range(height)
    )

    def chunk(kind, data):
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(rows, 9))
        + chunk(b"IEND", b"")
    )


def main(out_dir):
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    cell = CELL * SCALE
    width, height = cell * len(FRAMES), cell
    pixels = [(0, 0, 0, 0)] * (width * height)
    for index, (_, rows) in enumerate(FRAMES):
        for y, row in enumerate(rows):
            for x, char in enumerate(row):
                colour = PALETTE[char]
                for dy in range(SCALE):
                    for dx in range(SCALE):
                        px = index * cell + x * SCALE + dx
                        py = y * SCALE + dy
                        pixels[py * width + px] = colour
    write_png(out / "sheet.png", width, height, pixels)

    tags, frames = [], []
    for index, (tag, _) in enumerate(FRAMES):
        frames.append(
            {
                "filename": f"placeholder {index}.aseprite",
                "frame": {"x": index * cell, "y": 0, "w": cell, "h": cell},
                "rotated": False,
                "trimmed": False,
                "spriteSourceSize": {"x": 0, "y": 0, "w": cell, "h": cell},
                "sourceSize": {"w": cell, "h": cell},
                "duration": DURATION_MS[tag],
            }
        )
        if tags and tags[-1]["name"] == tag:
            tags[-1]["to"] = index
        else:
            tags.append({"name": tag, "from": index, "to": index, "direction": "forward", "color": "#000000ff"})

    data = {
        "frames": frames,
        "meta": {
            "app": "scripts/make_placeholder_sheet.py",
            "format": "RGBA8888",
            "size": {"w": width, "h": height},
            "scale": "1",
            "frameTags": tags,
        },
    }
    (out / "sheet.json").write_text(json.dumps(data, indent=1) + "\n")
    print(f"{width}x{height}, {len(frames)} frames, tags: {[t['name'] for t in tags]}")


if __name__ == "__main__":
    main(sys.argv[1])
