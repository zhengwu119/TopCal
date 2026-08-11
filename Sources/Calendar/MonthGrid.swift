import Foundation

/// One cell of the month grid. May belong to the previous / current / next month.
struct MonthCell {
    let day: Int
    let monthOffset: Int   // -1 = previous month, 0 = current, +1 = next
    let isToday: Bool
    let lunarLabel: String?

    var isCurrentMonth: Bool { monthOffset == 0 }
}

/// Pure data model for a single calendar month grid.
/// Separated from the view controller so it can be tested in isolation.
struct MonthGrid {
    static let columnsPerWeek = 7

    let date: Date
    let rows: Int
    let isCurrentMonth: Bool
    let todayDay: Int

    private let calendar: Calendar
    private let startOfMonth: Date
    private let daysInMonth: Int
    private let daysInPreviousMonth: Int
    private let firstWeekdayOffset: Int  // 0-based offset of the 1st of the month

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

        let previousMonth = calendar.date(byAdding: .month, value: -1, to: start) ?? start
        let prevRange = calendar.range(of: .day, in: .month, for: previousMonth)

        return MonthGrid(date: date,
                         rows: rows,
                         isCurrentMonth: isCurrent,
                         todayDay: todayDay,
                         calendar: calendar,
                         startOfMonth: start,
                         daysInMonth: range.count,
                         daysInPreviousMonth: prevRange?.count ?? 30,
                         firstWeekdayOffset: weekday - 1)
    }

    /// The cell at the given row/column, including trailing cells from the
    /// adjacent months.
    func cellAt(row: Int, column: Int) -> MonthCell {
        let index = row * Self.columnsPerWeek + column
        // 0 means the 1st day of the current month
        let dayOffsetFromFirst = index - firstWeekdayOffset
        let dayInMonth = dayOffsetFromFirst + 1

        let cellDate = calendar.date(byAdding: .day, value: dayOffsetFromFirst,
                                     to: startOfMonth) ?? date

        let day: Int
        let monthOffset: Int
        if dayInMonth >= 1 && dayInMonth <= daysInMonth {
            day = dayInMonth
            monthOffset = 0
        } else if dayInMonth < 1 {
            day = daysInPreviousMonth + dayInMonth
            monthOffset = -1
        } else {
            day = dayInMonth - daysInMonth
            monthOffset = 1
        }

        let isToday = calendar.isDate(cellDate, inSameDayAs: Date())
        let lunarLabel = LunarCalendar.dayLabel(for: cellDate)
        return MonthCell(day: day, monthOffset: monthOffset, isToday: isToday,
                         lunarLabel: lunarLabel)
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
