#!/usr/bin/env python3
"""Generate TopCal app icon: PNG (1024) + .icns via iconset."""
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024

# Candidate bold fonts (macOS)
FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Helvetica Bold.ttc",
    "/System/Library/Fonts/Supplemental/Menlo.ttc",
    "/System/Library/Fonts/Supplemental/SFNS.ttf",
]


def find_font():
    for f in FONT_CANDIDATES:
        if os.path.exists(f):
            return f
    raise SystemExit("No usable bold font found")


def lerp(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def rounded_gradient(size, radius, top_color, bottom_color):
    """Vertical gradient clipped to a rounded rect."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(grad)
    for y in range(size):
        d.line([(0, y), (size, y)], fill=lerp(top_color, bottom_color, y / size))
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    img.paste(grad, (0, 0), mask)
    return img


def main():
    font_path = find_font()
    print(f"Using font: {font_path}")

    # ---- Base: red rounded square with subtle vertical gradient ----
    top = (255, 84, 94)     # #FF545E
    bottom = (215, 4, 41)   # #D70429
    radius = int(SIZE * 0.22)  # ~225
    img = rounded_gradient(SIZE, radius, top, bottom)
    d = ImageDraw.Draw(img)

    # ---- White menu-bar strip (suggests "top bar") ----
    strip_y0, strip_y1 = int(SIZE * 0.17), int(SIZE * 0.28)
    strip_margin = int(SIZE * 0.16)
    d.rounded_rectangle(
        [strip_margin, strip_y0, SIZE - strip_margin, strip_y1],
        radius=int(SIZE * 0.055), fill=(255, 255, 255, 255),
    )

    # ---- Small accent dot on the strip (like a status item) ----
    dot_r = int(SIZE * 0.018)
    dot_cx = int(SIZE * 0.5)
    dot_cy = (strip_y0 + strip_y1) // 2
    d.ellipse([dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
              fill=(255, 84, 94, 255))

    # ---- Big date number "25" ----
    font = ImageFont.truetype(font_path, int(SIZE * 0.42))
    text = "25"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (SIZE - tw) / 2 - bbox[0]
    ty = int(SIZE * 0.56) - bbox[1]
    d.text((tx, ty), text, font=font, fill=(255, 255, 255, 255))

    # ---- Outputs ----
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    png_path = os.path.join(out_dir, "icon.png")
    img.save(png_path)
    print(f"Saved {png_path}")

    # iconset for iconutil
    iconset = os.path.join(out_dir, "AppIcon.iconset")
    os.makedirs(iconset, exist_ok=True)
    sizes = [(16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
             (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
             (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
             (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
             (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png")]
    for px, name in sizes:
        img.resize((px, px), Image.LANCZOS).save(os.path.join(iconset, name))

    icns_path = os.path.join(out_dir, "AppIcon.icns")
    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", icns_path], check=True)
    print(f"Saved {icns_path}")
    print("DONE")


if __name__ == "__main__":
    main()
