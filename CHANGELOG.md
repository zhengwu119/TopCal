# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Nothing yet.

## [1.4.0] - 2026-08-11

### Added

- **Launch-at-login toggle** in the settings menu: checkmark reflects whether
  the LaunchAgent is installed; clicking installs/removes it via
  `LaunchAtLoginManager` and persists the choice in `UserDefaults`
  (`LaunchAtLogin`, default on). `AppDelegate` now respects the preference at
  startup so turning it off stays off across launches.
- **Appearance switcher** in the settings menu (`AppearanceManager`):
  Follow System (default) / Light / Dark, persisted in `UserDefaults`
  (`Appearance`) and applied instantly via `NSApp.appearance`; the
  menu-bar icon is re-rendered so its dynamic colors follow the theme.
- Settings strings localized across all 8 languages
  (`settings.launchAtLogin`, `settings.appearance.*`).

## [1.3.0] - 2026-08-11

### Added

- **Hover tooltips on holiday / make-up workday cells**: hovering a green dot
  shows e.g. `国庆节 · 放假` (zh) / `National Day · Public Holiday` (en);
  hovering a neutral dot shows `国庆节 · 调休上班` / `National Day ·
  Make-up Workday`. Holiday names come from `HolidayCalendar` (Chinese
  names + English equivalents) and the templates are localized in all 8
  languages.

### Fixed

- Today's highlighted cell rendered as a stretched **oval** because the
  corner radius was half the row height (20pt) while the cell is only
  ~31pt wide. Now uses a fixed 8pt radius (`cellCornerRadius`) → a clean
  rounded rectangle; the selection border follows the same radius.

## [1.2.0] - 2026-08-11

### Added

- **Year navigation chevrons** (« / ») flanking the existing monthly ‹ / »
  arrows. Built with `NSImage(systemSymbolName:)` so the arrows render as
  crisp SF Symbol glyphs (`chevron.left.2`, `chevron.right.2`).
- **Workday / total-day calculator** at the bottom of the popover. Two
  buttons open a date-range selection mode; clicking two cells computes
  the result inline:
  - *Workdays* = non-weekend days minus public holidays, plus weekend
    make-up workdays (uses `HolidayCalendar`).
  - *Days* = inclusive total days.
  The toolbar buttons and result text are localized across all 8 languages.
  Logic lives in `Sources/Calendar/WorkdayCounter.swift` (pure, tested).
- CalendarViewController: `DayCellView` carries the cell's absolute date so
  the click handler can convert a tap into a range selection without
  re-deriving the date from the grid. `MonthCell` now exposes `date`.
- Holiday dots get more breathing room: cell height raised to 40 pt with
  an explicit gap between the lunar label and the dot.

### Changed

- AppConstants.Popover.size → 248×362 (extra width for chevrons; extra
  height for the calculator toolbar).

### Changed

- **Lunar overlay and Chinese-holiday markers are enabled by default** (no
  longer gated on the system language). Set `LunarForceShow = NO` via
  `UserDefaults` to hide them.
- Calendar navigation arrows are now character buttons (`« ‹ › »`) — keeps
  the tint consistently neutral regardless of the SF Symbol / NSButton
  accent-color rendering quirks on recent macOS releases.
- The bottom toolbar buttons became image-only (SF Symbols
  `calendar.badge.clock` and `calendar`) with localized tooltips
  ("计算工作日" / "计算天数间隔" in zh-Hans); the previous text titles were
  replaced by `toolbar.workdays.tip` / `toolbar.days.tip` keys in every
  locale.
- Tapping a calculator button while a result or selection is in progress
  resets the toolbar to its initial empty state (one tap → enter selection
  mode; second tap → reset).

### Added

- **Settings menu** (gear icon, bottom-right of the toolbar):
  - **Language** submenu to switch the in-app language (8 locales). The
    choice is persisted in `UserDefaults` (`UserLanguage`) and applies
    immediately by rebuilding the popover. `LocaleProvider.localizedString`
    reads from the per-language `Localizable.strings` so dynamic UI
    strings (tooltips, prompts, results, about) follow the picked
    language — independent of the macOS system language.
  - **Check for Updates…** hits
    `https://api.github.com/repos/zhengwu119/TopCal/releases/latest`,
    compares with `CFBundleShortVersionString`, and offers to open the
    Releases page if a newer version is available.
  - **About TopCal** shows the version, license and app icon.
- Info.plist version bumped to **1.2.0** (matches the upcoming v1.2.0
  release) so the update check returns a sensible answer.

- Per-language README switcher at the top of both READMEs (English /
  简体中文 linked; 日本語 · 한국어 · Deutsch · Français · Español marked
  as translations welcome)
- **Real AppKit-rendered README screenshots**: a new `scripts/render/`
  tool instantiates the real `CalendarViewController` and
  `StatusBarIconRenderer` and exports PNG via `cacheDisplay`, so the
  popover images show actual layout, fonts, and lunar dates (not hand-drawn
  mockups). A small `LocaleProvider` hook in the app exposes `forcedLocale`
  / `forcedDateFormat` so the renderer can force a locale without touching
  global preferences.
- Menu-bar screenshots now embed the real AppKit-rendered icon (instead of
  a hand-drawn red pill). The popover is fully real; only the menu-bar
  background is synthesised because `NSStatusBar` requires a live GUI session.

## [1.1.0] - 2026-08-11

### Added

- **Lunar (农历) calendar overlay** in Chinese locales: each cell shows the
  traditional day (`初一`–`三十`); the 1st of each lunar month shows the month
  name (`正月`, `二月`, …); leap months render as `闰X月`. Implemented via
  Foundation's `Calendar(identifier: .chinese)`. Display is gated by
  `Locale.current.language.languageCode` so non-Chinese locales stay clean.
- **Adjacent-month dates in the calendar grid**: previous / next-month leading
  and trailing cells are now rendered in dim grey (instead of empty placeholders).
- App icon: red rounded square with a white menu-bar strip and bold "25"
  (`AppIcon.icns` + `icon.png`, generated by `scripts/make_icon.py`)
- Refactored source layout into `Sources/` subdirectories by responsibility
  (Calendar, LaunchAtLogin, Notifications, Support)
- `MonthGrid` — pure data model for the calendar grid (testable, now with
  `monthOffset` for adjacent months and `lunarLabel`)
- `NotificationManager`, `StatusBarIconRenderer`, `AppConstants` — focused,
  reusable modules extracted from `AppDelegate`

### Changed

- `AppDelegate` is now a thin wiring layer (no icon drawing, no notification
  logic, no login-item logic — all delegated)
- `LaunchAtLoginManager` shares a single helper for `bootstrap` / `bootout`,
  and uses `Bundle.main.bundleIdentifier ?? AppConstants.fallbackBundleIdentifier`
- README Gatekeeper section: only the `xattr -dr com.apple.quarantine` command
- English README has zero Chinese; icon displayed at 128px centered; README
  screenshots added per locale (`docs/en/`, `docs/zh-Hans/` — English shows no
  lunar overlay, Simplified Chinese shows lunar dates; regenerated via
  `scripts/make_screenshots.py`)

### Fixed

- Leap-month detection no longer relies on `DateComponents.isLeapMonth`
  (macOS 14+ only) — the manual check keeps the deployment target at macOS 13

## [1.0.0] - 2026-08-11

### Added

- Menu bar shows today's day-of-month (e.g. `25`)
- Popover calendar with current-day highlight
- Month/year navigation (`◀` / `▶`)
- Launch at login via per-user LaunchAgent (no helper app required)
- Optional launch notification
- Localization: 简体中文 · 繁體中文 · English · 日本語 · 한국어 · Deutsch · Français · Español
- Bilingual README (EN / zh-CN)

### Fixed

- Use explicit `main.swift` entry point — `@main` silently fails on
  `NSApplicationDelegate` subclasses under macOS 26 / Swift 6.2
- Day-of-month rendered as `NSImage` (more reliable than `button.title` on recent macOS)
- Removed leftover debug output; diagnostics now use `os_log`
- `launchctl bootstrap` used instead of deprecated `load`

[Unreleased]: https://github.com/zhengwu119/TopCal/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/zhengwu119/TopCal/releases/tag/v1.0.0
