# TopCal · 顶历

A minimal macOS menu bar calendar. Shows today's day-of-month in the menu bar; click it to view a popover calendar with month/year navigation.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange) ![License](https://img.shields.io/badge/License-MIT-green)

**顶历** — 顶部的日历 (Top Cal): the name says it all — a calendar living in the top menu bar.

## Features

- 📅 Current day-of-month shown in the menu bar (e.g. `25`)
- 🗓 Click to open a popover calendar — current day is highlighted
- ◀ ▶ Month/year navigation inside the popover
- 🌍 Localized: 简体中文 · 繁體中文 · English · 日本語 · 한국어 · Deutsch · Français · Español
- 🚀 Launch at login (via per-user LaunchAgent, no helper app required)
- 🔔 Optional launch notification to confirm the app is running
- ⚡ Native AppKit, no dependencies, no sandbox account needed

## Requirements

- macOS 13.0 or later (arm64 / x86_64)
- Xcode Command Line Tools (`xcode-select --install`) to build from source

## Installation

Download the latest `TopCal.app` from [Releases](../../releases) and drag it into your **Applications** folder, then launch it.

> First launch: the app registers itself as a login item and may ask for
> notification permission — these are optional and can be denied.

### macOS Gatekeeper / "Apple cannot check it for malicious software"

TopCal is **ad-hoc signed** (no paid Apple Developer ID), so macOS may block the
first launch. This is normal for free open-source apps. Fix it with any one of:

- **Right-click** the app → **Open** → **Open** again in the dialog, **or**
- Remove the quarantine attribute in Terminal:

  ```bash
  xattr -dr com.apple.quarantine /Applications/TopCal.app
  ```

- If still blocked: **System Settings → Privacy & Security → Security** → click **Open Anyway**.

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
  main.swift AppDelegate.swift CalendarViewController.swift LaunchAtLoginManager.swift
cp Info.plist TopCal.app/Contents/Info.plist
cp -R *.lproj TopCal.app/Contents/Resources/
codesign --force --deep --sign - TopCal.app
```

## Usage

- The menu bar shows today's date. Click it to toggle the calendar popover.
- Click `◀` / `▶` inside the popover to switch months.
- Click anywhere outside the popover to close it.
- The interface follows your system language automatically (no setting needed).

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
├── main.swift                    # Explicit app entry point
├── AppDelegate.swift             # Status bar item, popover, notifications
├── CalendarViewController.swift  # Calendar grid UI + month navigation
├── LaunchAtLoginManager.swift    # LaunchAgent install/remove
├── Info.plist                    # Bundle config (LSUIElement = menu bar app)
├── *.lproj/                      # Localization resources (8 languages)
├── build.sh                      # One-command build script
└── .github/workflows/build.yml   # CI: compiles and verifies signature
```

## Contributing

Issues and pull requests are welcome! Please make sure:

1. Code compiles with `./build.sh`
2. No new `print()` debug output in release code — use `os_log` if needed
3. When adding a string, add translations to every `*.lproj/Localizable.strings`
4. Keep changes focused and documented

## License

[MIT](LICENSE) © Alex Liu
