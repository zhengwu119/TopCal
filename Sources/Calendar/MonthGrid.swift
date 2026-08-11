import Foundation

/// Pure data model for a single calendar month grid.
/// Separated from the view controller so it can be tested in isolation.
struct MonthGrid {
    /// Number of cells per week (always 7, but explicit for clarity).
    static let columnsPerWeek = 7

    let date: Date
    let weekdayOfFirst: Int   // 1..7 (Calendar.component(.weekday, ...))
    let daysInMonth: Int
    let rows: Int
    /// Whether this grid shows the current month (controls today's highlight).
    let isCurrentMonth: Bool
    let todayDay: Int

    /// Builds a grid for the given month. Returns nil if the date is invalid.
    static func make(for date: Date,
                     today: Date = Date(),
                     calendar: Calendar = .current) -> MonthGrid? {
        let todayParts = calendar.dateComponents([.year, .month], from: today)
        let shownParts = calendar.dateComponents([.year, .month], from: date)
        let isCurrent = todayParts.year == shownParts.year && todayParts.month == shownParts.month

        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: date) else { return nil }

        let weekday = calendar.component(.weekday, from: start)
        let totalCells = range.count + (weekday - 1)
        let rows = Int(ceil(Double(totalCells) / Double(Self.columnsPerWeek)))
        let todayDay = calendar.component(.day, from: today)

        return MonthGrid(date: date,
                         weekdayOfFirst: weekday,
                         daysInMonth: range.count,
                         rows: rows,
                         isCurrentMonth: isCurrent,
                         todayDay: todayDay)
    }

    /// The day-of-month at the given cell, or nil if it's a leading/trailing empty slot.
    func dayAt(row: Int, column: Int) -> Int? {
        let index = row * Self.columnsPerWeek + column
        let day = index - (weekdayOfFirst - 1) + 1
        return (1...daysInMonth).contains(day) ? day : nil
    }

    /// Localized title for the month header (e.g. "2026年8月" / "August 2026").
    var formattedTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.dateFormat = NSLocalizedString("month.title.format",
                                                 comment: "Month/year title format for the calendar header")
        return formatter.string(from: date)
    }

    /// Localized very-short weekday abbreviations, aligned to the calendar's
    /// first weekday (e.g. ["S","M","T","W","T","F","S"] on en-US, ["日","一","二"...] on zh).
    static func weekdaySymbols() -> [String] {
        let calendar = Calendar.current
        var symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1  // 0-based
        if first > 0 && first < symbols.count {
            symbols = Array(symbols[first...] + symbols[..<first])
        }
        return symbols
    }
}