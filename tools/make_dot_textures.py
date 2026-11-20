#!/usr/bin/env python3
"""Render the verdict dot textures (textures/dot_green.tga, dot_yellow.tga),
the tooltip and menu markers (pearl_green.tga, pearl_yellow.tga) and the
border glow (textures/glow.tga).

The markers are the same painted dots as in the bag: green round, yellow a
rounded diamond, so the two verdicts differ in shape as well as colour and can
be told apart by someone who cannot tell the colours apart. The marker has no
drop shadow and sits in the middle of its frame, so it lines up with the text.
The colour is baked in: a white highlight can't survive a vertex-colour tint,
which only multiplies.

Usage: python3 tools/make_dot_textures.py [--out textures]
Needs Pillow-free numpy only for the maths; writes plain 32-bit TGA files.
"""

import argparse
import numpy as np

SIZE = 64            # texture is 64x64
SUPERSAMPLE = 6

# Bag dots are painted the way the game's own icons are: smooth shading from a lit upper
# left to a shaded lower right, a thin dark rim, a soft highlight. Each ramp shifts hue as it
# goes dark (lit side toward yellow, shade toward blue), as painted icons do.
DOT_COLORS = {
    "green": {
        "o": (0.01, 0.02, 0.01),   # rim: black
        "h": (0.38, 0.84, 0.4),   # light
        "b": (0.2, 0.78, 0.35),   # base: the green of a site's "unread" badge (iOS system green, #34C759)
        "s": (0.0, 0.69, 0.32),   # shade
        "w": (0.86, 0.98, 0.83),   # highlight
    },
    "yellow": {
        "o": (0.02, 0.01, 0.00),   # rim: black
        "h": (1.00, 0.89, 0.45),
        "b": (0.95, 0.72, 0.10),
        "s": (0.74, 0.45, 0.04),
        "w": (1.00, 0.98, 0.80),
    },
}
# Each verdict's shape: "disc" or "diamond" (rounded square turned 45 degrees).
SHAPES = {"green": "disc", "yellow": "diamond"}


GLOW_HALF_SIZE = 18.0   # half the slot, in texture pixels (frame = 64/36 = 1.78 x the slot)
GLOW_CORNER = 3.0       # corner radius of the slot edge
GLOW_OUTER = 5.5        # how far the glow spreads outside the slot edge
GLOW_INNER = 1.1        # how far it creeps inside, so the icon stays clear
GLOW_STRENGTH = 0.95


def render_glow():
    """A soft glowing border around a square slot, white so it can be tinted."""
    n = SIZE * SUPERSAMPLE
    ys, xs = np.mgrid[0:n, 0:n]
    x = np.abs((xs - (n - 1) / 2) / SUPERSAMPLE)
    y = np.abs((ys - (n - 1) / 2) / SUPERSAMPLE)
    # Signed distance to a rounded square: negative inside.
    qx = x - (GLOW_HALF_SIZE - GLOW_CORNER)
    qy = y - (GLOW_HALF_SIZE - GLOW_CORNER)
    outside = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0))
    inside = np.minimum(np.maximum(qx, qy), 0)
    dist = outside + inside - GLOW_CORNER
    alpha = np.where(dist >= 0,
                     np.exp(-dist / GLOW_OUTER * 1.6),
                     np.exp(dist / GLOW_INNER)) * GLOW_STRENGTH
    # Reach zero before the frame edge so nothing is clipped.
    edge = np.maximum(x, y)
    alpha *= np.clip((31.0 - edge) / 7.0, 0, 1) ** 1.5
    small = alpha.reshape(SIZE, SUPERSAMPLE, SIZE, SUPERSAMPLE).mean(axis=(1, 3))
    a = (np.clip(small, 0, 1) * 255 + 0.5).astype(np.uint8)
    rgba = np.zeros((SIZE, SIZE, 4), np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = a
    return rgba


# ---------------------------------------------------------------------------
# The verdict dots in the bag. They are drawn at 32 x 32, not 64: the game shows
# them about 14 px wide, so a 32 px texture is shrunk about 2x instead of 4.5x
# and keeps its edges. The body fills about 85% of the frame (a 1 px shadow is
# all that is baked in), and the highlight is a crisp speck, not a broad sheen.
# ---------------------------------------------------------------------------
DOT_TEXTURE = 32            # shown at 16 px: exactly 2 to 1, so the game's bilinear filter is a clean box average
DOT_SUPERSAMPLE = 8
DOT_CENTERS = {"disc": 15.0, "diamond": 16.0}   # body centre per shape; the diamond's tips reach further, so it sits in the middle of the texture
DOT_DISC_RADIUS = 12.5      # 12.5 px across on screen: a circle weighs more than a diamond of the same width
DOT_DIAMOND_HALF = 14.5     # tip to centre before rounding; any more and the tips touch the texture edge
DOT_DIAMOND_ROUNDING = 1.5  # about 14 px across on screen
DOT_RIM = 3.0               # black rim, texture pixels: 1.5 px on screen
DOT_HIGHLIGHT = (-0.36, -0.40, 0.20, 0.50)    # x and y offset as fractions of the radius, softness, strength
DOT_SHADOW_OFFSET = (1.2, 1.8)   # the drop shadow falls to the lower right
DOT_SHADOW_BLUR = 1.7
DOT_SHADOW_STRENGTH = 0.7        # light: the dot sits on the slot's corner, mostly over its frame and the dark bag, so it needs little
DOT_HALO_BLUR = 1.1              # a tighter dark halo all round, so the dot never melts into the icon
DOT_HALO_STRENGTH = 0.35
DOT_SPOT_SCALE = 0.3             # the soft highlight spot is only a hint now; the edge shine does the work
DOT_SHINE_WIDTH = 4.2            # soft part of the edge shine, texture pixels inward from the rim
DOT_SHINE_LINE = 0.95            # strength of the crisp specular line just inside the rim
DOT_SHINE_SOFT = 0.45            # strength of the soft band behind it


def gaussian_blur(a, sigma):
    """Separable gaussian blur with numpy only."""
    radius = int(sigma * 3) + 1
    k = np.exp(-0.5 * (np.arange(-radius, radius + 1) / sigma) ** 2)
    k /= k.sum()
    for axis in (0, 1):
        padded = np.pad(a, [(radius, radius) if i == axis else (0, 0) for i in range(a.ndim)], mode="edge")
        a = sum(k[i] * np.take(padded, range(i, i + a.shape[axis]), axis=axis) for i in range(len(k)))
    return a


def gradient_color(ramp, u):
    """Colour along the light direction: u = -1 is the lit edge, 0 the base, +1 the shaded edge."""
    u = np.clip(u, -1, 1)[..., None]
    light, base, shade = (np.array(ramp[k]) for k in "hbs")
    lit_side = base + (light - base) * np.clip(-u / 0.9, 0, 1)
    shaded_side = base + (shade - base) * np.clip(u / 0.9, 0, 1)
    return np.where(u < 0, lit_side, shaded_side)


# The markers in the tooltip and the menu are the same dots with no shadow, in the middle of the
# frame, the same size as the dot in the bag.
MARKER_CENTER = 16.0
MARKER_DISC_RADIUS = 12.5
MARKER_DIAMOND_HALF = 14.5


def render_dot(ramp, shape, marker=False):
    """The verdict dot, painted: smooth shading, thin rim, soft highlight, soft shadow.

    marker=True draws the version for the tooltip and the menu: no shadow, centred, larger.
    """
    ss = DOT_SUPERSAMPLE
    n = DOT_TEXTURE * ss
    ys, xs = np.mgrid[0:n, 0:n].astype(np.float32)
    center = MARKER_CENTER if marker else DOT_CENTERS[shape]
    x, y = xs / ss - center, ys / ss - center
    if shape == "disc":
        radius = MARKER_DISC_RADIUS if marker else DOT_DISC_RADIUS
        dist = np.hypot(x, y) - radius
    else:
        radius = MARKER_DIAMOND_HALF if marker else DOT_DIAMOND_HALF
        h = radius - DOT_DIAMOND_ROUNDING
        dist = (np.abs(x) + np.abs(y)) / np.sqrt(2) - h / np.sqrt(2) - DOT_DIAMOND_ROUNDING
    inside = (dist <= 0).astype(np.float32)
    body = (dist <= -DOT_RIM).astype(np.float32)
    rim = inside - body

    u = (x + y) / (np.sqrt(2) * radius)                       # -1 upper left, +1 lower right
    rgb = gradient_color(ramp, u * 1.25)
    hx, hy, soft, strength = DOT_HIGHLIGHT
    spot = np.exp(-((x - hx * radius) ** 2 + (y - hy * radius) ** 2) / (2 * (soft * radius) ** 2))
    rgb = rgb + (np.array(ramp["w"]) - rgb) * (strength * DOT_SPOT_SCALE * spot)[..., None]

    # Edge shine: a bright line just inside the rim, strongest where the edge faces the upper left.
    gy, gx = np.gradient(dist)
    facing = np.clip((gx * -0.7071 + gy * -0.7071) / np.maximum(np.hypot(gx, gy), 1e-6), 0, 1)
    arc = np.clip((facing - 0.1) / 0.9, 0, 1) ** 1.1
    depth = -(dist + DOT_RIM)                                 # 0 at the rim, grows inward
    onset = np.clip(depth / 0.3, 0, 1)
    line = onset * np.clip(1 - (depth - 1.4) / 0.8, 0, 1)
    soft_band = onset * np.clip(1 - (depth - 0.4) / DOT_SHINE_WIDTH, 0, 1)
    shine = arc * np.clip(DOT_SHINE_LINE * line + DOT_SHINE_SOFT * soft_band, 0, 1) * body
    rgb = rgb + (np.array(ramp["w"]) - rgb) * shine[..., None]
    rgb = rgb * body[..., None] + np.array(ramp["o"])[None, None, :] * rim[..., None]

    shadow = gaussian_blur(inside, DOT_SHADOW_BLUR * ss)
    shadow = np.roll(np.roll(shadow, int(DOT_SHADOW_OFFSET[1] * ss), axis=0), int(DOT_SHADOW_OFFSET[0] * ss), axis=1)
    halo = gaussian_blur(inside, DOT_HALO_BLUR * ss)
    backdrop = np.maximum(np.clip(shadow * DOT_SHADOW_STRENGTH, 0, 0.9), np.clip(halo * 1.8, 0, 1) * DOT_HALO_STRENGTH)
    alpha = inside if marker else np.clip(inside + backdrop * (1 - inside), 0, 1)
    pm = np.dstack([rgb * inside[..., None], alpha])
    small = pm.reshape(DOT_TEXTURE, ss, DOT_TEXTURE, ss, 4).mean(axis=(1, 3))
    a = small[..., 3]
    out_rgb = np.where(a[..., None] > 1e-6, small[..., :3] / np.maximum(a[..., None], 1e-6), 0)
    return (np.clip(np.dstack([out_rgb, a]), 0, 1) * 255 + 0.5).astype(np.uint8)


def write_tga(path, rgba):
    size = rgba.shape[0]
    # 32-bit uncompressed, alpha, bottom-left origin; the size is little-endian twice.
    header = bytes.fromhex("000002000000000000000000") + size.to_bytes(2, "little") * 2 + bytes.fromhex("2008")
    rows = []
    for y in range(size - 1, -1, -1):               # bottom-left origin
        row = bytearray()
        for px in rgba[y]:
            row += bytes((int(px[2]), int(px[1]), int(px[0]), int(px[3])))
        rows.append(bytes(row))
    with open(path, "wb") as handle:
        handle.write(header + b"".join(rows))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default="textures")
    args = parser.parse_args()
    for name, ramp in DOT_COLORS.items():
        path = f"{args.out}/dot_{name}.tga"
        write_tga(path, render_dot(ramp, SHAPES[name]))
        print("wrote", path)
        # The tooltip's and the menu's marker: the same dot, no shadow, in the middle of its frame.
        path = f"{args.out}/pearl_{name}.tga"
        write_tga(path, render_dot(ramp, SHAPES[name], marker=True))
        print("wrote", path)
    write_tga(f"{args.out}/glow.tga", render_glow())
    print("wrote", f"{args.out}/glow.tga")


if __name__ == "__main__":
    main()
