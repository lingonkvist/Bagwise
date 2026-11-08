#!/usr/bin/env python3
"""Render the addon-list icon (textures/icon.tga, 128x128).

One bronze-framed inventory slot on a dark tile, with a pearl painted in an
angle (conic) gradient: it starts at 12 o'clock in yellow and sweeps clockwise
through green to a teal green, with a hard seam where it meets itself, like
Photoshop's Angle gradient. The colours were sampled from the reference art,
smoothed, and a pearl finish (luster, dome shading, a film of colour at the
rim) sits on top without hiding the sweep.

Usage: python3 tools/make_icon.py [--out textures/icon.tga]
Needs only numpy; writes a plain 32-bit TGA.
"""

import argparse
import numpy as np

SIZE = 128
SUPERSAMPLE = 8

TILE_CORNER = 24.0
SLOT_MARGIN = 3.0
SLOT_CORNER = 17.0
SLOT_FRAME = 5.0
DISC_RADIUS = 42.0
DISC_OUTLINE = 1.7
CENTRE_SOFT = 11.0    # the sweep fades to its average colour inside this radius

TILE = np.array([23, 17, 10]) / 255
OUTLINE = np.array([16, 11, 6]) / 255
FRAME_LIGHT = np.array([182, 147, 92]) / 255
FRAME_DARK = np.array([101, 71, 37]) / 255
FILL_LIGHT = np.array([72, 59, 37]) / 255
FILL_DARK = np.array([38, 27, 12]) / 255

# The angle gradient: degrees clockwise from 12 o'clock -> colour.
SWEEP = [
    (0, (224, 185, 83)), (20, (210, 179, 74)), (40, (189, 169, 63)),
    (60, (170, 160, 55)), (80, (151, 153, 49)), (100, (130, 139, 44)),
    (120, (115, 134, 42)), (140, (101, 126, 41)), (160, (96, 131, 47)),
    (180, (93, 138, 53)), (200, (86, 140, 59)), (220, (82, 147, 68)),
    (240, (79, 152, 79)), (260, (80, 158, 92)), (280, (86, 165, 107)),
    (300, (94, 171, 121)), (320, (102, 176, 133)), (340, (92, 171, 135)),
    (360, (88, 168, 138)),
]


def smooth_sweep(degrees):
    """The sampled colours, run through a Gaussian along the angle so the
    straight segments between samples leave no visible kinks. The ends are
    held (not wrapped) so the seam at 12 o'clock stays crisp."""
    fine = np.linspace(0, 360, 721)
    stops = np.array([s[0] for s in SWEEP], float)
    colours = np.array([s[1] for s in SWEEP], float) / 255
    kernel = np.exp(-0.5 * (np.arange(-30, 31) / 12.0) ** 2)
    kernel /= kernel.sum()
    channels = []
    for c in range(3):
        line = np.interp(fine, stops, colours[:, c])
        padded = np.concatenate([np.full(30, line[0]), line, np.full(30, line[-1])])
        channels.append(np.convolve(padded, kernel, mode="valid"))
    return np.dstack([np.interp(degrees, fine, ch) for ch in channels])


def blob(x, y, cx, cy, radius):
    """A soft round glow, 1 at its centre and fading smoothly to 0."""
    return np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * radius ** 2))


def rounded_distance(x, y, half, corner):
    """Signed distance to a rounded square: negative inside."""
    qx = np.abs(x) - (half - corner)
    qy = np.abs(y) - (half - corner)
    return (np.hypot(np.maximum(qx, 0), np.maximum(qy, 0))
            + np.minimum(np.maximum(qx, qy), 0) - corner)


def lerp(a, b, t):
    return a[None, None, :] * (1 - t[..., None]) + b[None, None, :] * t[..., None]


def render():
    n = SIZE * SUPERSAMPLE
    ys, xs = np.mgrid[0:n, 0:n]
    x = (xs - (n - 1) / 2) / SUPERSAMPLE
    y = (ys - (n - 1) / 2) / SUPERSAMPLE
    half = SIZE / 2

    tile = rounded_distance(x, y, half, TILE_CORNER) <= 0
    slot_half = half - SLOT_MARGIN
    d = rounded_distance(x, y, slot_half, SLOT_CORNER)

    # Light falls from the top, a little from the left.
    shade = np.clip(0.5 + 0.5 * (0.75 * y + 0.25 * x) / slot_half, 0, 1)
    fill = lerp(FILL_LIGHT, FILL_DARK, shade)
    frame = lerp(FRAME_LIGHT, FRAME_DARK, shade)

    rgb = np.broadcast_to(TILE, (n, n, 3)).copy()
    rgb = np.where((d <= 0)[..., None], fill, rgb)
    rgb = np.where(((d <= 0) & (d > -SLOT_FRAME))[..., None], frame, rgb)

    # The pearl: the angle gradient underneath, a pearl finish on top.
    r = np.hypot(x, y)
    degrees = (np.degrees(np.arctan2(x, -y)) + 360) % 360
    sweep = smooth_sweep(degrees)

    # Every angle meets at the centre, so the sweep pinches into a knot there.
    # Fade to the sweep's average colour over a few pixels so it never has to
    # resolve to a point.
    average = smooth_sweep(np.linspace(0, 360, 361)).mean(axis=1)[0]
    centre = np.clip(r / CENTRE_SOFT, 0, 1)
    centre = (centre * centre * (3 - 2 * centre))[..., None]
    sweep = average[None, None, :] * (1 - centre) + sweep * centre

    # Soft shadow on the slot, down and to the right of the pearl.
    shadow_r = np.hypot(x - 1.6, y - 3.2)
    shadow = 0.55 * np.clip(1 - (shadow_r - DISC_RADIUS) / 5.5, 0, 1) ** 1.8
    rgb = np.where((d <= 0)[..., None], rgb * (1 - shadow[..., None]), rgb)

    rgb = np.where(((r > DISC_RADIUS) & (r <= DISC_RADIUS + DISC_OUTLINE))[..., None], OUTLINE, rgb)

    nr = np.clip(r / DISC_RADIUS, 0, 1)
    dome = 1 - 0.11 * nr ** 2.2 * np.clip(0.5 + 0.5 * (x + y) / DISC_RADIUS, 0, 1)
    pearl = sweep * dome[..., None]
    luster = blob(x, y, -14.0, -16.0, 15.0)[..., None] * 0.20      # broad soft sheen
    hot = blob(x, y, -15.5, -17.5, 4.2)[..., None] * 0.50          # small bright spot
    sheen = np.array([1.0, 0.95, 0.97])
    pearl = pearl * (1 - luster) + sheen * luster
    pearl = pearl * (1 - hot) + np.ones(3) * hot

    # A film of colour near the rim: faint pink on the lit side, aqua opposite.
    film = np.clip((nr - 0.62) / 0.38, 0, 1)[..., None] ** 1.5
    lit = np.clip(-(x + y) / (DISC_RADIUS * 1.4), -1, 1)[..., None]
    tint = np.where(lit > 0, np.array([1.0, 0.74, 0.86]), np.array([0.62, 0.95, 1.0]))
    pearl = pearl * (1 - 0.13 * film) + tint * 0.13 * film
    rgb = np.where((r <= DISC_RADIUS)[..., None], np.clip(pearl, 0, 1), rgb)

    alpha = tile.astype(float)
    pm = np.dstack([rgb * alpha[..., None], alpha])
    small = pm.reshape(SIZE, SUPERSAMPLE, SIZE, SUPERSAMPLE, 4).mean(axis=(1, 3))
    a = small[..., 3]
    out_rgb = np.where(a[..., None] > 1e-6, small[..., :3] / np.maximum(a[..., None], 1e-6), 0)
    return (np.clip(np.dstack([out_rgb, a]), 0, 1) * 255 + 0.5).astype(np.uint8)


def write_tga(path, rgba):
    header = bytes([0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    SIZE & 255, SIZE >> 8, SIZE & 255, SIZE >> 8, 32, 0x08])
    rows = []
    for y in range(SIZE - 1, -1, -1):               # bottom-left origin
        row = bytearray()
        for px in rgba[y]:
            row += bytes((int(px[2]), int(px[1]), int(px[0]), int(px[3])))
        rows.append(bytes(row))
    with open(path, "wb") as handle:
        handle.write(header + b"".join(rows))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default="textures/icon.tga")
    args = parser.parse_args()
    write_tga(args.out, render())
    print("wrote", args.out)


if __name__ == "__main__":
    main()
