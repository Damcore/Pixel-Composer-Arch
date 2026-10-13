#!/usr/bin/env python3
"""Set a PNG file as an X11 window's EWMH _NET_WM_ICON property."""

from __future__ import annotations

import ctypes
import ctypes.util
import struct
import sys
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def read_rgba_png(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"not a PNG file: {path}")

    width = height = bit_depth = color_type = interlace = None
    compressed = bytearray()
    offset = len(PNG_SIGNATURE)
    while offset + 12 <= len(data):
        length = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4 : offset + 8]
        begin = offset + 8
        end = begin + length
        if end + 4 > len(data):
            raise ValueError("truncated PNG chunk")
        payload = data[begin:end]
        if kind == b"IHDR":
            width, height, bit_depth, color_type, _compression, _filter, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            break
        offset = end + 4

    if not width or not height or bit_depth != 8 or color_type != 6 or interlace != 0:
        raise ValueError("icon PNG must be non-interlaced 8-bit RGBA")

    stride = width * 4
    scanlines = zlib.decompress(compressed)
    if len(scanlines) != height * (stride + 1):
        raise ValueError("unexpected PNG scanline length")

    rgba = bytearray(height * stride)
    previous = bytearray(stride)
    source = 0
    for y in range(height):
        filter_type = scanlines[source]
        source += 1
        row = bytearray(scanlines[source : source + stride])
        source += stride
        if filter_type not in (0, 1, 2, 3, 4):
            raise ValueError(f"unsupported PNG filter: {filter_type}")
        for i in range(stride):
            left = row[i - 4] if i >= 4 else 0
            above = previous[i]
            upper_left = previous[i - 4] if i >= 4 else 0
            if filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = above
            elif filter_type == 3:
                predictor = (left + above) // 2
            elif filter_type == 4:
                p = left + above - upper_left
                pa = abs(p - left)
                pb = abs(p - above)
                pc = abs(p - upper_left)
                predictor = left if pa <= pb and pa <= pc else above if pb <= pc else upper_left
            else:
                predictor = 0
            row[i] = (row[i] + predictor) & 0xFF
        rgba[y * stride : (y + 1) * stride] = row
        previous = row
    return width, height, bytes(rgba)


def packed_argb(width: int, height: int, rgba: bytes, size: int) -> list[int]:
    stride = width * 4
    output = [size, size]
    for y in range(size):
        source_y = (y * height) // size
        for x in range(size):
            source_x = (x * width) // size
            offset = source_y * stride + source_x * 4
            r, g, b, a = rgba[offset : offset + 4]
            output.append((a << 24) | (r << 16) | (g << 8) | b)
    return output


def set_icon(window_id: int, icon_path: Path) -> None:
    width, height, rgba = read_rgba_png(icon_path)
    values = packed_argb(width, height, rgba, 32) + packed_argb(width, height, rgba, 64)
    cardinals = (ctypes.c_ulong * len(values))(*values)

    library = ctypes.util.find_library("X11")
    if not library:
        raise RuntimeError("libX11 was not found")
    x11 = ctypes.CDLL(library)
    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
    x11.XInternAtom.restype = ctypes.c_ulong
    x11.XChangeProperty.argtypes = [
        ctypes.c_void_p,
        ctypes.c_ulong,
        ctypes.c_ulong,
        ctypes.c_ulong,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.POINTER(ctypes.c_ubyte),
        ctypes.c_int,
    ]
    x11.XChangeProperty.restype = ctypes.c_int
    x11.XFlush.argtypes = [ctypes.c_void_p]
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]

    display = x11.XOpenDisplay(None)
    if not display:
        raise RuntimeError("could not connect to the X display")
    try:
        icon_atom = x11.XInternAtom(display, b"_NET_WM_ICON", 0)
        cardinal_atom = x11.XInternAtom(display, b"CARDINAL", 0)
        result = x11.XChangeProperty(
            display,
            window_id,
            icon_atom,
            cardinal_atom,
            32,
            0,
            ctypes.cast(cardinals, ctypes.POINTER(ctypes.c_ubyte)),
            len(values),
        )
        if result == 0:
            raise RuntimeError("XChangeProperty failed")
        x11.XFlush(display)
    finally:
        x11.XCloseDisplay(display)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: set-window-icon.py WINDOW_ID ICON.png")
    set_icon(int(sys.argv[1], 0), Path(sys.argv[2]))
