import Foundation

/// Lunar (Chinese) calendar helpers, built on Foundation's `.chinese` calendar.
///
/// Lunar dates are shown only in Chinese locales (zh-*); other locales render
/// the plain Gregorian calendar without lunar annotations.
enum LunarCalendar {
    static let monthNames = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月"
    ]

    static let dayNames = [
        "", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    /// Whether lunar dates should be shown (Chinese-locale environments only).
    ///
    /// Honors `LocaleProvider.forcedLocale` (set by `scripts/render/main.swift`)
    /// and a `LunarForceShow` UserDefaults flag — both are unused by the app.
    static func shouldShow() -> Bool {
        if UserDefaults.standard.object(forKey: lunarForceShowKey) != nil {
            return UserDefaults.standard.bool(forKey: lunarForceShowKey)
        }
        let code = LocaleProvider.locale.language.languageCode?.identifier
        return code?.hasPrefix("zh") ?? false
    }

    static let lunarForceShowKey = "LunarForceShow"

    /// Lunar month/day components for the given Gregorian date.
    static func components(for date: Date) -> (month: Int, day: Int)? {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "zh_CN")
        let comps = calendar.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day,
              day >= 1, day < dayNames.count else { return nil }
        return (month, day)
    }

    /// Short lunar label for a day cell: the month name on the 1st
    /// (with a `闰` prefix for leap months), otherwise the day name.
    static func dayLabel(for date: Date) -> String? {
        guard shouldShow(), let comps = components(for: date) else { return nil }
        if comps.day == 1 {
            let name = monthNames[comps.month - 1]
            return isLeapMonthFirstDay(date, month: comps.month) ? "闰\(name)" : name
        }
        return dayNames[comps.day]
    }

    /// Detects a leap month for a date that is the 1st of a lunar month.
    ///
    /// A leap month repeats the *previous* month's number, so if the day before
    /// this lunar month's first day still belongs to a month with the same
    /// number, this is the leap (second) occurrence.
    ///
    /// `DateComponents.isLeapMonth` is macOS 14+ only; this manual check keeps
    /// the deployment target at macOS 13.
    private static func isLeapMonthFirstDay(_ date: Date, month: Int) -> Bool {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "zh_CN")
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
            return false
        }
        return calendar.component(.month, from: previousDay) == month
    }
}
