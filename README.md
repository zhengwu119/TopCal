# TopCal

<div align="center">
  <img src="icon.png" width="128" alt="TopCal icon">
</div>

🌐 **Languages:** 🇺🇸 [English](README.md) · 🇨🇳 [简体中文](README.zh-CN.md) · 🇯🇵 日本語 · 🇰🇷 한국어 · 🇩🇪 Deutsch · 🇫🇷 Français · 🇪🇸 Español &nbsp;_(translations welcome — see [CONTRIBUTING](#contributing))_

A minimal macOS menu bar calendar. Shows today's day-of-month in the menu bar; click it to view a popover calendar with month/year navigation.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange) ![License](https://img.shields.io/badge/License-MIT-green)

**TopCal** — a tiny calendar that lives in your menu bar. Click it, see the month, get back to work.

<p align="center">
  <img src="docs/en/screenshot-menu.png" width="640" alt="TopCal in the menu bar">
</p>

## Features

- 📅 Current day-of-month shown in the menu bar (e.g. `25`)
- 🗓 Click to open a popover calendar — current day is highlighted
- ◀ ▶ Month/year navigation inside the popover
- 🐉 Lunar (Chinese) calendar overlay is enabled by default: each cell shows
  the traditional `初一` … `三十` date and labels the first day of each lunar month
- 📌 Chinese public holidays and make-up workdays (enabled by default):
  a green dot marks every official holiday, a neutral dot marks the
  weekend workdays scheduled by the State Council (per the annual notice).
  Hover a marked day to see which holiday it is, e.g.
  `国庆节 · 放假` or `National Day · Make-up Workday`
- 🎉 **Special-festival hover tooltips**: hover any day that is a special
  festival to see its name and a one-line description — fixed Gregorian
  festivals (Valentine's Day, Women's Day, Arbor Day, April Fools' Day,
  Youth Day, Children's Day, Army Day, Teachers' Day, Halloween,
  Singles' Day, Christmas Eve, Christmas, New Year's Eve) and lunar
  festivals (Lantern Festival, Qixi, Dragon Boat, Mid-Autumn, Double
  Ninth, Laba Festival, Lunar New Year's Eve). Lunar dates are resolved
  with the system's `.chinese` calendar, so they stay correct every year
  without data updates; 除夕 is the day before lunar 1/1. On statutory
  holiday / make-up days the existing line is kept and the festival
  description is appended on a second line
- ◀ ▶ Monthly navigation + « » **year** navigation (SF Symbols chevrons)
- 🧮 **Day calculator**: two buttons in the toolbar below the grid —
  *Workdays* and *Days*. Pick any two cells in the popover to get the
  number of working days (excluding public holidays, including weekend
  make-up workdays) or total days in that range.
- ⚙️ **Settings menu** (gear icon, bottom-right):
  - **Language** — switch the in-app UI language (8 locales, persisted)
  - **Appearance** — Follow System / Light / Dark theme, applied instantly
  - **Launch at Login** — toggle (default on)
  - **Check for Updates** — compares with the latest GitHub release
  - **About** and **Quit**
- 🌍 Localized: English · Simplified Chinese · Traditional Chinese · Japanese · Korean · German · French · Spanish
- 🚀 Launch at login (via per-user LaunchAgent, no helper app required)
- 🔔 Optional launch notification to confirm the app is running
- ⚡ Native AppKit, no dependencies, no sandbox account needed

<p align="center">
  <img src="docs/en/screenshot-popover.png" width="540" alt="Calendar popover">
</p>

## Requirements

- macOS 13.0 or later (arm64 / x86_64)
- Xcode Command Line Tools (`xcode-select --install`) to build from source

## Installation

Download the latest `TopCal.app` from [Releases](../../releases) and drag it into your **Applications** folder, then launch it.

> First launch: the app registers itself as a login item and may ask for
> notification permission — these are optional and can be denied.

### macOS Gatekeeper / "Apple cannot check it for malicious software"

TopCal is **ad-hoc signed** (no paid Apple Developer ID), so macOS may block the
first launch. This is normal for free open-source apps. Remove the quarantine
flag in Terminal and it will open normally:

```bash
# 1. Move the app into /Applications first, then remove the quarantine flag
#    (sudo is needed because /Applications is not writable by regular users):
sudo xattr -dr com.apple.quarantine /Applications/TopCal.app
# 2. Launch it:
open /Applications/TopCal.app
```

## Build from Source

```bash
git clone https://github.com/zhengwu119/TopCal.git TopCal
cd TopCal
./build.sh
open build/TopCal.app
```

Or manually:

```bash
swiftc -o TopCal.app/Contents/MacOS/TopCal \
  -framework AppKit -framework Foundation -framework UserNotifications \
  $(find Sources -name "*.swift" | sort)
cp Info.plist TopCal.app/Contents/Info.plist
cp AppIcon.icns TopCal.app/Contents/Resources/AppIcon.icns
cp -R *.lproj TopCal.app/Contents/Resources/
codesign --force --deep --sign - TopCal.app
```

## Usage

- The menu bar shows today's date. Click it to toggle the calendar popover.
- Click `◀` / `▶` inside the popover to switch months.
- Click anywhere outside the popover to close it.
- The interface follows your system language automatically (no setting needed).
- The lunar overlay (`初一`–`三十`) and Chinese public-holiday / make-up
  workday markers are enabled regardless of your macOS system language.
- In Chinese locales (Simplified or Traditional) each cell also shows the
  lunar date (`初一`–`三十`, with month names like `七月` on the 1st). Adjacent
  months appear dimmed to keep the current month prominent.
- Chinese public holidays get a green dot; make-up workdays get a neutral
  dot. Regular weekends are left unmarked. Hover a marked day to see the
  holiday name and whether it's a day off or a make-up workday.
- Use the « / » chevrons to jump a whole year; ‹ / » switch by month.
- The bottom toolbar has a *Workdays* button (excludes public holidays,
  includes weekend make-up workdays) and a *Days* button (inclusive
  total). Pick two cells in the popover to see the result inline.
- The gear menu lets you switch the UI language, pick a Light / Dark /
  Follow-System appearance, toggle launch-at-login, check for updates,
  and quit.

## Uninstall

```bash
# 1. Remove the login item
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.topcal.app.plist
rm ~/Library/LaunchAgents/com.topcal.app.plist

# 2. Quit and delete the app
pkill TopCal
rm -rf /Applications/TopCal.app
```

## How It Works

- **Status bar icon**: the day-of-month is rendered into an `NSImage` and set on
  the `NSStatusBarButton` — more reliable than `button.title` on recent macOS.
- **Popover**: an `NSPopover` with `.transient` behavior (auto-closes on outside click).
- **Lunar calendar**: uses Foundation's `Calendar(identifier: .chinese)` to compute
  the traditional month / day / leap-month for any Gregorian date. Displayed
  only in Chinese locales; other locales see the plain Gregorian grid.
- **Localization**: `*.lproj` bundles (8 languages) provide notifications, the
  month header format, and the localized display name. Weekday headers use
  `Calendar`'s localized symbols aligned to the first weekday.
- **Launch at login**: writes a `LaunchAgent` plist to `~/Library/LaunchAgents`
  and loads it via `launchctl bootstrap` — works with ad-hoc signing, no
  Developer ID or helper app required.
- **Entry point**: `main.swift` uses explicit top-level code instead of `@main`
  because `@main` on `NSApplicationDelegate` subclasses silently fails on
  macOS 26 / Swift 6.2 (see comment in `main.swift`).

## Project Structure

```
├── Sources/
│   ├── main.swift                      # Explicit app entry point (NOT @main)
│   ├── AppDelegate.swift               # Thin wiring: status item + popover + timer
│   ├── AppConstants.swift              # All tunable constants
│   ├── Calendar/
│   │   ├── CalendarViewController.swift  # Popover UI + navigation
│   │   ├── MonthGrid.swift              # Pure data model with adjacent-month cells
│   │   ├── LunarCalendar.swift          # Chinese lunar date helpers
│   │   ├── HolidayCalendar.swift        # Statutory holidays / make-up workdays
│   │   └── Festivals.swift              # Special-festival tooltip data (fixed + lunar)
│   ├── LaunchAtLogin/
│   │   └── LaunchAtLoginManager.swift   # LaunchAgent install/remove
│   ├── Notifications/
│   │   └── NotificationManager.swift    # UserNotifications wrapper
│   └── Support/
│       └── StatusBarIconRenderer.swift  # Renders day number into NSImage
├── *.lproj/                             # Localization (8 languages)
├── AppIcon.icns / icon.png              # App icon (generated by scripts/make_icon.py)
├── docs/                                # Per-locale README screenshots
│   ├── en/                              #   English (no lunar overlay)
│   │   ├── screenshot-menu.png
│   │   ├── screenshot-popover.png       #    ← real AppKit render
│   │   └── menubar-icon.png             #    ← real AppKit render
│   └── zh-Hans/                         #   Simplified Chinese (with lunar dates)
│       ├── screenshot-menu.png
│       ├── screenshot-popover.png       #    ← real AppKit render
│       └── menubar-icon.png             #    ← real AppKit render
├── Info.plist                           # Bundle config (LSUIElement, localizations, icon)
├── scripts/
│   ├── make_icon.py                     # Regenerate AppIcon.icns from icon.png
│   ├── make_screenshots.py              # Compose menu-bar composite using the real icon
│   └── render/                          # Off-screen AppKit renderer (see build.sh)
│       ├── main.swift
│       ├── Info.plist
│       └── build.sh
├── build.sh                             # One-command local build
├── .github/workflows/
│   ├── build.yml                        # CI: compile + signature verification
│   └── release.yml                      # CI: tag → universal build → GitHub Release
├── LICENSE, README.md, README.zh-CN.md, CHANGELOG.md
```

## Contributing

Issues and pull requests are welcome! Please make sure:

1. Code compiles with `./build.sh`
2. No new `print()` debug output in release code — use `os_log` if needed
3. When adding a string, add translations to every `*.lproj/Localizable.strings`
4. Keep changes focused and documented

## License

[MIT](LICENSE) © Alex Liu