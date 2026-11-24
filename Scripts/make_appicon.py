#!/usr/bin/env python3
"""
GlassTube app icon generator.

Draws the 1024x1024 iOS app icon entirely in code — no binary assets are
committed to the repository. Design: deep plum gradient, radial red glow,
top glass gloss, soft-diagonal light streak and a white play glyph.

Usage:
    python3 Scripts/make_appicon.py

Writes:
    GlassTube/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png
"""

import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

SIZE = 1024

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(
    os.path.join(
        HERE,
        "..",
        "GlassTube",
        "Assets.xcassets",
        "AppIcon.appiconset",
        "AppIcon1024.png",
    )
)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main():
    # 1. Vertical background gradient: deep plum -> near black.
    top, bottom = (18, 11, 26), (8, 6, 14)
    img = Image.new("RGB", (SIZE, SIZE))
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        row = lerp(top, bottom, y / (SIZE - 1))
        draw.line([(0, y), (SIZE, y)], fill=row)

    # 2. Radial hero glow (red -> transparent) behind the glyph.
    mask = Image.radial_gradient("L").resize((int(SIZE * 1.5),) * 2, Image.BILINEAR)
    mask = ImageOps.invert(mask)  # bright center
    glow_color = Image.new("RGB", mask.size, (255, 59, 92))
    glow = Image.new("RGB", (SIZE, SIZE))
    glow.paste(
        glow_color,
        (int(SIZE * 0.5 - mask.width / 2), int(SIZE * 0.54 - mask.height / 2)),
        mask,
    )
    img = Image.blend(img, glow, 0.72)
    img = img.filter(ImageFilter.GaussianBlur(24))

    # 3. Warm secondary glow, bottom-left.
    mask2 = Image.radial_gradient("L").resize((int(SIZE * 1.1),) * 2, Image.BILINEAR)
    mask2 = ImageOps.invert(mask2).point(lambda v: int(v * 0.45))
    warm = Image.new("RGB", mask2.size, (255, 122, 61))
    warm_layer = Image.new("RGB", (SIZE, SIZE))
    warm_layer.paste(warm, (int(SIZE * 0.22 - mask2.width / 2), int(SIZE * 0.85 - mask2.height / 2)), mask2)
    img = Image.blend(img, warm_layer, 0.35)
    img = img.filter(ImageFilter.GaussianBlur(18))

    # 4. Diagonal light streak (glass reflection).
    streak = Image.new("L", (SIZE, SIZE), 0)
    sdraw = ImageDraw.Draw(streak)
    sdraw.polygon([(int(SIZE * 0.55), 0), (int(SIZE * 0.95), 0), (int(SIZE * 0.35), SIZE), (int(SIZE * 0.05), SIZE)], fill=42)
    streak = streak.filter(ImageFilter.GaussianBlur(60))
    white_layer = Image.new("RGB", (SIZE, SIZE), (255, 255, 255))
    img = Image.composite(white_layer, img, streak)

    # 5. Top gloss: fading white sheen over the upper 45%.
    gloss = Image.new("L", (SIZE, SIZE), 0)
    gdraw = ImageDraw.Draw(gloss)
    fade_height = int(SIZE * 0.45)
    for y in range(fade_height):
        gdraw.line([(0, y), (SIZE, y)], fill=int(64 * (1 - y / fade_height)))
    img = Image.composite(white_layer, img, gloss)

    # 6. Soft drop shadow under the play glyph.
    glyph_shadow = Image.new("L", (SIZE, SIZE), 0)
    gsdraw = ImageDraw.Draw(glyph_shadow)
    gsdraw.polygon(
        [(int(SIZE * 0.36), int(SIZE * 0.25)), (int(SIZE * 0.79), int(SIZE * 0.5)), (int(SIZE * 0.36), int(SIZE * 0.75))],
        fill=110,
    )
    glyph_shadow = glyph_shadow.filter(ImageFilter.GaussianBlur(28))
    black_layer = Image.new("RGB", (SIZE, SIZE), (10, 4, 8))
    img = Image.composite(black_layer, img, ImageChops.offset(glyph_shadow, 0, 14))

    # 7. White play glyph with a subtle vertical gradient tint.
    glyph_mask = Image.new("L", (SIZE, SIZE), 0)
    mdraw = ImageDraw.Draw(glyph_mask)
    mdraw.polygon(
        [(int(SIZE * 0.36), int(SIZE * 0.24)), (int(SIZE * 0.82), int(SIZE * 0.5)), (int(SIZE * 0.36), int(SIZE * 0.76))],
        fill=255,
    )
    glyph_fill = Image.new("RGB", (SIZE, SIZE))
    gtop, gbottom = (255, 255, 255), (255, 231, 236)
    gdr = ImageDraw.Draw(glyph_fill)
    for y in range(SIZE):
        gdr.line([(0, y), (SIZE, y)], fill=lerp(gtop, gbottom, y / (SIZE - 1)))
    img.paste(glyph_fill, (0, 0), glyph_mask)

    # 8. Save (opaque square — iOS applies its own corner mask).
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, "PNG")
    print(f"App icon written: {OUT} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()
