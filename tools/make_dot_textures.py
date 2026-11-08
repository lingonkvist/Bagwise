#!/usr/bin/env python3
"""Render the verdict dot textures (textures/dot_green.tga, dot_yellow.tga),
the shadowless tooltip pearls (pearl_green.tga, pearl_yellow.tga) and
the border glow (textures/glow.tga).

Each dot is a lit sphere (soft body shading, a broad glossy sheen and a small
hot spot, a little bounce light low on the far side) sitting in a soft
drop shadow. The colour is baked in: a white highlight can't survive a
vertex-colour tint, which only multiplies.

Usage: python3 tools/make_dot_textures.py [--out textures]
Needs Pillow-free numpy only for the maths; writes plain 32-bit TGA files.
"""

import argparse
import numpy as np

SIZE = 64            # texture is 64x64
SUPERSAMPLE = 6
DISC_RADIUS = 25.0   # in texture pixels; the rest of the frame is shadow
SHADOW_FADE = 4.1     # the shadow fades to nothing over this distance, always inside the frame
SHADOW_STRENGTH = 0.88
SHADOW_OFFSET = (2.7, 4.4)   # shadow sits down and to the right, like the digits
DISC_CENTER = (0.0, -3.0)    # disc sits high in the frame so it hugs the slot corner

# Verdict colours (keep in step with VERDICT_COLORS in src/tooltip.lua).
COLORS = {
    "green": (0.33, 0.87, 0.49),
    "yellow": (0.97, 0.82, 0.16),
}
PEARL_SHEEN = np.array([1.0, 0.96, 0.98])   # faint warm-pink white
RING_WIDTH = 4.6     # near-black outline, about 1 px on screen at the 13 px dot size
RING_COLOR = np.array([0.03, 0.02, 0.02])
BEVEL_WIDTH = 6.0    # soft emboss just inside the ring: bright toward the light, dim away from it
BEVEL_LIGHT = 0.42
BEVEL_SHADE = 0.22


def normalize(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def render(color, shadow_on=True, center=DISC_CENTER):
    n = SIZE * SUPERSAMPLE
    ys, xs = np.mgrid[0:n, 0:n]
    cx = cy = (n - 1) / 2
    fx = (xs - cx) / SUPERSAMPLE
    fy = (ys - cy) / SUPERSAMPLE
    x = fx - center[0]
    y = fy - center[1]
    r = np.hypot(x, y)

    inside = r <= DISC_RADIUS
    nx, ny = x / DISC_RADIUS, y / DISC_RADIUS
    nz = np.sqrt(np.clip(1 - nx * nx - ny * ny, 0, 1))

    light = normalize((-0.5, -0.62, 0.62))
    diffuse = np.clip(nx * light[0] + ny * light[1] + nz * light[2], 0, 1)

    base = np.array(color)
    body = base[None, None, :] * (0.55 + 0.45 * diffuse)[..., None]

    # Bounce light: a faint lift low on the side away from the light.
    away = np.clip(-(nx * light[0] + ny * light[1]) / np.maximum(np.hypot(light[0], light[1]), 1e-6), 0, 1)
    rim = (1 - nz) ** 2
    body += (base * 0.22)[None, None, :] * (away * rim)[..., None]

    # Pearl sheen: a soft broad glow, drifting toward a pale pink-white.
    half = normalize(light + np.array([0, 0, 1.0]))
    nh = np.clip(nx * half[0] + ny * half[1] + nz * half[2], 0, 1)
    broad = (nh ** 8) * 0.55
    hot = (nh ** 90) * 0.95
    body = body * (1 - broad[..., None]) + PEARL_SHEEN[None, None, :] * broad[..., None]
    body = body * (1 - hot[..., None]) + np.ones(3)[None, None, :] * hot[..., None]

    # Bevel: a narrow band just inside the ring, lit from the same side as the
    # sphere, so the edge reads as a rounded pearl rather than a flat sticker.
    inner = DISC_RADIUS - RING_WIDTH
    band = np.clip((r - (inner - BEVEL_WIDTH)) / BEVEL_WIDTH, 0, 1)
    band = np.sin(band * np.pi / 2) * np.clip((inner - r) / 1.2 + 1, 0, 1)
    facing = -(nx * light[0] + ny * light[1]) / np.maximum(np.hypot(light[0], light[1]), 1e-6)
    lit = np.clip(facing, 0, 1) * band
    dim = np.clip(-facing, 0, 1) * band
    body = body * (1 - BEVEL_SHADE * dim[..., None])
    body = body * (1 - BEVEL_LIGHT * lit[..., None]) + PEARL_SHEEN[None, None, :] * (BEVEL_LIGHT * lit[..., None])

    # The outline: near-black, so the dot stands out on any icon.
    ring = np.clip((r - inner) / 1.0, 0, 1)
    body = body * (1 - ring[..., None]) + RING_COLOR[None, None, :] * ring[..., None]
    body = np.clip(body, 0, 1)

    # Drop shadow: solid under the disc, then a short fade, offset down and
    # right. It must reach zero before the frame edge so nothing is clipped.
    sr = np.hypot(x - SHADOW_OFFSET[0], y - SHADOW_OFFSET[1])
    tail = np.clip(1 - (sr - DISC_RADIUS) / SHADOW_FADE, 0, 1) ** 1.6
    shadow = SHADOW_STRENGTH * np.where(sr <= DISC_RADIUS, 1.0, tail)
    if not shadow_on:
        shadow = np.zeros_like(shadow)

    shadow_rgb = np.array([0.04, 0.025, 0.015])
    alpha = np.where(inside, 1.0, shadow)
    rgb = np.where(inside[..., None], body, shadow_rgb[None, None, :])

    # Downsample with premultiplied alpha so edges don't pick up fringes.
    pm = np.dstack([rgb * alpha[..., None], alpha])
    small = pm.reshape(SIZE, SUPERSAMPLE, SIZE, SUPERSAMPLE, 4).mean(axis=(1, 3))
    a = small[..., 3]
    out_rgb = np.where(a[..., None] > 1e-6, small[..., :3] / np.maximum(a[..., None], 1e-6), 0)
    return (np.clip(np.dstack([out_rgb, a]), 0, 1) * 255 + 0.5).astype(np.uint8)


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


def write_tga(path, rgba):
    header = bytes.fromhex("000002000000000000000000400040002008")  # 64x64, 32-bit, alpha
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
    parser.add_argument("--out", default="textures")
    args = parser.parse_args()
    for name, color in COLORS.items():
        path = f"{args.out}/dot_{name}.tga"
        write_tga(path, render(color))
        print("wrote", path)
        # The tooltip's inline copy: no shadow and dead centre in its frame, so
        # it sits level with the text instead of riding high.
        path = f"{args.out}/pearl_{name}.tga"
        write_tga(path, render(color, shadow_on=False, center=(0.0, 0.0)))
        print("wrote", path)
    write_tga(f"{args.out}/glow.tga", render_glow())
    print("wrote", f"{args.out}/glow.tga")


if __name__ == "__main__":
    main()
