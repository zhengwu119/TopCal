# MenuBarCalendar

A minimal macOS menu bar calendar. Shows today's day-of-month in the menu bar; click it to view a popover calendar with month/year navigation.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 📅 Current day-of-month shown in the menu bar (e.g. `25`)
- 🗓 Click to open a popover calendar — current day is highlighted
- ◀ ▶ Month/year navigation inside the popover
- 🚀 Launch at login (via per-user LaunchAgent, no helper app required)
- 🔔 Optional launch notification to confirm the app is running
- ⚡ Native AppKit, no dependencies, no sandbox account needed

## Requirements

- macOS 13.0 or later (arm64 / x86_64)
- Xcode Command Line Tools (`xcode-select --install`) to build from source

## Installation

Download the latest `.app` from [Releases](../../releases) and drag it into your **Applications** folder, then launch it.

> First launch: the app registers itself as a login item and may ask for
> notification permission — these are optional and can be denied.

## Build from Source

```bash
git clone <your-repo-url> MenuBarCalendar
cd MenuBarCalendar
./build.sh
open build/MenuBarCalendar.app
```

Or manually:

```bash
swiftc -o MenuBarCalendar.app/Contents/MacOS/MenuBarCalendar \
  -framework AppKit -framework Foundation -framework UserNotifications \
  main.swift AppDelegate.swift CalendarViewController.swift LaunchAtLoginManager.swift
cp Info.plist MenuBarCalendar.app/Contents/Info.plist
codesign --force --deep --sign - MenuBarCalendar.app
```

## Usage

- The menu bar shows today's date. Click it to toggle the calendar popover.
- Click `◀` / `▶` inside the popover to switch months.
- Click anywhere outside the popover to close it.

## Uninstall

```bash
# 1. Remove the login item
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.menubarcalendar.app.plist
rm ~/Library/LaunchAgents/com.menubarcalendar.app.plist

# 2. Quit and delete the app
pkill MenuBarCalendar
rm -rf /Applications/MenuBarCalendar.app
```

## How It Works

- **Status bar icon**: the day-of-month is rendered into an `NSImage` and set on
  the `NSStatusBarButton` — more reliable than `button.title` on recent macOS.
- **Popover**: an `NSPopover` with `.transient` behavior (auto-closes on outside click).
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
├── build.sh                      # One-command build script
└── .github/workflows/build.yml   # CI: compiles and verifies signature
```

## Contributing

Issues and pull requests are welcome! Please make sure:

1. Code compiles with `./build.sh`
2. No new `print()` debug output in release code — use `os_log` if needed
3. Keep changes focused and documented

## License

[MIT](LICENSE) © Alex Liu
