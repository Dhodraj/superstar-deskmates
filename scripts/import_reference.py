#!/usr/bin/env python3
"""Turn reference images into character sprite sheets.

One image per pose. The importer cuts the background, crops to the figure,
scales every pose to the same height, and writes a sheet plus the Aseprite
JSON the app already reads.

    python3 scripts/import_reference.py Art/reference Sources/Deskmates/Resources/sprites

Three layouts, in the order the importer prefers them:

    Art/reference/vijay/strip-idle-walk-walk-happy.png (one or more strips)
    Art/reference/vijay/idle.png, walk-a.png, walk-b.png, happy.png
    Art/reference/vijay.png

A strip holds every pose in one image, separated by background. That is the one
to ask an image model for: poses generated together share a camera, so they
come back at one scale. Poses generated one at a time do not, and the cast ends
up at different sizes. The tags come from the file name, in order.

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
# How tall a plainly standing figure ends up. The rest of the cell is headroom
# for a raised arm, so a wave does not shrink everyone else.
ANCHOR_HEIGHT = 168
WORK_HEIGHT = 480          # sips does this resize; Python only sees the small one
BACKGROUND_TOLERANCE = 46  # how far from the corner colour still counts as background
EDGE_TOLERANCE = 78        # looser, for the anti-aliased halo left behind
PAD = 1                    # transparent margin, so the figure never touches the cell edge

# Frame order and duration per tag, in milliseconds.
TAG_ORDER = ["idle", "walk", "happy", "busy", "alert", "sleep"]
# A figure tagged `anchor` is a plainly standing copy of the character, put in
# every image so separate images can be matched to one size. It is measured,
# then thrown away.
ANCHOR = "anchor"
DURATION_MS = {"idle": 500, "walk": 260, "happy": 300, "busy": 400, "alert": 260, "sleep": 700}


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


def figures(width, height, pixels):
    """Split a strip into one group of pixels per figure.

    Cutting at empty columns is not enough: a walking figure swings a foot out,
    and two figures that never touch can still share a column. So label the
    connected lumps of paint instead, and treat each big one as a figure.

    A small lump is either part of a figure that is drawn detached, such as a
    coin in the air, or it is a watermark in a corner. Attach the first to the
    nearest figure, and drop the second, which is the one that touches the edge
    of the image.
    """
    label = [-1] * (width * height)
    lumps = []
    for start in range(width * height):
        if label[start] != -1 or pixels[start][3] <= 8:
            continue
        index = len(lumps)
        queue = deque([start])
        label[start] = index
        members, left, right, touches_edge = [], width, -1, False
        while queue:
            at = queue.popleft()
            x, y = at % width, at // width
            members.append(at)
            left, right = min(left, x), max(right, x)
            if x == 0 or y == 0 or x == width - 1 or y == height - 1:
                touches_edge = True
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if not (0 <= nx < width and 0 <= ny < height):
                        continue
                    near = ny * width + nx
                    if label[near] == -1 and pixels[near][3] > 8:
                        label[near] = index
                        queue.append(near)
        lumps.append({
            "members": members,
            "left": left,
            "right": right,
            "edge": touches_edge,
        })

    if not lumps:
        return []

    biggest = max(len(lump["members"]) for lump in lumps)
    big = [lump for lump in lumps if len(lump["members"]) >= biggest * 0.2]
    small = [lump for lump in lumps if len(lump["members"]) < biggest * 0.2]
    big.sort(key=lambda lump: lump["left"])

    for lump in small:
        if lump["edge"]:
            continue                      # a watermark or a stray speck
        middle = (lump["left"] + lump["right"]) / 2
        nearest = min(big, key=lambda f: abs((f["left"] + f["right"]) / 2 - middle))
        nearest["members"].extend(lump["members"])
        nearest["left"] = min(nearest["left"], lump["left"])
        nearest["right"] = max(nearest["right"], lump["right"])

    return big


def cut_out(width, pixels, lump):
    """Crop one figure, keeping only its own pixels.

    Cropping to a rectangle would bring in the neighbour's foot where the two
    overlap, so copy the figure's own pixels and nothing else.
    """
    top = min(at // width for at in lump["members"])
    bottom = max(at // width for at in lump["members"])
    left, right = lump["left"], lump["right"]
    w, h = right - left + 1, bottom - top + 1
    out = [(0, 0, 0, 0)] * (w * h)
    for at in lump["members"]:
        x, y = at % width, at // width
        out[(y - top) * w + (x - left)] = pixels[at]
    return w, h, out


def poses_for(directory, name):
    folder = directory / name
    if folder.is_dir():
        strips = sorted(folder.glob("strip-*.png"))
        if strips:
            # More than one strip is normal: the first covers standing and
            # walking, a later one adds the moods a job needs.
            return [("strip", s, s.stem.split("-")[1:]) for s in strips]
        found = sorted(p for p in folder.iterdir() if p.suffix.lower() == ".png")
        return [(p.stem.split("-")[0], p, None) for p in found]
    return [("idle", directory / f"{name}.png", None)]


def load(path, work, tags):
    """Return the figures in one file, cropped but not yet scaled."""
    small = work / f"{path.stem}-{abs(hash(str(path))) % 10000}.png"
    subprocess.run(
        ["sips", "-Z", str(WORK_HEIGHT), str(path), "--out", str(small)],
        capture_output=True,
        check=True,
    )
    width, height, pixels = pixelpng.read(small)
    pixels = cut_background(width, height, pixels)
    if tags is None:
        return [crop(width, height, pixels)]

    found = figures(width, height, pixels)
    assert len(found) == len(tags), (
        f"{path.name}: {len(tags)} tags in the name but {len(found)} figures in the image"
    )
    return [cut_out(width, pixels, lump) for lump in found]


def scale_for(source, figures):
    """How much to shrink one image's figures.

    When the image carries an anchor, measure that: it is the same standing
    pose in every image, so matching it matches the character across images
    drawn at different distances. Without an anchor, fall back to the tallest
    figure in the image, which only holds when every pose came from one image.
    """
    for tag, (_, height, _) in figures:
        if tag == ANCHOR:
            return ANCHOR_HEIGHT / height
    return TARGET_HEIGHT / max(height for _, (_, height, _) in figures)


def warn_about_mixed_cameras(by_file):
    """Say when two source files were drawn at different distances.

    Every pose is scaled by the tallest figure across all of them, so a file
    shot closer makes every other pose small. Separate generations do not share
    a camera, whatever the prompt asks, so this is worth catching loudly.
    """
    if len(by_file) < 2:
        return
    middles = {name: sorted(heights)[len(heights) // 2] for name, heights in by_file.items()}
    tallest, shortest = max(middles.values()), min(middles.values())
    if tallest <= shortest * 1.15:
        return
    print("  WARNING: these files were drawn at different distances.")
    for name, middle in sorted(middles.items(), key=lambda pair: -pair[1]):
        print(f"    {name:34} typical figure {middle} tall")
    print("  Put every pose in one image, or the small ones will stay small.")


def build(name, poses, out_dir, work):
    cut = {}
    for tag, path, tags in poses:
        found = load(path, work, tags)
        cut[path.name] = list(zip(tags or [tag], found))
        print(f"  {path.name:34} {len(found)} figure(s)")
    if not any(any(tag == ANCHOR for tag, _ in figures) for figures in cut.values()):
        warn_about_mixed_cameras(
            {name: [height for _, (_, height, _) in figures] for name, figures in cut.items()}
        )

    frames = []
    for source, figures in cut.items():
        factor = scale_for(source, figures)
        for tag, (width, height, pixels) in figures:
            if tag == ANCHOR:
                continue
            new_width = max(1, round(width * factor))
            new_height = max(1, round(height * factor))
            frames.append((tag, new_width, new_height, resize(width, height, pixels, new_width, new_height)))
            print(f"  {tag:6} {new_width}x{new_height}")
    frames.sort(key=lambda f: (TAG_ORDER.index(f[0]) if f[0] in TAG_ORDER else 99, f[0]))
    cell_w = max(f[1] for f in frames) + PAD * 2
    cell_h = max(f[2] for f in frames) + PAD * 2
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
