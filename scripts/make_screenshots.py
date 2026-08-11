#!/usr/bin/env python3
"""Compose the menu-bar screenshot for each locale.

Reads the real AppKit-rendered menu-bar icon from docs/<locale>/menubar-icon.png
(produced by scripts/render/build.sh) and embeds it into a synthetic menu bar
strip alongside the clock. Produces docs/<locale>/screenshot-menu.png.

The popover screenshot is fully real (also from scripts/render/build.sh); only
the menu bar background is synthesised here because NSStatusBar requires a real
macOS GUI session.

Usage: make_screenshots.py [locale ...]  (default: en zh-Hans)
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

FONT_CN = "/System/Library/Fonts/STHeiti Medium.ttc"
FONT_ARIAL_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

LOCALES = {
    "en": ["File", "Edit", "View", "Window", "Help"],
    "zh-Hans": ["文件", "编辑", "显示", "窗口", "帮助"],
}


def font(path, size):
    return ImageFont.truetype(path, size)


def text_left(draw, x, cy, s, fnt, fill):
    bbox = draw.textbbox((0, 0), s, font=fnt)
    h = bbox[3] - bbox[1]
    draw.text((x - bbox[0], cy - h / 2 - bbox[1]), s, font=fnt, fill=fill)


def gradient(w, h, top, bottom):
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def draw_menu_bar(img, draw, x0, y0, x1, y1, locale, icon_img):
    h = y1 - y0
    draw.rectangle([x0, y0, x1, y1], fill=(38, 38, 42, 235))
    draw.line([x0, y1 - 1, x1, y1 - 1], fill=(0, 0, 0, 40))

    text_color = (255, 255, 255, 255)
    dim_color = (255, 255, 255, 150)
    cy = (y0 + y1) / 2

    f_app = font(FONT_CN, int(h * 0.42))
    f_menu = font(FONT_CN, int(h * 0.32))
    text_left(draw, x0 + 18, cy, "TopCal", f_app, text_color)

    menus = LOCALES.get(locale, LOCALES["en"])
    menu_x = x0 + 96
    menu_ends = []
    for m in menus:
        text_left(draw, menu_x, cy, m, f_menu, dim_color)
        w = draw.textbbox((0, 0), m, font=f_menu)[2]
        menu_ends.append(menu_x + w)
        menu_x += w + 12
    menu_last_x = menu_ends[-1] if menu_ends else x0

    # Clock on the far right
    f_clock = font(FONT_ARIAL_BOLD, int(h * 0.42))
    clock_text = "12:00"
    clock_w = draw.textbbox((0, 0), clock_text, font=f_clock)[2]
    clock_x = x1 - 16 - clock_w
    text_left(draw, clock_x, cy, clock_text, f_clock, text_color)

    # TopCal icon — placed between menus and clock, vertically centered
    icon_target_h = int(h * 0.62)
    scale = icon_target_h / icon_img.size[1]
    icon_w = int(icon_img.size[0] * scale)
    icon_h = icon_target_h
    icon_left = max(menu_last_x + 14, clock_x - icon_w - 12)
    icon_resized = icon_img.resize((icon_w, icon_h), Image.LANCZOS)
    img.paste(icon_resized, (icon_left, int(cy - icon_h / 2)), icon_resized)


def main():
    locales = sys.argv[1:] if len(sys.argv) > 1 else ["en", "zh-Hans"]
    base = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.abspath(os.path.join(base, ".."))

    for locale in locales:
        out_dir = os.path.join(repo, "docs", locale)
        os.makedirs(out_dir, exist_ok=True)
        icon_path = os.path.join(out_dir, "menubar-icon.png")
        if not os.path.exists(icon_path):
            print(f"missing {icon_path}; run scripts/render/build.sh first")
            continue
        icon = Image.open(icon_path).convert("RGBA")

        img = Image.new("RGBA", (640, 100), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        img.alpha_composite(gradient(640, 40, (122, 133, 255), (74, 114, 255)), (0, 60))
        draw_menu_bar(img, d, 0, 0, 640, 60, locale, icon)
        out = os.path.join(out_dir, "screenshot-menu.png")
        img.convert("RGB").save(out)
        print("saved", out)


if __name__ == "__main__":
    main()