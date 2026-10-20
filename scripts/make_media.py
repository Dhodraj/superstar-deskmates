#!/usr/bin/env python3
"""Build the README animations from the sprite sheets.

    python3 scripts/make_media.py docs

The frames are the real ones the app plays, at the real sizes and the real
timings read out of each sheet's JSON. The background is drawn here rather
than filmed, so no desktop ends up in the picture.
"""
import json
import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import pixelpng

SPRITES = pathlib.Path("Sources/DeskmatesCore/Resources/sprites")
FPS = 20
SCALE = 1                      # sheets are already at the on-screen size
WIDTH, HEIGHT = 760, 230
GROUND = 16                    # how far the feet sit above the bottom edge

TOP = (36, 38, 52, 255)
BOTTOM = (22, 23, 34, 255)
FLOOR = (46, 48, 66, 255)


class Sheet:
    """One character's frames, grouped by tag."""

    def __init__(self, name):
        folder = SPRITES / name
        meta = json.loads((folder / "sheet.json").read_text())
        self.width, self.height, self.pixels = pixelpng.read(folder / "sheet.png")
        self.cells = [f["frame"] for f in meta["frames"]]
        self.holds = [f["duration"] / 1000 for f in meta["frames"]]
        self.tags = {t["name"]: (t["from"], t["to"]) for t in meta["meta"]["frameTags"]}

    def frame(self, tag, step):
        """The frame to show `step` ticks into a looping tag."""
        first, last = self.tags.get(tag, self.tags["idle"])
        count = last - first + 1
        held = max(1, round(self.holds[first] * FPS))
        return first + (step // held) % count

    def size(self, index):
        cell = self.cells[index]
        return cell["w"], cell["h"]

    def draw(self, canvas, index, left, bottom):
        """Paste one frame with its feet on `bottom`, trimmed to its paint."""
        cell = self.cells[index]
        rows = [
            self.pixels[(cell["y"] + y) * self.width + cell["x"] + x]
            for y in range(cell["h"])
            for x in range(cell["w"])
        ]
        lowest = max(
            (i // cell["w"] for i, p in enumerate(rows) if p[3] > 8),
            default=cell["h"] - 1,
        )
        top = bottom - lowest - 1
        for y in range(cell["h"]):
            for x in range(cell["w"]):
                pixel = rows[y * cell["w"] + x]
                if pixel[3] < 8:
                    continue
                px, py = int(left) + x, top + y
                if 0 <= px < WIDTH and 0 <= py < HEIGHT:
                    canvas[py * WIDTH + px] = pixel


def background():
    canvas = []
    for y in range(HEIGHT):
        mix = y / (HEIGHT - 1)
        row = tuple(
            int(TOP[i] + (BOTTOM[i] - TOP[i]) * mix) for i in range(3)
        ) + (255,)
        canvas.extend([row] * WIDTH)
    for y in range(HEIGHT - GROUND, HEIGHT - GROUND + 2):
        for x in range(WIDTH):
            canvas[y * WIDTH + x] = FLOOR
    return canvas


def pill(canvas, text, centre_x, bottom_y):
    """The countdown, drawn as blocks rather than type, because there is no
    font here and the shape is what the picture needs."""
    digits = {
        "0": ["###", "# #", "# #", "# #", "###"],
        "1": [" # ", " # ", " # ", " # ", " # "],
        "2": ["###", "  #", "###", "#  ", "###"],
        "3": ["###", "  #", "###", "  #", "###"],
        "4": ["# #", "# #", "###", "  #", "  #"],
        "5": ["###", "#  ", "###", "  #", "###"],
        "6": ["###", "#  ", "###", "# #", "###"],
        "7": ["###", "  #", "  #", "  #", "  #"],
        "8": ["###", "# #", "###", "# #", "###"],
        "9": ["###", "# #", "###", "  #", "###"],
        ":": ["   ", " # ", "   ", " # ", "   "],
    }
    dot = 2
    glyphs = [digits[c] for c in text]
    inner = sum(len(g[0]) + 1 for g in glyphs) * dot
    pad = 7
    w, h = inner + pad * 2, 5 * dot + pad * 2
    left, top = int(centre_x - w / 2), bottom_y - h
    for y in range(top, top + h):
        for x in range(left, left + w):
            if 0 <= x < WIDTH and 0 <= y < HEIGHT:
                edge = (y in (top, top + h - 1)) and (x in (left, left + w - 1))
                if not edge:
                    canvas[y * WIDTH + x] = (18, 18, 24, 235)
    cursor = left + pad
    for glyph in glyphs:
        for gy, row in enumerate(glyph):
            for gx, ch in enumerate(row):
                if ch != "#":
                    continue
                for dy in range(dot):
                    for dx in range(dot):
                        x, y = cursor + gx * dot + dx, top + pad + gy * dot + dy
                        if 0 <= x < WIDTH and 0 <= y < HEIGHT:
                            canvas[y * WIDTH + x] = (246, 246, 250, 255)
        cursor += (len(glyph[0]) + 1) * dot


def encode(frames_dir, out, seconds):
    palette = frames_dir / "palette.png"
    common = ["-y", "-loglevel", "error", "-framerate", str(FPS),
              "-i", str(frames_dir / "%04d.png")]
    subprocess.run(["ffmpeg", *common, "-vf", "palettegen=stats_mode=diff",
                    str(palette)], check=True)
    subprocess.run(["ffmpeg", *common, "-i", str(palette), "-lavfi",
                    "paletteuse=dither=none", "-loop", "0", str(out)], check=True)
    size = out.stat().st_size / 1024
    print(f"{out}  {seconds:.0f}s  {size:.0f} KB")


def walking(out_dir, work):
    """The hero shot: three characters, one walking across."""
    vijay, ajit, rajni = Sheet("vijay"), Sheet("ajit"), Sheet("rajni")
    seconds = 9
    speed = 11 / FPS * 3        # points per frame, quicker than life for a loop
    total = seconds * FPS
    start, end = -70, WIDTH + 10
    for step in range(total):
        canvas = background()
        floor = HEIGHT - GROUND
        # Spaced so the walker passes between them rather than through one.
        ajit.draw(canvas, ajit.frame("idle", step), 110, floor)
        rajni.draw(canvas, rajni.frame("idle", step), 530, floor)
        x = start + (end - start) * (step / total)
        vijay.draw(canvas, vijay.frame("walk", step), x, floor)
        pixelpng.write(work / f"{step:04d}.png", WIDTH, HEIGHT, canvas)
    encode(work, out_dir / "walking.gif", seconds)


def focus(out_dir, work):
    """Click Vijay: he folds his arms, counts down, then waves."""
    vijay = Sheet("vijay")
    seconds = 8
    total = seconds * FPS
    floor = HEIGHT - GROUND
    for step in range(total):
        canvas = background()
        phase = step / total
        if phase < 0.12:
            tag, label = "idle", None
        elif phase < 0.78:
            tag = "busy"
            left = int(25 * 60 * (1 - (phase - 0.12) / 0.66))
            label = f"{left // 60}:{left % 60:02d}"
        else:
            tag, label = "happy", None
        index = vijay.frame(tag, step)
        width, _ = vijay.size(index)
        centre = WIDTH / 2
        vijay.draw(canvas, index, centre - width / 2, floor)
        if label:
            pill(canvas, label, centre, floor - 150)
        pixelpng.write(work / f"{step:04d}.png", WIDTH, HEIGHT, canvas)
    encode(work, out_dir / "focus.gif", seconds)


def main(out_dir):
    out_dir = pathlib.Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, build in (("walking", walking), ("focus", focus)):
        work = out_dir / f".frames-{name}"
        shutil.rmtree(work, ignore_errors=True)
        work.mkdir()
        build(out_dir, work)
        shutil.rmtree(work)


if __name__ == "__main__":
    main(sys.argv[1])
