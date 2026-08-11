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

    struct Components {
        let month: Int
        let day: Int
        let isLeap: Bool
    }

    /// Whether lunar dates should be shown (Chinese-locale environments only).
    static func shouldShow() -> Bool {
        guard let code = Locale.current.language.languageCode?.identifier else { return false }
        return code.hasPrefix("zh")
    }

    /// Lunar month/day components for the given Gregorian date.
    static func components(for date: Date) -> Components? {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "zh_CN")
        let comps = calendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        guard let month = comps.month, let day = comps.day, day >= 1, day < dayNames.count else {
            return nil
        }
        return Components(month: month, day: day, isLeap: comps.isLeapMonth ?? false)
    }

    /// Short lunar label for a day cell: the month name on the 1st,
    /// otherwise the day name (e.g. "正月", "初二", "廿三").
    static func dayLabel(for date: Date) -> String? {
        guard shouldShow(), let comps = components(for: date) else { return nil }
        if comps.day == 1 {
            let name = monthNames[comps.month - 1]
            return comps.isLeap ? "闰\(name)" : name
        }
        return dayNames[comps.day]
    }
}
