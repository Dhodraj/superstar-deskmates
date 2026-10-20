#!/usr/bin/env python3
"""Draw the character sprite sheets and their Aseprite-shaped JSON.

Each character is authored at 16x16 and doubled, so one cell on the sheet is
32x32. The art follows the reference images in Art/reference/, cut down to the
few cues that survive that size.

The JSON matches what Aseprite writes with `--format json-array --list-tags`,
so the loader is tested against the shape it will meet when the art is drawn in
Aseprite instead.
"""
import json
import pathlib
import struct
import sys
import zlib

CELL = 16
SCALE = 2

PALETTE = {
    ".": (0, 0, 0, 0),
    "S": (232, 180, 140, 255),   # skin
    "E": (32, 24, 32, 255),      # eye
    "K": (24, 20, 28, 255),      # black: sunglasses, shoes, moustache
    "W": (240, 238, 230, 255),   # white cloth
    "R": (210, 40, 40, 255),     # red
    "Y": (240, 185, 40, 255),    # yellow
    "G": (185, 185, 190, 255),   # grey hair
    "H": (40, 32, 48, 255),      # dark hair
    "T": (198, 160, 96, 255),    # tan suit
    "F": (90, 70, 55, 255),      # shoe
    "O": (24, 20, 28, 255),      # outline, added automatically
}

# Vijay: white shirt and trousers, red headband, red and yellow scarf down the
# chest, rolled sleeves so the forearms are bare.
VIJAY = [
    "................",
    ".....HHHHHH.....",
    "....HHHHHHHH....",
    "....RRRRRRRR....",
    "....SSSSSSSS....",
    "....SSESSESS....",
    "....SSSSSSSS....",
    ".....SKKKKS.....",
    "......SKKS......",
    "...WWWRYWWWWW...",
    "..SWWWRYWWWWWS..",
    "..SWWWRYWWWWWS..",
    "...WWWRYWWWWW...",
]
# Waving, which is how he arrives in the reference. His `happy` frames.
VIJAY_WAVE_A = [
    "..S.............",
    "..S..HHHHHH.....",
    "..S.HHHHHHHH....",
    "...SRRRRRRRR....",
    "...SSSSSSSSS....",
    "...SSSESSESS....",
    "....SSSSSSSS....",
    ".....SKKKKS.....",
    "......SKKS......",
    "...WWWRYWWWWW...",
    "...WWWRYWWWWWS..",
    "...WWWRYWWWWWS..",
    "...WWWRYWWWWW...",
]
VIJAY_WAVE_B = [
    "................",
    "...S.HHHHHH.....",
    "...SHHHHHHHH....",
    "...SRRRRRRRR....",
    "...SSSSSSSSS....",
    "...SSSESSESS....",
    "....SSSSSSSS....",
    ".....SKKKKS.....",
    "......SKKS......",
    "...WWWRYWWWWW...",
    "...WWWRYWWWWWS..",
    "...WWWRYWWWWWS..",
    "...WWWRYWWWWW...",
]

# Ajit: white race suit, grey hair and full grey beard, red and yellow stripes
# down the outside of the arms and legs, red boots.
AJIT = [
    "................",
    ".....GGGGGG.....",
    "....GGGGGGGG....",
    "....GSSSSSSG....",
    "....SSSSSSSS....",
    "....SSESSESS....",
    "....SSSSSSSS....",
    ".....GGGGGG.....",
    "......GGGG......",
    "...RWWWWWWWWR...",
    "..SRWWWWWWWWRS..",
    "..SRWWWWWWWWRS..",
    "...RWWWWWWWWR...",
]
# Helmet on, which is what he does when a run is going. His `busy` frames.
AJIT_HELMET_A = [
    "................",
    "....WWWWWWWW....",
    "...WWWWWWWWWW...",
    "...WWWWWWWWWW...",
    "...WKKKKKKKKW...",
    "...WKKKKKKKKW...",
    "...WWWWWWWWWW...",
    "....WWWWWWWW....",
    "......SSSS......",
    "...RWWWWWWWWR...",
    "..SRWWWWWWWWRS..",
    "..SRWWWWWWWWRS..",
    "...RWWWWWWWWR...",
]
AJIT_HELMET_B = [
    "................",
    "....WWWWWWWW....",
    "...WWWRRWWWWW...",
    "...WWWWWWWWWW...",
    "...WKKKYKKKKW...",
    "...WKKKKKKKKW...",
    "...WWWWWWWWWW...",
    "....WWWWWWWW....",
    "......SSSS......",
    "...RWWWWWWWWR...",
    "..SRWWWWWWWWRS..",
    "..SRWWWWWWWWRS..",
    "...RWWWWWWWWR...",
]

# Rajni: tan suit over a white shirt, patterned tie, black sunglasses, dark
# hair swept back with a grey streak.
RAJNI = [
    "................",
    "....HHHHHHHG....",
    "...HHHHHHHHGG...",
    "...HSSSSSSSSG...",
    "....SSSSSSSS....",
    "....SKKKKKKS....",
    "....SSSSSSSS....",
    "......KKKK......",
    "......SSSS......",
    "...TTTWRWTTTT...",
    "..STTTWRWTTTTS..",
    "..STTTWRWTTTTS..",
    "...TTTTRTTTTT...",
]

CHARACTERS = {
    "vijay": {
        "body": VIJAY,
        "leg": "W",
        "shoe": "F",
        "palette": {"F": (190, 186, 176, 255)},
        "extra": [("happy", VIJAY_WAVE_A), ("happy", VIJAY_WAVE_B)],
    },
    "ajit": {
        "body": AJIT,
        "leg": "W",
        "shoe": "R",
        "stripe": "R",
        "extra": [("busy", AJIT_HELMET_A), ("busy", AJIT_HELMET_B)],
    },
    "rajni": {
        "body": RAJNI,
        "leg": "T",
        "shoe": "F",
    },
}

DURATION_MS = {"idle": 400, "walk": 120, "happy": 260, "busy": 300}


def legs(character, apart):
    """Trouser and shoe rows, with Ajit's suit stripe down the outer seam."""
    leg, shoe = character["leg"], character["shoe"]
    stripe = character.get("stripe")
    # The legs are three wide with a four-wide gap. A narrower gap gets filled
    # solid by the outline from both sides, and the character reads as one leg.
    if apart:
        trouser = f"..{leg * 3}......{leg * 3}.."
        foot = f"..{shoe * 3}......{shoe * 3}.."
        if stripe:
            trouser = f"..{stripe}{leg * 2}......{leg * 2}{stripe}.."
    else:
        trouser = f"...{leg * 3}....{leg * 3}..."
        foot = f"...{shoe * 3}....{shoe * 3}..."
        if stripe:
            trouser = f"...{stripe}{leg * 2}....{leg * 2}{stripe}..."
    return [trouser, trouser, foot]


def outline(rows):
    """Ring the figure in dark pixels.

    Without it a white suit disappears on a pale desktop. The references are
    drawn the same way. Outlining here, before the art is doubled, keeps the
    ring the same width as every other pixel.
    """
    ringed = [list(row) for row in rows]
    for y, row in enumerate(rows):
        for x, char in enumerate(row):
            if char != ".":
                continue
            neighbours = [
                rows[y + dy][x + dx]
                for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))
                if 0 <= y + dy < CELL and 0 <= x + dx < CELL
            ]
            if any(n not in ".O" for n in neighbours):
                ringed[y][x] = "O"
    return ["".join(row) for row in ringed]


def frame(character, body, apart=False, drop=0):
    rows = list(body) + legs(character, apart)
    if drop:
        rows = ["." * CELL] * drop + rows[:-drop]
    assert len(rows) == CELL, len(rows)
    for row in rows:
        assert len(row) == CELL, (len(row), row)
    return outline(rows)


def frames_for(character):
    body = character["body"]
    sheet = [
        ("idle", frame(character, body)),
        ("idle", frame(character, body, drop=1)),
        ("walk", frame(character, body, apart=True)),
        ("walk", frame(character, body, drop=1)),
        ("walk", frame(character, body, apart=True)),
        ("walk", frame(character, body)),
    ]
    for tag, extra in character.get("extra", []):
        sheet.append((tag, frame(character, extra)))
    return sheet


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
    palette = dict(PALETTE, **character.get("palette", {}))
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
