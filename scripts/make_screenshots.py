#!/usr/bin/env python3
"""Generate per-locale UI screenshots for the READMEs.

For each locale it produces two images:
  docs/<locale>/screenshot-menu.png     — menu bar close-up with the TopCal pill
  docs/<locale>/screenshot-popover.png  — desktop + menu bar + calendar popover

The popover screenshots show August 2026. In Chinese locales each cell also
shows the lunar date (from a JSON map produced by a small Swift helper using
Calendar(identifier: .chinese)); other locales show the plain Gregorian grid.

Usage: make_screenshots.py [lunar_map.json] [locale ...]
  lunar_map.json   JSON mapping "YYYY-MM-DD" -> lunar label (default: /tmp/lunar_map.json)
  locale           en, zh-Hans, ... (default: en zh-Hans)
"""
import json
import os
import sys
from datetime import date, timedelta

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT_CN = "/System/Library/Fonts/STHeiti Medium.ttc"
FONT_ARIAL_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

# Per-locale rendering config ---------------------------------------------
LOCALES = {
    "en": {
        "dir": "en",
        "menus": ["File", "Edit", "View", "Window", "Help"],
        "weekdays": ["S", "M", "T", "W", "T", "F", "S"],
        "month_title": "August 2026",
        "show_lunar": False,
    },
    "zh-Hans": {
        "dir": "zh-Hans",
        "menus": ["文件", "编辑", "显示", "窗口", "帮助"],
        "weekdays": ["日", "一", "二", "三", "四", "五", "六"],
        "month_title": "2026年8月",
        "show_lunar": True,
    },
}


def font(path, size):
    return ImageFont.truetype(path, size)


# ---------------------------------------------------------------- helpers

def rounded(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def text_center(draw, cx, cy, s, fnt, fill):
    bbox = draw.textbbox((0, 0), s, font=fnt)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    draw.text((cx - w / 2 - bbox[0], cy - h / 2 - bbox[1]), s, font=fnt, fill=fill)


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


# ---------------------------------------------------------------- menu bar

def draw_menu_bar(draw, x0, y0, x1, y1, cfg, with_clock=True):
    """Draws a macOS-style menu bar with the TopCal red pill on the right."""
    h = y1 - y0
    draw.rectangle([x0, y0, x1, y1], fill=(38, 38, 42, 235))
    draw.line([x0, y1 - 1, x1, y1 - 1], fill=(0, 0, 0, 40))

    text_color = (255, 255, 255, 255)
    dim_color = (255, 255, 255, 150)
    accent = (255, 84, 94, 255)  # TopCal red

    # app name + menus (left)
    f_app = font(FONT_CN, int(h * 0.42))
    f_menu = font(FONT_CN, int(h * 0.36))
    cy = (y0 + y1) / 2
    text_left(draw, x0 + 18, cy, "TopCal", f_app, text_color)
    x = x0 + 110
    for m in cfg["menus"]:
        text_left(draw, x, cy, m, f_menu, dim_color)
        x += 78

    # right-side items (right to left)
    rx = x1 - 16
    # TopCal pill
    pill_w, pill_h = int(h * 1.15), int(h * 0.62)
    rx -= pill_w
    rounded(draw, [rx, cy - pill_h / 2, rx + pill_w, cy + pill_h / 2],
            pill_h / 2, accent)
    text_center(draw, rx + pill_w / 2, cy, "25", font(FONT_ARIAL_BOLD, int(h * 0.44)),
                (255, 255, 255, 255))
    rx -= 18

    if with_clock:
        f_clock = font(FONT_ARIAL_BOLD, int(h * 0.42))
        clock_s = "12:00"
        cw = draw.textbbox((0, 0), clock_s, font=f_clock)[2]
        rx -= cw
        text_left(draw, rx, cy, clock_s, f_clock, text_color)
        rx -= 14

    # battery
    bx = rx - int(h * 0.9)
    bh = int(h * 0.34)
    draw.rectangle([bx, cy - bh / 2, bx + int(h * 0.5), cy + bh / 2],
                   outline=dim_color, width=2)
    draw.rectangle([bx + int(h * 0.52), cy - bh / 4, bx + int(h * 0.6), cy + bh / 4],
                   fill=dim_color)
    draw.rectangle([bx + 3, cy - bh / 2 + 3, bx + int(h * 0.45), cy + bh / 2 - 3],
                   fill=dim_color)
    rx = bx - 16

    # wifi (three arcs, simplified as dots)
    for _, rr in enumerate([3, 8, 14]):
        cx = rx - rr - 14
        draw.arc([cx - rr, cy - rr, cx + rr, cy + rr], start=180, end=360,
                 fill=dim_color, width=3)
    rx -= 30

    # control center (two pills)
    rounded(draw, [rx - 26, cy - 10, rx + 26, cy + 10], 10, dim_color)
    draw.rectangle([rx - 8, cy - 5, rx + 8, cy + 5], fill=(0, 0, 0, 60))


# ---------------------------------------------------------------- popover

def draw_popover(img, draw, x0, y0, cfg, lunar_map, scale=2):
    W, H = 240 * scale, 300 * scale  # popover is 240x300 pt
    margin = 10 * scale
    accent = (10, 132, 255, 255)  # system blue for today
    text_main = (30, 30, 30, 255)
    text_weekday = (120, 120, 120, 255)
    text_adjacent = (190, 190, 190, 255)
    lunar_dim = (170, 170, 170, 255)
    lunar_adj = (215, 215, 215, 255)

    # shadow
    shadow = Image.new("RGBA", (W + 30 * scale, H + 30 * scale), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    rounded(sd, [0, 0, W + 30 * scale - 1, H + 30 * scale - 1], 22 * scale, (0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18 * scale))
    img.alpha_composite(shadow, (x0 - 15 * scale, y0 - 15 * scale))

    # white body
    rounded(draw, [x0, y0, x0 + W - 1, y0 + H - 1], 20 * scale, (255, 255, 255, 255))
    # arrow (pointing up)
    ax = x0 + W - 70 * scale
    draw.polygon([(ax - 12 * scale, y0 + 1), (ax + 12 * scale, y0 + 1), (ax, y0 - 12 * scale)],
                 fill=(255, 255, 255, 255))

    # ---- header ----
    hy = y0 + 26 * scale
    f_nav = font(FONT_CN, 13 * scale)
    f_title = font(FONT_CN, 13 * scale)
    text_left(draw, x0 + 22 * scale, hy, "◀", f_nav, (90, 90, 90, 255))
    text_center(draw, x0 + W / 2, hy, cfg["month_title"], f_title, text_main)
    text_left(draw, x0 + W - 40 * scale, hy, "▶", f_nav, (90, 90, 90, 255))

    # ---- weekday row ----
    wy = hy + 26 * scale
    f_week = font(FONT_CN, 10 * scale)
    col_w = (W - 2 * margin) / 7.0
    for i, wd in enumerate(cfg["weekdays"]):
        text_center(draw, x0 + margin + col_w * (i + 0.5), wy, wd, f_week, text_weekday)

    # ---- day grid ----
    grid_top = wy + 18 * scale
    cell_h = 34 * scale
    f_day = font(FONT_ARIAL_BOLD, 12 * scale)
    f_lunar = font(FONT_CN, 9 * scale)

    first = date(2026, 8, 1)
    first_col = 6  # Aug 1 2026 is Saturday (Sun=0)
    today = date(2026, 8, 11)

    for r in range(6):
        for c in range(7):
            idx = r * 7 + c
            day_offset = idx - first_col
            d = first + timedelta(days=day_offset)
            cx = x0 + margin + col_w * (c + 0.5)
            cy = grid_top + cell_h * (r + 0.5)

            is_current = d.month == 8
            is_today = d == today
            lunar = lunar_map.get(d.isoformat(), "") if cfg["show_lunar"] else ""

            day_color = (255, 255, 255, 255) if is_today else (
                text_main if is_current else text_adjacent)
            lunar_color = (255, 255, 255, 200) if is_today else (
                lunar_dim if is_current else lunar_adj)

            if is_today:
                r_px = 24 * scale
                rounded(draw,
                        [cx - r_px, cy - 14 * scale, cx + r_px, cy - 14 * scale + 2 * r_px],
                        r_px, accent)

            text_center(draw, cx, cy - 8 * scale, str(d.day), f_day, day_color)
            if lunar:
                text_center(draw, cx, cy + 10 * scale, lunar, f_lunar, lunar_color)


# ---------------------------------------------------------------- main

def main():
    lunar_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/lunar_map.json"
    locales = sys.argv[2:] if len(sys.argv) > 2 else ["en", "zh-Hans"]
    base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs")

    lunar_map = {}
    if os.path.exists(lunar_path):
        with open(lunar_path) as f:
            lunar_map = json.load(f)

    for locale in locales:
        cfg = LOCALES[locale]
        out_dir = os.path.join(base, cfg["dir"])
        os.makedirs(out_dir, exist_ok=True)

        # 1. menu bar close-up
        img1 = Image.new("RGBA", (640, 100), (0, 0, 0, 0))
        d1 = ImageDraw.Draw(img1)
        img1.alpha_composite(gradient(640, 40, (122, 133, 255), (74, 114, 255)), (0, 60))
        draw_menu_bar(d1, 0, 0, 640, 60, cfg, with_clock=False)
        p1 = os.path.join(out_dir, "screenshot-menu.png")
        img1.convert("RGB").save(p1)
        print("Saved", p1)

        # 2. desktop + popover
        W2, H2 = 720, 780
        img2 = Image.new("RGBA", (W2, H2))
        img2.alpha_composite(gradient(W2, H2, (92, 122, 255), (74, 74, 190)), (0, 0))
        d2 = ImageDraw.Draw(img2)
        draw_menu_bar(d2, 0, 0, W2, 48, cfg)
        draw_popover(img2, d2, W2 - 480 - 50, 66, cfg, lunar_map, scale=2)
        p2 = os.path.join(out_dir, "screenshot-popover.png")
        img2.convert("RGB").save(p2)
        print("Saved", p2)


if __name__ == "__main__":
    main()
