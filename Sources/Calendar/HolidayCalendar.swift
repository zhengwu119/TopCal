import Foundation

/// Official Chinese public holidays and make-up workdays (调休补班).
///
/// Data is entered per year from the State Council's annual holiday notice
/// (国务院办公厅关于部分节假日安排的通知). Markers are only shown in Chinese
/// locales, matching the lunar calendar overlay.
///
/// Dates are stored as `YYYYMMDD` integers to avoid timezone pitfalls.
/// Please add new years' data when the official notice is published.
enum HolidayCalendar {
    /// 法定节假日（放假）— date keys as YYYYMMDD.
    private static let holidaysByYear: [Int: Set<Int>] = [
        2026: [
            // 元旦 1/1–1/3
            20260101, 20260102, 20260103,
            // 春节 2/15–2/23
            20260215, 20260216, 20260217, 20260218, 20260219,
            20260220, 20260221, 20260222, 20260223,
            // 清明 4/4–4/6
            20260404, 20260405, 20260406,
            // 劳动节 5/1–5/5
            20260501, 20260502, 20260503, 20260504, 20260505,
            // 端午 6/19–6/21
            20260619, 20260620, 20260621,
            // 中秋 9/25–9/27
            20260925, 20260926, 20260927,
            // 国庆 10/1–10/7
            20261001, 20261002, 20261003, 20261004,
            20261005, 20261006, 20261007
        ]
    ]

    /// 调休上班日（周末补班）— date keys as YYYYMMDD.
    private static let makeupWorkdaysByYear: [Int: Set<Int>] = [
        2026: [
            20260104,  // 1/4 (Sun) after New Year
            20260214,  // 2/14 (Sat) before Spring Festival
            20260228,  // 2/28 (Sat) after Spring Festival
            20260509,  // 5/9 (Sat) after Labour Day
            20260920,  // 9/20 (Sun) before Mid-Autumn
            20261010   // 10/10 (Sat) after National Day
        ]
    ]

    /// 法定节假日（公休日）→ green dot.
    static func isPublicHoliday(_ date: Date) -> Bool {
        guard shouldShow() else { return false }
        let parts = ymdParts(date)
        return holidaysByYear[parts.year]?.contains(parts.ymd) ?? false
    }

    /// 调休上班日（周末补班）→ neutral dot.
    static func isMakeupWorkday(_ date: Date) -> Bool {
        guard shouldShow() else { return false }
        let parts = ymdParts(date)
        return makeupWorkdaysByYear[parts.year]?.contains(parts.ymd) ?? false
    }

    /// Whether holiday markers should be shown (Chinese-locale environments only).
    private static func shouldShow() -> Bool {
        if UserDefaults.standard.object(forKey: LunarCalendar.lunarForceShowKey) != nil {
            return UserDefaults.standard.bool(forKey: LunarCalendar.lunarForceShowKey)
        }
        let code = LocaleProvider.locale.language.languageCode?.identifier
        return code?.hasPrefix("zh") ?? false
    }

    private static func ymdParts(_ date: Date) -> (year: Int, ymd: Int) {
        let comps = LocaleProvider.calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 0
        return (year, year * 10000 + (comps.month ?? 0) * 100 + (comps.day ?? 0))
    }
}
