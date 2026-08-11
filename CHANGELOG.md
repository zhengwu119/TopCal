# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Nothing yet.

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
