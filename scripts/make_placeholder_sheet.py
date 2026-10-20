#!/usr/bin/env python3
"""Draw placeholder sprite sheets and their Aseprite-shaped JSON.

Real characters come from Aseprite. These exist so the stage has art to load
before anyone draws a frame, and so the loader is tested against the same JSON
shape Aseprite writes.

The three placeholders also test one claim from DESIGN.md: that sunglasses,
dithered grey hair and a plain face read apart at this size.
"""
import json
import pathlib
import struct
import sys
import zlib

CELL = 16          # art is authored at 16x16
SCALE = 2          # and doubled, so one cell on the sheet is 32x32

SKIN = (232, 180, 140, 255)
DARK = (24, 20, 28, 255)
HAIR = (40, 32, 48, 255)
SHOE = (90, 70, 55, 255)

BASE = [
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

# Each character overrides a few rows. That is the whole difference between
# them, which is the point: a silhouette cue is two or three pixels.
CHARACTERS = {
    "vijay": {
        "shirt": (64, 120, 200, 255),
        "rows": {},
    },
    "ajit": {
        "shirt": (150, 54, 60, 255),
        "rows": {
            1: ".....HGHGHG.....",
            2: "....GHGHGHGH....",
            6: "....KSSSSSSK....",
            7: ".....KKKKKK.....",
        },
    },
    "rajni": {
        "shirt": (226, 224, 214, 255),
        "rows": {
            5: "....KKKKKKKK....",
        },
    },
}
DURATION_MS = {"idle": 400, "walk": 120}


def frame(character, legs, drop=0):
    rows = [character["rows"].get(i, row) for i, row in enumerate(BASE)] + legs
    if drop:
        rows = ["." * CELL] * drop + rows[:-drop]
    assert len(rows) == CELL, len(rows)
    for row in rows:
        assert len(row) == CELL, (len(row), row)
    return rows


def frames_for(character):
    return [
        ("idle", frame(character, LEGS_TOGETHER)),
        ("idle", frame(character, LEGS_TOGETHER, drop=1)),
        ("walk", frame(character, LEGS_APART)),
        ("walk", frame(character, LEGS_TOGETHER, drop=1)),
        ("walk", frame(character, LEGS_APART)),
        ("walk", frame(character, LEGS_TOGETHER)),
    ]


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


def build(name, character, out):
    palette = {
        ".": (0, 0, 0, 0),
        "H": HAIR,
        "G": (150, 148, 156, 255),   # the grey half of dithered hair
        "S": SKIN,
        "E": (32, 24, 32, 255),
        "K": DARK,
        "B": character["shirt"],
        "F": SHOE,
    }
    sheet = frames_for(character)
    cell = CELL * SCALE
    width, height = cell * len(sheet), cell
    pixels = [(0, 0, 0, 0)] * (width * height)
    for index, (_, rows) in enumerate(sheet):
        for y, row in enumerate(rows):
            for x, char in enumerate(row):
                colour = palette[char]
                for dy in range(SCALE):
                    for dx in range(SCALE):
                        pixels[(y * SCALE + dy) * width + index * cell + x * SCALE + dx] = colour

    out.mkdir(parents=True, exist_ok=True)
    write_png(out / "sheet.png", width, height, pixels)

    tags, frames = [], []
    for index, (tag, _) in enumerate(sheet):
        frames.append(
            {
                "filename": f"{name} {index}.aseprite",
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
            tags.append(
                {"name": tag, "from": index, "to": index, "direction": "forward", "color": "#000000ff"}
            )

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
    return width, height, [t["name"] for t in tags]


def main(root):
    root = pathlib.Path(root)
    for name, character in CHARACTERS.items():
        width, height, tags = build(name, character, root / name)
        print(f"{name}: {width}x{height}, tags {tags}")


if __name__ == "__main__":
    main(sys.argv[1])
