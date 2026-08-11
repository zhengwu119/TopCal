import Foundation

/// Centralised locale/calendar source so the screenshot renderer can force a
/// locale regardless of the system default. The app itself never sets these
/// overrides; they are hooks for `scripts/render/main.swift` (and tests).
enum LocaleProvider {
    /// Render/test-only override. `nil` in production.
    static var forcedLocale: Locale?

    /// Render-only: forces `MonthGrid.formattedTitle`'s date format string
    /// (bypasses the bundle's NSLocalizedString resolution, which the render
    /// tool can't control). `nil` in production.
    static var forcedDateFormat: String?

    static var locale: Locale {
        forcedLocale ?? Locale.autoupdatingCurrent
    }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar
    }
}