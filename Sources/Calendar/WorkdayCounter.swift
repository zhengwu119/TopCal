import Foundation

/// Date-range calculations: total days and Chinese workdays.
///
/// A workday = any day that is not a weekend, except official public
/// holidays; weekend days scheduled as make-up workdays (调休补班) count as
/// workdays. In non-Chinese locales HolidayCalendar returns no entries, so
/// the result naturally falls back to "non-weekend days".
enum WorkdayCounter {
    /// Inclusive total days from `start` to `end` (end >= start).
    static func totalDays(from start: Date, to end: Date,
                          calendar: Calendar = LocaleProvider.calendar) -> Int {
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        guard let days = calendar.dateComponents([.day], from: s, to: e).day else { return 0 }
        return days + 1
    }

    /// Number of workdays in the inclusive range [start, end].
    static func workdays(from start: Date, to end: Date,
                         calendar: Calendar = LocaleProvider.calendar) -> Int {
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        guard s <= e else { return 0 }

        var count = 0
        var day = s
        while day <= e {
            let weekday = calendar.component(.weekday, from: day)
            let isWeekend = weekday == 1 || weekday == 7  // Sunday / Saturday
            if isWeekend {
                // Make-up workday on a weekend counts as a workday.
                if HolidayCalendar.isMakeupWorkday(day) { count += 1 }
            } else {
                // Official holiday during the week does not count.
                if !HolidayCalendar.isPublicHoliday(day) { count += 1 }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return count
    }
}
