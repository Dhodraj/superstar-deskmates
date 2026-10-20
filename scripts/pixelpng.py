"""Minimal PNG read and write, so the importer needs no installed library.

Handles what `sips` writes: 8-bit non-interlaced RGB or RGBA.
"""
import struct
import zlib

RGB, RGBA = 2, 6


def read(path):
    """Return (width, height, pixels) where pixels is a flat list of RGBA tuples."""
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"{path}: not a PNG"
    pos, idat, width, height, colour, depth = 8, b"", 0, 0, None, 8
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            width, height, depth, colour, _, _, interlace = struct.unpack(">IIBBBBB", body)
            assert depth == 8, f"{path}: {depth}-bit PNG not supported"
            assert interlace == 0, f"{path}: interlaced PNG not supported"
            assert colour in (RGB, RGBA), f"{path}: colour type {colour} not supported"
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length

    channels = 3 if colour == RGB else 4
    raw = zlib.decompress(idat)
    stride = width * channels
    out = []
    previous = bytearray(stride)
    at = 0
    for _ in range(height):
        filter_type = raw[at]
        line = bytearray(raw[at + 1:at + 1 + stride])
        at += 1 + stride
        if filter_type == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 255
        elif filter_type == 2:
            for i in range(stride):
                line[i] = (line[i] + previous[i]) & 255
        elif filter_type == 3:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + previous[i]) >> 1)) & 255
        elif filter_type == 4:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                up = previous[i]
                corner = previous[i - channels] if i >= channels else 0
                estimate = left + up - corner
                da, db, dc = abs(estimate - left), abs(estimate - up), abs(estimate - corner)
                best = left if da <= db and da <= dc else up if db <= dc else corner
                line[i] = (line[i] + best) & 255
        for x in range(width):
            base = x * channels
            if channels == 4:
                out.append((line[base], line[base + 1], line[base + 2], line[base + 3]))
            else:
                out.append((line[base], line[base + 1], line[base + 2], 255))
        previous = line
    return width, height, out


def write(path, width, height, pixels):
    rows = b"".join(
        b"\x00" + bytes(v for x in range(width) for v in pixels[y * width + x])
        for y in range(height)
    )

    def chunk(kind, body):
        return (
            struct.pack(">I", len(body))
            + kind
            + body
            + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", width, height, 8, RGBA, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(rows, 9))
        + chunk(b"IEND", b"")
    )
