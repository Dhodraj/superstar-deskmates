#!/usr/bin/env python3
"""Turn reference images into character sprite sheets.

One image per pose. The importer cuts the background, crops to the figure,
scales every pose to the same height, and writes a sheet plus the Aseprite
JSON the app already reads.

    python3 scripts/import_reference.py Art/reference Sources/Deskmates/Resources/sprites

Layout it expects, where the file name is the animation tag:

    Art/reference/vijay/idle.png
    Art/reference/vijay/walk-a.png
    Art/reference/vijay/walk-b.png
    Art/reference/vijay/happy.png

A bare `Art/reference/vijay.png` is read as a single idle frame, which is what
the first references were.

Resolution is the whole point. Spritefolk draws its characters at about
120x193 real pixels. Art at 32x32 stretched to the same size cannot carry a
face, so the target here is the same order: 192 pixels tall.
"""
import json
import pathlib
import subprocess
import sys
import tempfile
from collections import deque

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import pixelpng

TARGET_HEIGHT = 192
WORK_HEIGHT = 480          # sips does this resize; Python only sees the small one
BACKGROUND_TOLERANCE = 46  # how far from the corner colour still counts as background
EDGE_TOLERANCE = 78        # looser, for the anti-aliased halo left behind
PAD = 1                    # transparent margin, so the figure never touches the cell edge

# Frame order and duration per tag, in milliseconds.
TAG_ORDER = ["idle", "walk", "happy", "busy", "alert", "sleep"]
DURATION_MS = {"idle": 400, "walk": 150, "happy": 260, "busy": 300, "alert": 220, "sleep": 600}


def near(a, b, tolerance):
    return (
        abs(a[0] - b[0]) <= tolerance
        and abs(a[1] - b[1]) <= tolerance
        and abs(a[2] - b[2]) <= tolerance
    )


def cut_background(width, height, pixels):
    """Flood the background in from the border and make it transparent.

    Flooding from the border rather than keying on colour is what lets Vijay
    and Ajit keep their white clothes: the dark outline round each figure stops
    the flood before it reaches them.
    """
    background = pixels[0]
    out = list(pixels)
    seen = bytearray(width * height)
    queue = deque()
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if not (0 <= x < width and 0 <= y < height):
            continue
        index = y * width + x
        if seen[index]:
            continue
        if not near(pixels[index], background, BACKGROUND_TOLERANCE):
            continue
        seen[index] = 1
        out[index] = (0, 0, 0, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))

    # The resize left a soft halo where the figure met the background. Clear the
    # pixels that are still close to the background colour and touch a hole.
    for y in range(height):
        for x in range(width):
            index = y * width + x
            if out[index][3] == 0:
                continue
            if not near(out[index], background, EDGE_TOLERANCE):
                continue
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height and out[ny * width + nx][3] == 0:
                    out[index] = (0, 0, 0, 0)
                    break
    return out


def crop(width, height, pixels):
    left, right, top, bottom = width, -1, height, -1
    for y in range(height):
        row = y * width
        for x in range(width):
            if pixels[row + x][3] > 8:
                left = min(left, x)
                right = max(right, x)
                top = min(top, y)
                bottom = max(bottom, y)
    assert right >= left, "nothing left after cutting the background"
    w, h = right - left + 1, bottom - top + 1
    out = [pixels[(top + y) * width + left + x] for y in range(h) for x in range(w)]
    return w, h, out


def resize(width, height, pixels, new_width, new_height):
    """Box filter on premultiplied alpha, so edges do not pick up a fringe."""
    out = []
    for ny in range(new_height):
        y0, y1 = ny * height // new_height, max(ny * height // new_height + 1, (ny + 1) * height // new_height)
        for nx in range(new_width):
            x0, x1 = nx * width // new_width, max(nx * width // new_width + 1, (nx + 1) * width // new_width)
            r = g = b = a = n = 0
            for y in range(y0, y1):
                row = y * width
                for x in range(x0, x1):
                    pr, pg, pb, pa = pixels[row + x]
                    r += pr * pa
                    g += pg * pa
                    b += pb * pa
                    a += pa
                    n += 1
            if a == 0:
                out.append((0, 0, 0, 0))
            else:
                out.append((r // a, g // a, b // a, a // n))
    return out


def poses_for(directory, name):
    folder = directory / name
    if folder.is_dir():
        found = sorted(p for p in folder.iterdir() if p.suffix.lower() == ".png")
        return [(p.stem.split("-")[0], p) for p in found]
    return [("idle", directory / f"{name}.png")]


def load(path, work):
    small = work / f"{path.stem}-{abs(hash(str(path))) % 10000}.png"
    subprocess.run(
        ["sips", "-Z", str(WORK_HEIGHT), str(path), "--out", str(small)],
        capture_output=True,
        check=True,
    )
    width, height, pixels = pixelpng.read(small)
    pixels = cut_background(width, height, pixels)
    width, height, pixels = crop(width, height, pixels)
    new_width = max(1, round(width * TARGET_HEIGHT / height))
    return new_width, TARGET_HEIGHT, resize(width, height, pixels, new_width, TARGET_HEIGHT)


def build(name, poses, out_dir, work):
    frames = []
    for tag, path in poses:
        width, height, pixels = load(path, work)
        frames.append((tag, width, height, pixels))
        print(f"  {tag:6} {path.name:16} {width}x{height}")

    frames.sort(key=lambda f: (TAG_ORDER.index(f[0]) if f[0] in TAG_ORDER else 99, f[0]))
    cell_w = max(f[1] for f in frames) + PAD * 2
    cell_h = TARGET_HEIGHT + PAD * 2
    sheet_w, sheet_h = cell_w * len(frames), cell_h
    sheet = [(0, 0, 0, 0)] * (sheet_w * sheet_h)

    for index, (_, width, height, pixels) in enumerate(frames):
        # Centred horizontally and sitting on the floor of the cell, so a pose
        # with a raised arm does not make the character hop.
        ox = index * cell_w + (cell_w - width) // 2
        oy = cell_h - PAD - height
        for y in range(height):
            for x in range(width):
                sheet[(oy + y) * sheet_w + ox + x] = pixels[y * width + x]

    out_dir.mkdir(parents=True, exist_ok=True)
    pixelpng.write(out_dir / "sheet.png", sheet_w, sheet_h, sheet)

    tags, records = [], []
    for index, (tag, _, _, _) in enumerate(frames):
        records.append({
            "filename": f"{name} {index}.aseprite",
            "frame": {"x": index * cell_w, "y": 0, "w": cell_w, "h": cell_h},
            "rotated": False,
            "trimmed": False,
            "spriteSourceSize": {"x": 0, "y": 0, "w": cell_w, "h": cell_h},
            "sourceSize": {"w": cell_w, "h": cell_h},
            "duration": DURATION_MS.get(tag, 300),
        })
        if tags and tags[-1]["name"] == tag:
            tags[-1]["to"] = index
        else:
            tags.append({"name": tag, "from": index, "to": index,
                         "direction": "forward", "color": "#000000ff"})

    (out_dir / "sheet.json").write_text(json.dumps({
        "frames": records,
        "meta": {
            "app": "scripts/import_reference.py",
            "format": "RGBA8888",
            "size": {"w": sheet_w, "h": sheet_h},
            "scale": "1",
            "frameTags": tags,
        },
    }, indent=1) + "\n")
    print(f"  -> {sheet_w}x{sheet_h}, tags {[t['name'] for t in tags]}")


def main(reference_root, sprites_root):
    reference_root, sprites_root = pathlib.Path(reference_root), pathlib.Path(sprites_root)
    names = sorted({p.stem for p in reference_root.glob("*.png")} |
                   {p.name for p in reference_root.iterdir() if p.is_dir()})
    with tempfile.TemporaryDirectory() as temp:
        work = pathlib.Path(temp)
        for name in names:
            print(name)
            build(name, poses_for(reference_root, name), sprites_root / name, work)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
